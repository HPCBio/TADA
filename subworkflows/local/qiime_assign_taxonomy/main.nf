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

    QIIME2_FEATURE_CLASSIFIER ( 
        asvs_fasta, 
        reference 
    )
    // ch_versions = ch_versions.mix(QIIME2_FEATURE_CLASSIFIER.out.versions.first())

    QIIME2_FEATURE_TO_RDS ( 
      QIIME2_FEATURE_CLASSIFIER.out.taxtab_qiime2_tsv 
    )
    // ch_versions = ch_versions.mix(QIIME2_FEATURE_TO_RDS.out.versions.first())

    emit:
    taxtab_rds      = QIIME2_FEATURE_TO_RDS.out.taxtab_rds      // channel: [ val(meta), [ bam ] ]
    metrics_rds     = QIIME2_FEATURE_TO_RDS.out.metrics_rds     // channel: [ val(meta), [ bai ] ]

    versions = ch_versions                     // channel: [ versions.yml ]
}
