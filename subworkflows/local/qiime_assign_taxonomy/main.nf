// TODO: at the moment this only uses the naive Bayesian classifier (q2-feature-classifier), 
//       we may add another option to select the specific 
//       QIIME2 classifier to use (feature-classifier, BLAST, VSEARCH)

include { QIIME2_FEATURE_CLASSIFIER             } from '../../../modules/local/qiime2featureclassifier'
include { QIIME2_FEATURE_TO_RDS                 } from '../../../modules/local/qiime2featuretords'

workflow QIIME2_TAXONOMY_CLASSIFIER {

    take:
    asvs_fasta // channel: [ val(meta), [ bam ] ]
    reference

    main:

    ch_versions = Channel.empty()

    // output from this step can either be a final QIIME2 output, or retained as pre-filtered
    QIIME2_FEATURE_CLASSIFIER ( 
        asvs_fasta, 
        reference 
    )
    // ch_versions = ch_versions.mix(QIIME2_FEATURE_CLASSIFIER.out.versions.first())

    // TODO: output from this step would be the final output if filtering is requested
    // TODO: add a *simple* tax filtering step specific for QIIME2 QZA here, using same general
    //       parameters or rules. For now, we just pass everything to RDS conversion
    // TODO: filtering should be on: taxtable, seqtable, ASVs
    // TODO: add seqtable+ASV to QIIME2 here
    // TODO: move outputs from QIIME2 to both R and TSV here
    // TODO: this is also a final output, regardless of filtering above
    // Okay, so we need R files && text output (TSV)
    QIIME2_FEATURE_TO_RDS ( 
      QIIME2_FEATURE_CLASSIFIER.out.taxtab_qiime2_tsv 
    )
    // ch_versions = ch_versions.mix(QIIME2_FEATURE_TO_RDS.out.versions.first())

    emit:
    taxtab_rds      = QIIME2_FEATURE_TO_RDS.out.taxtab_rds      // channel: [ val(meta), [ bam ] ]
    metrics_rds     = QIIME2_FEATURE_TO_RDS.out.metrics_rds     // channel: [ val(meta), [ bai ] ]

    versions = ch_versions                     // channel: [ versions.yml ]
}
