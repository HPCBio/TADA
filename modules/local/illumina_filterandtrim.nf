process ILLUMINA_DADA2_FILTER_AND_TRIM {
    tag "$meta.id"
    label 'process_medium'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}*.trim.fastq.gz"), optional: true, emit: trimmed
    path("*.trimmed.txt"), emit: trimmed_report

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def r1prefix = meta.single_end ? "" : "_1"
    def r2prefix = meta.single_end ? "" : "_2"
    def rev_args = meta.single_end ? "" : "--rev ${reads[1]} --rev_out ${meta.id}${r2prefix}.trim.fastq.gz"
    """
    illumina_filter_and_trim.R \\
        --fwd ${reads[0]} \\
        --fwd_out ${meta.id}${r1prefix}.trim.fastq.gz \\
        ${rev_args} \\
        --sample_id ${meta.id} \\
        --trim_for ${params.trim_for} \\
        --trim_rev ${params.trim_rev} \\
        --trunc_for ${params.trunc_for} \\
        --trunc_rev ${params.trunc_rev} \\
        --maxEE_for ${params.maxEE_for} \\
        --maxEE_rev ${params.maxEE_rev} \\
        --truncQ ${params.truncQ} \\
        --maxN ${params.maxN} \\
        --rmPhiX ${params.rmPhiX} \\
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