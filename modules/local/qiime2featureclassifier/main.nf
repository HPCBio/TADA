process QIIME2_FEATURE_CLASSIFIER {
    label 'process_medium'

    container "quay.io/qiime2/amplicon:2025.7"

    input:
    path(asvs)
    path(ref)
    
    output:
    path("taxtab.qza"), emit: taxtab_qza
    path("asv_sequences.qza"), emit: asvs_qza
    path("taxtab.qzv"), emit: metrics_rds
    path("taxtab.qiime2.tsv"), emit: taxtab_qiime2_tsv
    
    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    qiime tools import \
           --input-path ${asvs} \
           --output-path asv_sequences.qza \
           --type 'FeatureData[Sequence]'
     
    qiime feature-classifier classify-sklearn \
          --i-classifier ${ref} \
          --p-n-jobs ${task.cpus} \
          --i-reads asv_sequences.qza \
          --verbose \
          --o-classification taxtab.qza

    qiime metadata tabulate \
          --m-input-file taxtab.qza \
          --o-visualization taxtab.qzv

    qiime tools export \
          --input-path taxtab.qza \
          --output-path taxtab.qiime2.tsv \
          --output-format "TSVTaxonomyFormat"
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    """
}
