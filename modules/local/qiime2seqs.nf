process QIIME2_SEQUENCE {

    container "quay.io/qiime2/amplicon:2026.1"

    input:
    path(seqs)

    output:
    path("asv_sequences.qza"), emit: asvs_qza
    path("asv_sequences.qzv"), emit: asvs_qzv
    path("versions.yml"), emit: versions

    when:
    task.ext.when == null || task.ext.when 

    script:
    def args = task.ext.args ?: ''
    """
    qiime tools import \
        --input-path ${seqs} \
        --output-path asv_sequences.qza \
        --type 'FeatureData[Sequence]'

    qiime feature-table tabulate-seqs \
      --i-data asv_sequences.qza \
      --o-visualization asv_sequences.qzv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: \$( qiime --version | sed '1!d;s/.* //' )
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    touch asv_sequences.qza

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: \$( qiime --version | sed '1!d;s/.* //' )
    END_VERSIONS    
    """
}
