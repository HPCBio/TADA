include { READ_TRACKING          } from '../../modules/local/readtracking'
include { PLOT_MERGED_HEATMAP    } from '../../modules/local/plotmerged'
include { PLOT_ASV_DIST          } from '../../modules/local/plotasvlen'

workflow QUALITY_CONTROL {

    take:
    ch_readtracking
    // ch_merged_seqs
    ch_filtered_seqtable

    main:
    ch_versions = Channel.empty()

    READ_TRACKING(
        ch_readtracking.collect()
    )

    // PLOT_MERGED_HEATMAP(
    //     ch_merged_seqs
    // )

    PLOT_ASV_DIST(
        ch_filtered_seqtable
    )

    emit:
    versions = ch_versions                     // channel: [ versions.yml ]
}

