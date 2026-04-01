process DADA2_TAXFILTER {
    tag "tax_filter:${params.tax_filter_rank}"
    label 'process_single'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path readmap
    path seqtab
    path taxtab
    path metrics

    output:
    path "seqtab.tax_filtered.RDS", emit: seqtab_tax_filtered_rds
    path "taxfiltered.summary.csv", emit: readtracking
    path "taxtab.tax_filtered.RDS", emit: taxtab_tax_filtered_rds
    path "taxmetrics.tax_filtered.RDS", emit: taxmetrics_tax_filtered_rds
    path "readmap.tax_filtered.RDS", emit: readmap_tax_filtered_rds
    path "asvs.tax_filtered.fna", emit: asvs_tax_filtered
    // path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    dada2_taxfilter.R \\
        --readmap ${readmap} \\
        --seqtab ${seqtab} \\
        --taxtab ${taxtab} \\
        --metrics ${metrics} \\
        --tax_filter_rank ${params.tax_filter_rank}
    """

    // stub:
    // def args = task.ext.args ?: ''
    
    // // TODO nf-core: A stub section should mimic the execution of the original module as best as possible
    // //               Have a look at the following examples:
    // //               Simple example: https://github.com/nf-core/modules/blob/818474a292b4860ae8ff88e149fbcda68814114d/modules/nf-core/bcftools/annotate/main.nf#L47-L63
    // //               Complex example: https://github.com/nf-core/modules/blob/818474a292b4860ae8ff88e149fbcda68814114d/modules/nf-core/bedtools/split/main.nf#L38-L54
    // """
    // touch ${prefix}.bam

    // cat <<-END_VERSIONS > versions.yml
    // "${task.process}":
    //     dada2taxfilter: \$(samtools --version |& sed '1!d ; s/samtools //')
    // END_VERSIONS
    // """
}
