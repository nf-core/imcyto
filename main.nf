#!/usr/bin/env nextflow
/*
========================================================================================
                         nf-core/imcyto
========================================================================================
 nf-core/imcyto Analysis Pipeline.
 #### Homepage / Documentation
 https://github.com/nf-core/imcyto
----------------------------------------------------------------------------------------
*/

def helpMessage() {
    log.info nfcoreHeader()
    log.info"""

    Usage:

    The typical command for running the pipeline is as follows:
      nextflow run nf-core/imcyto \
          --input "./inputs/*.mcd" \
          --metadata './inputs/metadata.csv' \
          --full_stack_cppipe './plugins/full_stack_preprocessing.cppipe' \
          --ilastik_stack_cppipe './plugins/ilastik_stack_preprocessing.cppipe' \
          --segmentation_cppipe './plugins/segmentation.cppipe' \
          --ilastik_training_ilp './plugins/ilastik_training_params.ilp' \
          --plugins './plugins/cp_plugins/' \
          -profile docker

    Mandatory arguments:
      --input [file]                  Path to input data file(s) (globs must be surrounded with quotes). Currently supported formats are *.mcd, *.ome.tiff, *.txt
      --metadata [file]               Path to metadata csv file indicating which images to merge in full stack and/or Ilastik stack
      --full_stack_cppipe [file]      CellProfiler pipeline file required to create full stack (cppipe format)
      --ilastik_stack_cppipe [file]   CellProfiler pipeline file required to create Ilastik stack (cppipe format)
      --segmentation_cppipe [file]    CellProfiler pipeline file required for segmentation (cppipe format)
      -profile [str]                  Configuration profile to use. Can use multiple (comma separated)
                                      Available: docker, singularity, awsbatch, test and more.

    Other options:
      --ilastik_training_ilp [file]   Parameter file required by Ilastik (ilp format)
      --compensation_tiff [file]      Tiff file for compensation analysis during CellProfiler preprocessing steps
      --skip_ilastik [bool]           Skip Ilastik processing step
      --plugins [file]                Path to directory with plugin files required for CellProfiler. Default: assets/plugins
      --outdir [file]                 The output directory where the results will be saved
      --publish_dir_mode [str]        Mode for publishing results in the output directory. Available: symlink, rellink, link, copy, copyNoFollow, move (Default: copy)
      --email [email]                 Set this parameter to your e-mail address to get a summary e-mail with details of the run sent to you when the workflow exits
      --email_on_fail [email]         Same as --email, except only send mail if the workflow is not successful
      -name [str]                     Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic.

    AWSBatch options:
      --awsqueue [str]                The AWSBatch JobQueue that needs to be set when running on AWSBatch
      --awsregion [str]               The AWS Region for your AWS Batch job to run on
      --awscli [str]                  Path to the AWS CLI tool
    """.stripIndent()
}

// Show help message
if (params.help) {
    helpMessage()
    exit 0
}

// Has the run name been specified by the user?
// this has the bonus effect of catching both -name and --name
custom_runName = params.name
if (!(workflow.runName ==~ /[a-z]+_[a-z]+/)) {
    custom_runName = workflow.runName
}

// Stage config files
ch_output_docs = file("$baseDir/docs/output.md", checkIfExists: true)
ch_output_docs_images = file("$baseDir/docs/images/", checkIfExists: true)

/*
 * Validate inputs
 */
if (params.input) {
    Channel
        .fromPath(params.input, checkIfExists: true)
        .map { it -> [ it.name.take(it.name.lastIndexOf('.')), it ] }
        .ifEmpty { exit 1, "Input file not found: ${params.input}" }
        .set { ch_mcd }
} else {
   exit 1, "Input file not specified!"
}

if (params.metadata)             { ch_metadata = file(params.metadata, checkIfExists: true) }                         else { exit 1, "Metadata csv file not specified!" }
if (params.full_stack_cppipe)    { ch_full_stack_cppipe = file(params.full_stack_cppipe, checkIfExists: true) }       else { exit 1, "CellProfiler full stack cppipe file not specified!" }
if (params.ilastik_stack_cppipe) { ch_ilastik_stack_cppipe = file(params.ilastik_stack_cppipe, checkIfExists: true) } else { exit 1, "Ilastik stack cppipe file not specified!" }
if (params.segmentation_cppipe)  { ch_segmentation_cppipe = file(params.segmentation_cppipe, checkIfExists: true) }   else { exit 1, "CellProfiler segmentation cppipe file not specified!" }

if (!params.skip_ilastik) {
    if (params.ilastik_training_ilp) {
        ch_ilastik_training_ilp = file(params.ilastik_training_ilp, checkIfExists: true) } else { exit 1, "Ilastik training ilp file not specified!" }
}

if (params.compensation_tiff) {
    Channel
        .fromPath(params.compensation_tiff, checkIfExists: true)
        .into { ch_compensation_full_stack;
                ch_compensation_ilastik_stack }
} else {
    Channel
        .empty()
        .into { ch_compensation_full_stack;
                ch_compensation_ilastik_stack }
}

// Plugins required for CellProfiler
Channel
    .fromPath(params.plugins, checkIfExists: true)
    .into { ch_preprocess_full_stack_plugin;
            ch_preprocess_ilastik_stack_plugin;
            ch_segmentation_plugin }

// AWS Batch settings
if (workflow.profile == 'awsbatch') {
  // AWSBatch sanity checking
  if (!params.awsqueue || !params.awsregion) exit 1, "Specify correct --awsqueue and --awsregion parameters on AWSBatch!"
  // Check outdir paths to be S3 buckets if running on AWSBatch
  // related: https://github.com/nextflow-io/nextflow/issues/813
  if (!params.outdir.startsWith('s3:')) exit 1, "Outdir not on S3 - specify S3 Bucket to run on AWSBatch!"
  // Prevent trace files to be stored on S3 since S3 does not support rolling files.
  if (workflow.tracedir.startsWith('s3:')) exit 1, "Specify a local tracedir or run without trace! S3 cannot be used for tracefiles."
}

// Header log info
log.info nfcoreHeader()
def summary = [:]
summary['Run Name']                     = custom_runName ?: workflow.runName
summary['Input Files']                  = params.input
summary['Metadata File']                = params.metadata
summary['Full Stack cppipe File']       = params.full_stack_cppipe
summary['Ilastik Stack cppipe File']    = params.ilastik_stack_cppipe
summary['Skip Ilastik Step']            = params.skip_ilastik ? 'Yes' : 'No'
if (params.compensation_tiff) summary['Compensation Tiff']    = params.compensation_tiff
if (!params.skip_ilastik) summary['Ilastik Training ilp File'] = params.ilastik_training_ilp
summary['Segmentation cppipe File']     = params.segmentation_cppipe
summary['Max Resources']    = "$params.max_memory memory, $params.max_cpus cpus, $params.max_time time per job"
if (workflow.containerEngine) summary['Container'] = "$workflow.containerEngine - $workflow.container"
summary['Output Dir']                   = params.outdir
summary['Launch Dir']                   = workflow.launchDir
summary['Working Dir']                  = workflow.workDir
summary['Script Dir']                   = workflow.projectDir
summary['User']                         = workflow.userName
summary['Config Profile']               = workflow.profile
if (params.config_profile_description) summary['Config Description'] = params.config_profile_description
if (params.config_profile_contact)     summary['Config Contact']     = params.config_profile_contact
if (params.config_profile_url)         summary['Config URL']         = params.config_profile_url
if (workflow.profile.contains('awsbatch')) {
  summary['AWS Region']                = params.awsregion
  summary['AWS Queue']                 = params.awsqueue
  summary['AWS CLI']                   = params.awscli
}
if (params.email || params.email_on_fail) {
  summary['E-mail Address']     = params.email
  summary['E-mail on failure']  = params.email_on_fail
}
log.info summary.collect { k,v -> "${k.padRight(25)}: $v" }.join("\n")
log.info "-\033[2m--------------------------------------------------\033[0m-"

// Check the hostnames against configured profiles
checkHostname()

/*
 * STEP 1: imctools
 */
process IMCTOOLS {
    tag "$name"
    label 'process_medium'
    publishDir "${params.outdir}/imctools/${name}", mode: params.publish_dir_mode,
        saveAs: { filename ->
                      if (filename.indexOf("version.txt") > 0) null
                      else filename
                }

    input:
    tuple val(name), path(mcd) from ch_mcd
    path metadata from ch_metadata

    output:
    tuple val(name), path("*/full_stack/*") into ch_full_stack_tiff
    tuple val(name), path("*/ilastik_stack/*") into ch_ilastik_stack_tiff
    path "*/*ome.tiff"
    path "*.csv"
    path "*version.txt" into ch_imctools_version

    script: // This script is bundled with the pipeline, in nf-core/imcyto/bin/
    """
    run_imctools.py $mcd $metadata
    pip show imctools | grep "Version" > imctools_version.txt
    """
}

// Function to get list of [sample_id,roi_id,path_to_file]
def flatten_tiff(ArrayList channel) {
    def sample = channel[0]
    def file_list = channel[1]
    def new_array = []
    for (int i=0; i<file_list.size(); i++) {
        def item = []
        item.add(sample)
        item.add(file_list[i].getParent().getParent().getName())
        item.add(file_list[i])
        new_array.add(item)
    }
    return new_array
}

// Group full stack files by sample and roi_id
ch_full_stack_tiff
    .map { flatten_tiff(it) }
    .flatten()
    .collate(3)
    .groupTuple(by: [0,1])
    .map { it -> [ it[0], it[1], it[2].sort() ] }
    .set { ch_full_stack_tiff }

// Group ilastik stack files by sample and roi_id
ch_ilastik_stack_tiff
    .map { flatten_tiff(it) }
    .flatten()
    .collate(3)
    .groupTuple(by: [0,1])
    .map { it -> [ it[0], it[1], it[2].sort() ] }
    .set { ch_ilastik_stack_tiff }

/*
 * STEP 2: Preprocess full stack images with CellProfiler
 */
process PREPROCESS_FULL_STACK {
    tag "${name}.${roi}"
    label 'process_medium'
    publishDir "${params.outdir}/preprocess/${name}/${roi}", mode: params.publish_dir_mode,
        saveAs: { filename ->
                      if (filename.indexOf("version.txt") > 0) null
                      else filename
                }

    input:
    tuple val(name), val(roi), path(tiff) from ch_full_stack_tiff
    path ctiff from ch_compensation_full_stack.collect().ifEmpty([])
    path cppipe from ch_full_stack_cppipe
    path plugin_dir from ch_preprocess_full_stack_plugin.collect()

    output:
    tuple val(name), val(roi), path("full_stack/*") into ch_preprocess_full_stack_tiff
    path "*version.txt" into ch_cellprofiler_version

    script:
    """
    export _JAVA_OPTIONS="-Xms${task.memory.toGiga()/2}g -Xmx${task.memory.toGiga()}g"
    cellprofiler \\
        --run-headless \\
        --pipeline $cppipe \\
        --image-directory ./ \\
        --plugins-directory ./${plugin_dir} \\
        --output-directory ./full_stack \\
        --log-level DEBUG \\
        --temporary-directory ./tmp

    cellprofiler --version > cellprofiler_version.txt
    """
}

/*
 * STEP 3: Preprocess Ilastik stack images with CellProfiler
 */
process PREPROCESS_ILASTIK_STACK {
    tag "${name}.${roi}"
    label 'process_medium'
    publishDir "${params.outdir}/preprocess/${name}/${roi}", mode: params.publish_dir_mode

    input:
    tuple val(name), val(roi), path(tiff) from ch_ilastik_stack_tiff
    path ctiff from ch_compensation_ilastik_stack.collect().ifEmpty([])
    path cppipe from ch_ilastik_stack_cppipe
    path plugin_dir from ch_preprocess_ilastik_stack_plugin.collect()

    output:
    tuple val(name), val(roi), path("ilastik_stack/*") into ch_preprocess_ilastik_stack_tiff

    script:
    """
    export _JAVA_OPTIONS="-Xms${task.memory.toGiga()/2}g -Xmx${task.memory.toGiga()}g"
    cellprofiler \\
        --run-headless \\
        --pipeline $cppipe \\
        --image-directory ./ \\
        --plugins-directory ./${plugin_dir} \\
        --output-directory ./ilastik_stack \\
        --log-level DEBUG \\
        --temporary-directory ./tmp
    """
}

/*
 * STEP 4: Ilastik
 */
if (params.skip_ilastik) {
    ch_preprocess_full_stack_tiff
        .join(ch_preprocess_ilastik_stack_tiff, by: [0,1])
        .map { it -> [ it[0], it[1], [ it[2], it[3] ].flatten().sort() ] }
        .set { ch_preprocess_full_stack_tiff }
    ch_ilastik_version = Channel.empty()
} else {
    process ILASTIK {
        tag "${name}.${roi}"
        label 'process_medium'
        publishDir "${params.outdir}/ilastik/${name}/${roi}", mode: params.publish_dir_mode,
            saveAs: { filename ->
                          if (filename.indexOf("version.txt") > 0) null
                          else filename
                    }

        input:
        tuple val(name), val(roi), path(tiff) from ch_preprocess_ilastik_stack_tiff
        path ilastik_training_ilp from ch_ilastik_training_ilp

        output:
        tuple val(name), val(roi), path("*.tiff") into ch_ilastik_tiff
        path "*version.txt" into ch_ilastik_version

        script:
        """
        cp $ilastik_training_ilp ilastik_params.ilp

        /ilastik-release/run_ilastik.sh \\
            --headless \\
            --project=ilastik_params.ilp \\
            --output_format="tiff sequence" \\
            --output_filename_format=./{nickname}_{result_type}_{slice_index}.tiff \\
            --logfile ./ilastik_log.txt \\
            $tiff
        rm  ilastik_params.ilp

        /ilastik-release/bin/python -c "import ilastik; print(ilastik.__version__)" > ilastik_version.txt
        """
    }

    ch_preprocess_full_stack_tiff
        .join(ch_ilastik_tiff, by: [0,1])
        .map { it -> [ it[0], it[1], [ it[2], it[3] ].flatten().sort() ] }
        .set { ch_preprocess_full_stack_tiff }
}

/*
 * STEP 5: Segmentation with CellProfiler
 */
process SEGMENTATION {
    tag "${name}.${roi}"
    label 'process_high'
    publishDir "${params.outdir}/segmentation/${name}/${roi}", mode: params.publish_dir_mode

    input:
    tuple val(name), val(roi), path(tiff) from ch_preprocess_full_stack_tiff
    path cppipe from ch_segmentation_cppipe
    path plugin_dir from ch_segmentation_plugin.collect()

    output:
    path "*.{csv,tiff}"

    script:
    """
    export _JAVA_OPTIONS="-Xms${task.memory.toGiga()/2}g -Xmx${task.memory.toGiga()}g"
    cellprofiler \\
        --run-headless \\
        --pipeline $cppipe \\
        --image-directory ./ \\
        --plugins-directory ./${plugin_dir} \\
        --output-directory ./ \\
        --log-level DEBUG \\
        --temporary-directory ./tmp
    """
}

/*
 * STEP 6: Output Description HTML
 */
process output_documentation {
    publishDir "${params.outdir}/pipeline_info", mode: params.publish_dir_mode

    input:
    path output_docs from ch_output_docs
    path images from ch_output_docs_images

    output:
    path "results_description.html"

    script:
    """
    markdown_to_html.r $output_docs results_description.html
    """
}

/*
 * Parse software version numbers
 */
process get_software_versions {
    publishDir "${params.outdir}/pipeline_info", mode: params.publish_dir_mode,
        saveAs: { filename ->
                      if (filename.indexOf(".csv") > 0) filename
                      else null
                }

    input:
    path imctools from ch_imctools_version.first()
    path cellprofiler from ch_cellprofiler_version.first()
    path ilastik from ch_ilastik_version.first().ifEmpty([])

    output:
    path "software_versions.csv"

    script:
    """
    echo $workflow.manifest.version > pipeline_version.txt
    echo $workflow.nextflow.version > nextflow_version.txt
    scrape_software_versions.py &> software_versions_mqc.yaml
    """
}

/*
 * Completion e-mail notification
 */
workflow.onComplete {

    // Set up the e-mail variables
    def subject = "[nf-core/imcyto] Successful: $workflow.runName"
    if (!workflow.success) {
        subject = "[nf-core/imcyto] FAILED: $workflow.runName"
    }
    def email_fields = [:]
    email_fields['version'] = workflow.manifest.version
    email_fields['runName'] = custom_runName ?: workflow.runName
    email_fields['success'] = workflow.success
    email_fields['dateComplete'] = workflow.complete
    email_fields['duration'] = workflow.duration
    email_fields['exitStatus'] = workflow.exitStatus
    email_fields['errorMessage'] = (workflow.errorMessage ?: 'None')
    email_fields['errorReport'] = (workflow.errorReport ?: 'None')
    email_fields['commandLine'] = workflow.commandLine
    email_fields['projectDir'] = workflow.projectDir
    email_fields['summary'] = summary
    email_fields['summary']['Date Started'] = workflow.start
    email_fields['summary']['Date Completed'] = workflow.complete
    email_fields['summary']['Pipeline script file path'] = workflow.scriptFile
    email_fields['summary']['Pipeline script hash ID'] = workflow.scriptId
    if (workflow.repository) email_fields['summary']['Pipeline repository Git URL'] = workflow.repository
    if (workflow.commitId) email_fields['summary']['Pipeline repository Git Commit'] = workflow.commitId
    if (workflow.revision) email_fields['summary']['Pipeline Git branch/tag'] = workflow.revision
    email_fields['summary']['Nextflow Version'] = workflow.nextflow.version
    email_fields['summary']['Nextflow Build'] = workflow.nextflow.build
    email_fields['summary']['Nextflow Compile Timestamp'] = workflow.nextflow.timestamp

    // Check if we are only sending emails on failure
    email_address = params.email
    if (!params.email && params.email_on_fail && !workflow.success) {
        email_address = params.email_on_fail
    }

    // Check if we are only sending emails on failure
    email_address = params.email
    if (!params.email && params.email_on_fail && !workflow.success) {
        email_address = params.email_on_fail
    }

    // Render the TXT template
    def engine = new groovy.text.GStringTemplateEngine()
    def tf = new File("$baseDir/assets/email_template.txt")
    def txt_template = engine.createTemplate(tf).make(email_fields)
    def email_txt = txt_template.toString()

    // Render the HTML template
    def hf = new File("$baseDir/assets/email_template.html")
    def html_template = engine.createTemplate(hf).make(email_fields)
    def email_html = html_template.toString()

    // Render the sendmail template
    def smail_fields = [ email: email_address, subject: subject, email_txt: email_txt, email_html: email_html, baseDir: "$baseDir"]
    def sf = new File("$baseDir/assets/sendmail_template.txt")
    def sendmail_template = engine.createTemplate(sf).make(smail_fields)
    def sendmail_html = sendmail_template.toString()

    // Send the HTML e-mail
    if (email_address) {
        try {
            if (params.plaintext_email) { throw GroovyException('Send plaintext e-mail, not HTML') }
            // Try to send HTML e-mail using sendmail
            [ 'sendmail', '-t' ].execute() << sendmail_html
            log.info "[nf-core/imcyto] Sent summary e-mail to $email_address (sendmail)"
        } catch (all) {
            // Catch failures and try with plaintext
            [ 'mail', '-s', subject, email_address ].execute() << email_txt
            log.info "[nf-core/imcyto] Sent summary e-mail to $email_address (mail)"
        }
    }

    // Write summary e-mail HTML to a file
    def output_d = new File("${params.outdir}/pipeline_info/")
    if (!output_d.exists()) {
        output_d.mkdirs()
    }
    def output_hf = new File(output_d, "pipeline_report.html")
    output_hf.withWriter { w -> w << email_html }
    def output_tf = new File(output_d, "pipeline_report.txt")
    output_tf.withWriter { w -> w << email_txt }

    c_green = params.monochrome_logs ? '' : "\033[0;32m";
    c_purple = params.monochrome_logs ? '' : "\033[0;35m";
    c_red = params.monochrome_logs ? '' : "\033[0;31m";
    c_reset = params.monochrome_logs ? '' : "\033[0m";

    if (workflow.stats.ignoredCount > 0 && workflow.success) {
        log.info "-${c_purple}Warning, pipeline completed, but with errored process(es) ${c_reset}-"
        log.info "-${c_red}Number of ignored errored process(es) : ${workflow.stats.ignoredCount} ${c_reset}-"
        log.info "-${c_green}Number of successfully ran process(es) : ${workflow.stats.succeedCount} ${c_reset}-"
    }

    if (workflow.success) {
        log.info "-${c_purple}[nf-core/imcyto]${c_green} Pipeline completed successfully${c_reset}-"
    } else {
        checkHostname()
        log.info "-${c_purple}[nf-core/imcyto]${c_red} Pipeline completed with errors${c_reset}-"
    }

}

def nfcoreHeader() {
    // Log colors ANSI codes
    c_black = params.monochrome_logs ? '' : "\033[0;30m";
    c_blue = params.monochrome_logs ? '' : "\033[0;34m";
    c_cyan = params.monochrome_logs ? '' : "\033[0;36m";
    c_dim = params.monochrome_logs ? '' : "\033[2m";
    c_green = params.monochrome_logs ? '' : "\033[0;32m";
    c_purple = params.monochrome_logs ? '' : "\033[0;35m";
    c_reset = params.monochrome_logs ? '' : "\033[0m";
    c_white = params.monochrome_logs ? '' : "\033[0;37m";
    c_yellow = params.monochrome_logs ? '' : "\033[0;33m";

    return """    -${c_dim}--------------------------------------------------${c_reset}-
                                            ${c_green},--.${c_black}/${c_green},-.${c_reset}
    ${c_blue}        ___     __   __   __   ___     ${c_green}/,-._.--~\'${c_reset}
    ${c_blue}  |\\ | |__  __ /  ` /  \\ |__) |__         ${c_yellow}}  {${c_reset}
    ${c_blue}  | \\| |       \\__, \\__/ |  \\ |___     ${c_green}\\`-._,-`-,${c_reset}
                                            ${c_green}`._,._,\'${c_reset}
    ${c_purple}  nf-core/imcyto v${workflow.manifest.version}${c_reset}
    -${c_dim}--------------------------------------------------${c_reset}-
    """.stripIndent()
}

def checkHostname() {
    def c_reset = params.monochrome_logs ? '' : "\033[0m"
    def c_white = params.monochrome_logs ? '' : "\033[0;37m"
    def c_red = params.monochrome_logs ? '' : "\033[1;91m"
    def c_yellow_bold = params.monochrome_logs ? '' : "\033[1;93m"
    if (params.hostnames) {
        def hostname = "hostname".execute().text.trim()
        params.hostnames.each { prof, hnames ->
            hnames.each { hname ->
                if (hostname.contains(hname) && !workflow.profile.contains(prof)) {
                    log.error "====================================================\n" +
                            "  ${c_red}WARNING!${c_reset} You are running with `-profile $workflow.profile`\n" +
                            "  but your machine hostname is ${c_white}'$hostname'${c_reset}\n" +
                            "  ${c_yellow_bold}It's highly recommended that you use `-profile $prof${c_reset}`\n" +
                            "============================================================"
                }
            }
        }
    }
}
