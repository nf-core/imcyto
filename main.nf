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
    // TODO nf-core: Add to this help message with new command line parameters
    log.info nfcoreHeader()
    log.info"""

    Usage:

    The typical command for running the pipeline is as follows:
    nextflow run nf-core/imcyto --mcd '*.mcd'--metadata metadata.csv --full_stack_cppipe full_stack.cppipe --ilastik_stack_cppipe ilastik_stack.cppipe --segmentation_cppipe segmentation.cppipe -profile docker

    Mandatory arguments:
      --mcd                         Path to input Mass Cytometery Data file(s) (must be surrounded with quotes)
      --metadata                    Path to metadata csv file indicating which images to merge in full stack and/or ilastik stack
      --full_stack_cppipe           CellProfiler pipeline file required to create full stack (*.cppipe format)
      --ilastik_stack_cppipe        CellProfiler pipeline file required to create Ilastik stack (*.cppipe format)
      --segmentation_cppipe         CellProfiler pipeline file required for segmentation (*.cppipe format)
      -profile                      Configuration profile to use. Can use multiple (comma separated)
                                    Available: docker, singularity, awsbatch, test and more.

    Other options:
      --ilastik_training_ilp        Paramter file required by Ilastik (*.ilp format)
      --plugins                     Directory with plugin files required for CellProfiler. Default: assets/plugins
      --skipIlastik                 Skip Ilastik processing step
      --outdir                      The output directory where the results will be saved
      --email                       Set this parameter to your e-mail address to get a summary e-mail with details of the run sent to you when the workflow exits
      -name                         Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic.

    AWSBatch options:
      --awsqueue                    The AWSBatch JobQueue that needs to be set when running on AWSBatch
      --awsregion                   The AWS Region for your AWS Batch job to run on
    """.stripIndent()
}

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
/* --                                                                     -- */
/* --                SET UP CONFIGURATION VARIABLES                       -- */
/* --                                                                     -- */
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

// Show help message
if (params.help){
    helpMessage()
    exit 0
}

// Has the run name been specified by the user?
//  this has the bonus effect of catching both -name and --name
custom_runName = params.name
if( !(workflow.runName ==~ /[a-z]+_[a-z]+/) ){
    custom_runName = workflow.runName
}

// Stage config files
ch_output_docs = file("$baseDir/docs/output.md")

////////////////////////////////////////////////////
/* --          VALIDATE INPUTS                 -- */
////////////////////////////////////////////////////

/*
 * Create a channel for input Mass Cytometry Data (mcd) files
 */
if( params.mcd ){
    ch_mcd = Channel
        .fromPath(params.mcd, checkIfExists: true)
        .map { it -> [ it.name.take(it.name.lastIndexOf('.')), it ] }
        .ifEmpty { exit 1, "MCD file not found: ${params.mcd}" }
} else {
   exit 1, "MCD file not specified!"
}

if( params.metadata ){ ch_metadata = file(params.metadata, checkIfExists: true) } else { exit 1, "Metadata csv file not specified!" }
if( params.full_stack_cppipe ){ ch_full_stack_cppipe = file(params.full_stack_cppipe, checkIfExists: true) } else { exit 1, "CellProfiler full stack cppipe file not specified!" }
if( params.ilastik_stack_cppipe ){ ch_ilastik_stack_cppipe = file(params.ilastik_stack_cppipe, checkIfExists: true) } else { exit 1, "Ilastik stack cppipe file not specified!" }
if( params.segmentation_cppipe ){ ch_segmentation_cppipe = file(params.segmentation_cppipe, checkIfExists: true) } else { exit 1, "CellProfiler segmentation cppipe file not specified!" }
if( !params.skipIlastik) {
    if( params.ilastik_training_ilp ){ ch_ilastik_training_ilp = file(params.ilastik_training_ilp, checkIfExists: true) } else { exit 1, "Ilastik training ilp file not specified!" }
}

// Plugins required for CellProfiler
Channel.fromPath(params.plugins, checkIfExists: true)
       .into { ch_preprocess_full_stack_plugin;
               ch_preprocess_ilastik_stack_plugin;
               ch_segmentation_plugin }

////////////////////////////////////////////////////
/* --                   AWS                    -- */
////////////////////////////////////////////////////

if( workflow.profile == 'awsbatch') {
  // AWSBatch sanity checking
  if (!params.awsqueue || !params.awsregion) exit 1, "Specify correct --awsqueue and --awsregion parameters on AWSBatch!"
  // Check outdir paths to be S3 buckets if running on AWSBatch
  // related: https://github.com/nextflow-io/nextflow/issues/813
  if (!params.outdir.startsWith('s3:')) exit 1, "Outdir not on S3 - specify S3 Bucket to run on AWSBatch!"
  // Prevent trace files to be stored on S3 since S3 does not support rolling files.
  if (workflow.tracedir.startsWith('s3:')) exit 1, "Specify a local tracedir or run without trace! S3 cannot be used for tracefiles."
}

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
/* --                                                                     -- */
/* --                       HEADER LOG INFO                               -- */
/* --                                                                     -- */
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

// Header log info
log.info nfcoreHeader()
def summary = [:]
summary['Run Name']                     = custom_runName ?: workflow.runName
summary['MCD Files']                    = params.mcd
summary['Metadata File']                = params.metadata
summary['Full Stack cppipe File']       = params.full_stack_cppipe
summary['Ilastik Stack cppipe File']    = params.ilastik_stack_cppipe
summary['Skip Ilastik Step']            = params.skipIlastik ? 'Yes' : 'No'
if(!params.skipIlastik) summary['Ilastik Training ilp File'] = params.ilastik_training_ilp
summary['Segmentation cppipe File']     = params.segmentation_cppipe
summary['Imctools Container']           = params.imctools_container
summary['CellProfiler Container']       = params.cellprofiler_container
summary['Ilastik Container']            = params.ilastik_container
summary['R-markdown Container']         = params.rmarkdown_container
summary['Max Resources']    = "$params.max_memory memory, $params.max_cpus cpus, $params.max_time time per job"
if(workflow.containerEngine) summary['Container'] = "$workflow.containerEngine - $workflow.container"
summary['Output Dir']                   = params.outdir
summary['Launch Dir']                   = workflow.launchDir
summary['Working Dir']                  = workflow.workDir
summary['Script Dir']                   = workflow.projectDir
summary['User']                         = workflow.userName
summary['Config Profile']               = workflow.profile
if(params.config_profile_description) summary['Config Description'] = params.config_profile_description
if(params.config_profile_contact)     summary['Config Contact']     = params.config_profile_contact
if(params.config_profile_url)         summary['Config URL']         = params.config_profile_url
if(workflow.profile == 'awsbatch'){
   summary['AWS Region']                = params.awsregion
   summary['AWS Queue']                 = params.awsqueue
}
if(params.email) summary['E-mail Address']  = params.email
log.info summary.collect { k,v -> "${k.padRight(25)}: $v" }.join("\n")
log.info "\033[2m----------------------------------------------------\033[0m"

// Check the hostnames against configured profiles
checkHostname()

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
/* --                                                                     -- */
/* --                           MAIN PIPELINE                             -- */
/* --                                                                     -- */
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

/*
 * STEP 1 - IMCTOOLS
 */
process imctools {
    tag "$name"
    label 'process_medium'
    container = params.imctools_container
    publishDir "${params.outdir}/imctools/${name}", mode: 'copy',
        saveAs: {filename ->
            if (filename.indexOf("version.txt") > 0) null
            else filename
        }

    input:
    set val(name), file(mcd) from ch_mcd
    file metadata from ch_metadata

    output:
    set val(name), file("*/full_stack/*") into ch_full_stack_tiff
    set val(name), file("*/ilastik_stack/*") into ch_ilastik_stack_tiff
    file "*version.txt" into ch_imctools_version

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
ch_full_stack_tiff.map { flatten_tiff(it) }
                  .flatten()
                  .collate(3)
                  .groupTuple(by: [0,1])
                  .map { it -> [ it[0], it[1], it[2].sort() ] }
                  .set { ch_full_stack_tiff }

// Group ilastik stack files by sample and roi_id
ch_ilastik_stack_tiff.map { flatten_tiff(it) }
                     .flatten()
                     .collate(3)
                     .groupTuple(by: [0,1])
                     .map { it -> [ it[0], it[1], it[2].sort() ] }
                     .set { ch_ilastik_stack_tiff }

/*
* STEP 2 - PREPROCESS FULL STACK IMAGES WITH CELLPROFILER
*/
process preprocessFullStack {
    tag "${name}.${roi}"
    label 'process_medium'
    container = params.cellprofiler_container
    publishDir "${params.outdir}/preprocess/${name}/${roi}", mode: 'copy',
        saveAs: {filename ->
            if (filename.indexOf("version.txt") > 0) null
            else filename
        }

    input:
    set val(name), val(roi), file(tiff) from ch_full_stack_tiff
    file cppipe from ch_full_stack_cppipe
    file plugin_dir from ch_preprocess_full_stack_plugin.collect()

    output:
    set val(name), val(roi), file("full_stack/*") into ch_preprocess_full_stack_tiff
    file "*version.txt" into ch_cellprofiler_version

    script:
    """
    export _JAVA_OPTIONS="-Xms${task.memory.toGiga()/2}g -Xmx${task.memory.toGiga()}g"
    cellprofiler --run-headless \\
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
* STEP 3 - PREPROCESS ILASTIK STACK IMAGES WITH CELLPROFILER
*/
process preprocessIlastikStack {
    tag "${name}.${roi}"
    label 'process_medium'
    container = params.cellprofiler_container
    publishDir "${params.outdir}/preprocess/${name}/${roi}", mode: 'copy'

    input:
    set val(name), val(roi), file(tiff) from ch_ilastik_stack_tiff
    file cppipe from ch_ilastik_stack_cppipe
    file plugin_dir from ch_preprocess_ilastik_stack_plugin.collect()

    output:
    set val(name), val(roi), file("ilastik_stack/*") into ch_preprocess_ilastik_stack_tiff

    script:
    """
    export _JAVA_OPTIONS="-Xms${task.memory.toGiga()/2}g -Xmx${task.memory.toGiga()}g"
    cellprofiler --run-headless \\
                 --pipeline $cppipe \\
                 --image-directory ./ \\
                 --plugins-directory ./${plugin_dir} \\
                 --output-directory ./ilastik_stack \\
                 --log-level DEBUG \\
                 --temporary-directory ./tmp
    """
}

/*
 * STEP 4 - ILASTIK
 */
if( params.skipIlastik ) {
  ch_preprocess_full_stack_tiff.join(ch_preprocess_ilastik_stack_tiff, by: [0,1])
                            .map { it -> [ it[0], it[1], [ it[2], it[3] ].flatten().sort() ] }
                            .set { ch_preprocess_full_stack_tiff }
  ch_ilastik_version = []
} else {
    process ilastik {
        tag "${name}.${roi}"
        label 'process_medium'
        container = params.ilastik_container
        publishDir "${params.outdir}/ilastik/${name}/${roi}", mode: 'copy',
            saveAs: {filename ->
                if (filename.indexOf("version.txt") > 0) null
                else filename
            }

        input:
        set val(name), val(roi), file(tiff) from ch_preprocess_ilastik_stack_tiff
        file ilastik_training_ilp from ch_ilastik_training_ilp

        output:
        set val(name), val(roi), file("*.tiff") into ch_ilastik_tiff
        file "*version.txt" into ch_ilastik_version

        script:
        """
        cp $ilastik_training_ilp ilastik_params.ilp

        /ilastik-release/run_ilastik.sh --headless \\
                       --project=ilastik_params.ilp \\
                       --output_format="tiff sequence" \\
                       --output_filename_format=./{nickname}_{result_type}_{slice_index}.tiff \\
                       $tiff
        rm  ilastik_params.ilp

        /ilastik-release/bin/python -c "import ilastik; print(ilastik.__version__)" > ilastik_version.txt
        """
    }
    ch_preprocess_full_stack_tiff.join(ch_ilastik_tiff, by: [0,1])
                            .map { it -> [ it[0], it[1], [ it[2], it[3] ].flatten().sort() ] }
                            .set { ch_preprocess_full_stack_tiff }
}

/*
 * STEP 5 - SEGMENTATION WITH CELLPROFILER
 */
process segmentation {
    tag "${name}.${roi}"
    label 'process_big'
    container = params.cellprofiler_container
    publishDir "${params.outdir}/segmentation/${name}/${roi}", mode: 'copy'

    input:
    set val(name), val(roi), file(tiff) from ch_preprocess_full_stack_tiff
    file cppipe from ch_segmentation_cppipe
    file plugin_dir from ch_segmentation_plugin.collect()

    output:
    set val(name), val(roi), file("*.csv") into ch_segmentation_csv
    set val(name), val(roi), file("*.tiff") into ch_segmentation_tiff

    script:
    """
    export _JAVA_OPTIONS="-Xms${task.memory.toGiga()/2}g -Xmx${task.memory.toGiga()}g"
    cellprofiler --run-headless \\
                 --pipeline $cppipe \\
                 --image-directory ./ \\
                 --plugins-directory ./${plugin_dir} \\
                 --output-directory ./ \\
                 --log-level DEBUG \\
                 --temporary-directory ./tmp
    """
}

/*
 * STEP 6 - Output Description HTML
 */
process output_documentation {
    container = params.rmarkdown_container
    publishDir "${params.outdir}/pipeline_info", mode: 'copy'

    input:
    file output_docs from ch_output_docs

    output:
    file "results_description.html"

    script:
    """
    markdown_to_html.r $output_docs results_description.html
    """
}

/*
 * Parse software version numbers
 */
process get_software_versions {
    container = params.cellprofiler_container
    publishDir "${params.outdir}/pipeline_info", mode: 'copy',
        saveAs: {filename ->
            if (filename.indexOf(".csv") > 0) filename
            else null
        }

    input:
    file imctools from ch_imctools_version.first()
    file cellprofiler from ch_cellprofiler_version.first()
    file ilastik from ch_ilastik_version.first()

    output:
    file "software_versions.csv"

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
    if(!workflow.success){
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
    if(workflow.repository) email_fields['summary']['Pipeline repository Git URL'] = workflow.repository
    if(workflow.commitId) email_fields['summary']['Pipeline repository Git Commit'] = workflow.commitId
    if(workflow.revision) email_fields['summary']['Pipeline Git branch/tag'] = workflow.revision
    if(workflow.container) email_fields['summary']['Docker image'] = workflow.container
    email_fields['summary']['Nextflow Version'] = workflow.nextflow.version
    email_fields['summary']['Nextflow Build'] = workflow.nextflow.build
    email_fields['summary']['Nextflow Compile Timestamp'] = workflow.nextflow.timestamp

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
    def smail_fields = [ email: params.email, subject: subject, email_txt: email_txt, email_html: email_html, baseDir: "$baseDir"]
    def sf = new File("$baseDir/assets/sendmail_template.txt")
    def sendmail_template = engine.createTemplate(sf).make(smail_fields)
    def sendmail_html = sendmail_template.toString()

    // Send the HTML e-mail
    if (params.email) {
        try {
          if( params.plaintext_email ){ throw GroovyException('Send plaintext e-mail, not HTML') }
          // Try to send HTML e-mail using sendmail
          [ 'sendmail', '-t' ].execute() << sendmail_html
          log.info "[nf-core/imcyto] Sent summary e-mail to $params.email (sendmail)"
        } catch (all) {
          // Catch failures and try with plaintext
          [ 'mail', '-s', subject, params.email ].execute() << email_txt
          log.info "[nf-core/imcyto] Sent summary e-mail to $params.email (mail)"
        }
    }

    // Write summary e-mail HTML to a file
    def output_d = new File( "${params.outdir}/pipeline_info/" )
    if( !output_d.exists() ) {
      output_d.mkdirs()
    }
    def output_hf = new File( output_d, "pipeline_report.html" )
    output_hf.withWriter { w -> w << email_html }
    def output_tf = new File( output_d, "pipeline_report.txt" )
    output_tf.withWriter { w -> w << email_txt }

    c_reset = params.monochrome_logs ? '' : "\033[0m";
    c_purple = params.monochrome_logs ? '' : "\033[0;35m";
    c_green = params.monochrome_logs ? '' : "\033[0;32m";
    c_red = params.monochrome_logs ? '' : "\033[0;31m";

    if (workflow.stats.ignoredCount > 0 && workflow.success) {
      log.info "${c_purple}Warning, pipeline completed, but with errored process(es) ${c_reset}"
      log.info "${c_red}Number of ignored errored process(es) : ${workflow.stats.ignoredCount} ${c_reset}"
      log.info "${c_green}Number of successfully ran process(es) : ${workflow.stats.succeedCount} ${c_reset}"
    }

    if(workflow.success){
        log.info "${c_purple}[nf-core/imcyto]${c_green} Pipeline completed successfully${c_reset}"
    } else {
        checkHostname()
        log.info "${c_purple}[nf-core/imcyto]${c_red} Pipeline completed with errors${c_reset}"
    }

}

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
/* --                                                                     -- */
/* --                       NF-CORE HEADER                                -- */
/* --                                                                     -- */
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

def nfcoreHeader(){
    // Log colors ANSI codes
    c_reset = params.monochrome_logs ? '' : "\033[0m";
    c_dim = params.monochrome_logs ? '' : "\033[2m";
    c_black = params.monochrome_logs ? '' : "\033[0;30m";
    c_green = params.monochrome_logs ? '' : "\033[0;32m";
    c_yellow = params.monochrome_logs ? '' : "\033[0;33m";
    c_blue = params.monochrome_logs ? '' : "\033[0;34m";
    c_purple = params.monochrome_logs ? '' : "\033[0;35m";
    c_cyan = params.monochrome_logs ? '' : "\033[0;36m";
    c_white = params.monochrome_logs ? '' : "\033[0;37m";

    return """    ${c_dim}----------------------------------------------------${c_reset}
                                            ${c_green},--.${c_black}/${c_green},-.${c_reset}
    ${c_blue}        ___     __   __   __   ___     ${c_green}/,-._.--~\'${c_reset}
    ${c_blue}  |\\ | |__  __ /  ` /  \\ |__) |__         ${c_yellow}}  {${c_reset}
    ${c_blue}  | \\| |       \\__, \\__/ |  \\ |___     ${c_green}\\`-._,-`-,${c_reset}
                                            ${c_green}`._,._,\'${c_reset}
    ${c_purple}  nf-core/imcyto v${workflow.manifest.version}${c_reset}
    ${c_dim}----------------------------------------------------${c_reset}
    """.stripIndent()
}

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
/* --                                                                     -- */
/* --                       HOSTNAME CHECK                                -- */
/* --                                                                     -- */
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

def checkHostname(){
    def c_reset = params.monochrome_logs ? '' : "\033[0m"
    def c_white = params.monochrome_logs ? '' : "\033[0;37m"
    def c_red = params.monochrome_logs ? '' : "\033[1;91m"
    def c_yellow_bold = params.monochrome_logs ? '' : "\033[1;93m"
    if(params.hostnames){
        def hostname = "hostname".execute().text.trim()
        params.hostnames.each { prof, hnames ->
            hnames.each { hname ->
                if(hostname.contains(hname) && !workflow.profile.contains(prof)){
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

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
/* --                                                                     -- */
/* --                        END OF PIPELINE                              -- */
/* --                                                                     -- */
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
