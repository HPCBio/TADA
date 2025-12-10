include { DADA2_POOLED_INFER                    } from '../../../modules/local/dadainfer'
include { DADA2_POOLED_SEQTABLE                 } from '../../../modules/local/pooledseqtable'

workflow DADA2_POOLED_DENOISE {

    take:
    ch_errs
    ch_trimmed_per_read

    main:
    ch_versions = Channel.empty()
    ch_readtracking = Channel.empty()

    ch_batch_errs = ch_errs.join(ch_trimmed_per_read)
    
    DADA2_POOLED_INFER(ch_batch_errs)

    DADA2_POOLED_SEQTABLE(
        DADA2_POOLED_INFER.out.inferred.map { it[1] }.collect(),
        ch_trimmed_per_read.map { it[1]}.collect() )

    ch_readtracking = ch_readtracking.mix(
            DADA2_POOLED_INFER.out.readtracking.collect(),
            DADA2_POOLED_SEQTABLE.out.readtracking,
        )

    emit:
    // TODO: switch this to read-tracking
    inferred = DADA2_POOLED_INFER.out.inferred
    merged_seqs = DADA2_POOLED_SEQTABLE.out.merged_seqs
    filtered_seqtable = DADA2_POOLED_SEQTABLE.out.filtered_seqtable
    versions = ch_versions                     // channel: [ versions.yml ]
    readtracking = ch_readtracking             // channel: [ readtracking.csv ]

}
