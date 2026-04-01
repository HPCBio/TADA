process CHECK_FASTQ_QUALITIES {
    tag "$meta.id"
    label 'process_single'

    input:
    tuple val(meta), path(reads)

    output:
    // tuple val(meta), path("*.pdf"), emit: qc
    tuple val(meta), path("quality_bins.RDS"), emit: quality_bins_rds
    // path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    check_fastq_qualities.R \\
        --fwd ${reads[0]} \\
        --sample_id ${meta.id}
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        checkfastqqualities: \$(samtools --version |& sed '1!d ; s/samtools //')
    END_VERSIONS
    """
}
