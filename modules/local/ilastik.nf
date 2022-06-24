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
