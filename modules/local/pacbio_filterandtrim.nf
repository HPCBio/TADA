process PACBIO_DADA2_FILTER_AND_TRIM {
    tag "$meta.id"
    label 'process_medium'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}.R1.trim.fastq.gz"), optional: true, emit: trimmed
    path("*.trimmed.txt"), emit: trimmed_report

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    pacbio_filter_and_trim.R \\
        --reads ${reads} \\
        --sample_id ${meta.id} \\
        --maxEE_for ${params.maxEE_for} \\
        --maxN ${params.maxN} \\
        --max_read_len ${params.max_read_len} \\
        --min_read_len ${params.min_read_len} \\
        --ncpus ${task.cpus}
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.R1.trim.fastq.gz
    touch ${prefix}.R2.trim.fastq.gz
    touch ${prefix}.trimmed.txt
    """
}