//
// This file holds several functions specific to the workflow/imcyto.nf in the nf-core/imcyto pipeline
//

class WorkflowImcyto {

    //
    // Check and validate parameters
    //
    public static void initialise(params, log) {

        if (!params.metadata) {
            log.error "Metadata csv file not specified!"
            System.exit(1)
        }

        if (!params.full_stack_cppipe) {
            log.error "CellProfiler full stack cppipe file not specified!"
            System.exit(1)
        }

        if (!params.ilastik_stack_cppipe) {
            log.error "Ilastik stack cppipe file not specified!"
            System.exit(1)
        }

        if (!params.segmentation_cppipe) {
            log.error "CellProfiler segmentation cppipe file not specified!"
            System.exit(1)
        }

        if (!params.skip_ilastik) {
            if (!params.ilastik_training_ilp) {
                log.error "Ilastik training ilp file not specified!"
                System.exit(1)
            }
        }

    }

    //
    // Function to get list of [ [ id: sample_id, roi: roi_id ], path_to_file ]
    //
    public static ArrayList flattenTiff(ArrayList channel) {
        def new_array = []
        def file_list = channel[1]
        for (int i=0; i<file_list.size(); i++) {
            def item = []
            def meta = channel[0].clone()
            meta.roi = file_list[i].getParent().getParent().getName()
            item.add(meta)
            item.add(file_list[i])
            new_array.add(item)
        }
        return new_array
    }

}
