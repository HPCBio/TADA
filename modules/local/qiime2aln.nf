process QIIME2_ALIGNMENT {

    container "quay.io/qiime2/amplicon:2026.1"

    input:
    path(aln)

    output:
    path("aligned_asvs.qza"), emit: alns_qza
    path("versions.yml"), emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    qiime tools import \
        --input-path ${aln} \
        --output-path aligned_asvs.qza \
        --type 'FeatureData[AlignedSequence]'

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: \$( qiime --version | sed '1!d;s/.* //' )
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    touch aligned_asvs.qza

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: \$( qiime --version | sed '1!d;s/.* //' )
    END_VERSIONS    
    """
}
