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
    params.plugins
]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.input) {
    Channel
        .fromPath(params.input)
        .map { it -> [ it.name.take(it.name.lastIndexOf('.')), it ] }
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
// .into { ch_compensation_full_stack;
//         ch_compensation_ilastik_stack }

// Plugins required for CellProfiler
ch_plugins = file(params.plugins)
// .into { ch_preprocess_full_stack_plugin;
//         ch_preprocess_ilastik_stack_plugin;
//         ch_segmentation_plugin }

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

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