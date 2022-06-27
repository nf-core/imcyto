/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowImcyto.initialise(params, log)

// Check input path parameters to see if they exist
def checkPathParamList = [ 
    params.input,
    params.metadata,
    params.full_stack_cppipe,
    params.ilastik_stack_cppipe,
    params.segmentation_cppipe,
    params.ilastik_training_ilp,
    params.compensation_tiff,
    params.plugins_dir
]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check input parameters
if (params.input) {
    Channel
        .fromPath(params.input)
        .map { it -> [ [ id : it.name.take(it.name.lastIndexOf('.')) ], it ] }
        .ifEmpty { exit 1, "Input file not found: ${params.input}" }
        .set { ch_mcd }
} else {
   exit 1, "Input file not specified!"
}

if (params.metadata)             { ch_metadata             = file(params.metadata)             }
if (params.full_stack_cppipe)    { ch_full_stack_cppipe    = file(params.full_stack_cppipe)    }
if (params.ilastik_stack_cppipe) { ch_ilastik_stack_cppipe = file(params.ilastik_stack_cppipe) }
if (params.segmentation_cppipe)  { ch_segmentation_cppipe  = file(params.segmentation_cppipe)  }

if (!params.skip_ilastik) {
    if (params.ilastik_training_ilp) {
        ch_ilastik_training_ilp = file(params.ilastik_training_ilp) 
    }
}

ch_compensation_tiff = params.compensation_tiff ? file(params.compensation_tiff) : []

// Plugins required for CellProfiler
ch_plugins_dir = file(params.plugins_dir)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Loaded from modules/local/
//
include { IMCTOOLS                                   } from '../modules/local/imctools'
include { CELLPROFILER as CELLPROFILER_FULL_STACK    } from '../modules/local/cellprofiler'
include { CELLPROFILER as CELLPROFILER_ILASTIK_STACK } from '../modules/local/cellprofiler'
include { CELLPROFILER as CELLPROFILER_SEGMENTATION  } from '../modules/local/cellprofiler'
include { ILASTIK                                    } from '../modules/local/ilastik'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/modules/custom/dumpsoftwareversions/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow IMCYTO {

    ch_versions = Channel.empty()

    //
    // MODULE: Run imctools
    //
    IMCTOOLS (
        ch_mcd,
        ch_metadata
    )
    ch_versions = ch_versions.mix(IMCTOOLS.out.versions)

    //
    // Group full stack files by sample and roi_id
    //
    IMCTOOLS
        .out
        .full_stack_tiff
        .map { WorkflowImcyto.flattenTiff(it) }
        .flatten()
        .collate(2)
        .groupTuple()
        .map { it -> [ it[0], it[1].sort() ] }
        .set { ch_full_stack_tiff }

    //
    // Group ilastik stack files by sample and roi_id
    //
    IMCTOOLS
        .out
        .ilastik_stack
        .map { WorkflowImcyto.flattenTiff(it) }
        .flatten()
        .collate(2)
        .groupTuple()
        .map { it -> [ it[0], it[1].sort() ] }
        .set { ch_ilastik_stack_tiff }

    //
    // MODULE: Preprocess full stack images with CellProfiler
    //
    CELLPROFILER_FULL_STACK (
        ch_full_stack_tiff,
        ch_full_stack_cppipe,
        ch_compensation_tiff,
        ch_plugins_dir
    )
    ch_versions = ch_versions.mix(CELLPROFILER_FULL_STACK.out.versions.first())

    //
    // MODULE: Preprocess Ilastik stack images with CellProfiler
    //
    CELLPROFILER_ILASTIK_STACK (
        ch_ilastik_stack_tiff,
        ch_ilastik_stack_cppipe,
        ch_compensation_tiff,
        ch_plugins_dir
    )

    //
    // MODULE: Run Ilastik
    //
    if (params.skip_ilastik) {
        CELLPROFILER_FULL_STACK
            .out
            .tiff
            .join(CELLPROFILER_ILASTIK_STACK.out.tiff)
            .map { it -> [ it[0], [ it[1], it[2] ].flatten().sort() ] }
            .set { ch_segmentation_tiff }
    } else {
        ILASTIK (
            CELLPROFILER_ILASTIK_STACK.out.tiff,
            ch_ilastik_training_ilp
        )
        ch_versions = ch_versions.mix(ILASTIK.out.versions.first())

        CELLPROFILER_FULL_STACK
            .out
            .tiff
            .join(ILASTIK.out.tiff)
            .map { it -> [ it[0], [ it[1], it[2] ].flatten().sort() ] }
            .set { ch_segmentation_tiff }
    }

    // //
    // // MODULE: Segmentation with CellProfiler
    // //
    // CELLPROFILER_SEGMENTATION (

    // )

    //
    // MODULE: Pipeline reporting
    //
    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, [])
    }
    NfcoreTemplate.summary(workflow, params, log)
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/