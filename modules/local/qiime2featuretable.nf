process QIIME2_FEATURETABLE {

    container "quay.io/qiime2/amplicon:2026.1"
    
    input:
    path(seqtab)

    output:
    path("seqtab.qza"), emit: seqtab_qza
    path("seqtab.qzv"), emit: seqtab_qzv
    path("versions.yml"), emit: versions

    when:
    task.ext.when == null || task.ext.when 

    script:
    def args = task.ext.args ?: ''
    """
    biom convert -i ${seqtab} \
        -o seqtab-biom-table.biom \
        --table-type="OTU table" \
        --to-hdf5

    qiime tools import \
        --input-path seqtab-biom-table.biom \
        --input-format BIOMV210Format \
        --output-path seqtab.qza \
        --type 'FeatureTable[Frequency]'

    qiime feature-table summarize \
      --i-table seqtab.qza \
      --o-visualization seqtab.qzv

    # TODO: we don't include metadata yet
    # --m-sample-metadata-file sample-metadata.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: \$( qiime --version | sed '1!d;s/.* //' )
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    touch seqtab.qza

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: \$( qiime --version | sed '1!d;s/.* //' )
    END_VERSIONS    
    """
}
