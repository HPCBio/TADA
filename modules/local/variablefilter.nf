process VARIABLEFILTER {
    tag "$meta.id"
    label 'process_medium'
    container ""

    input:
    tuple val(meta), file(reads), file(trimming) from itsStep3.join(itsStep3Trimming)

    output:
    tuple val(meta), file("${meta.id}.R1.filtered.fastq.gz") optional true, emit: filteredReadsR1
    tuple val(meta), file("${meta.id}.R2.filtered.fastq.gz") optional true, emit: filteredReadsR2
    tuple val(meta), file("${meta.id}.R[12].filtered.fastq.gz") optional true, emit: reads
    file "*.trimmed.txt", emit: read_tracking

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def singleEnd = meta.single_end ? "--single_end TRUE" : ""
    """
    variable_filter.R \\
        --sample_id ${meta.id} \\
        ${singleEnd} \\
        --maxEE_for ${params.maxEEFor} \\
        --maxEE_rev ${params.maxEERev} \\
        --truncQ ${params.truncQ} \\
        --rmPhiX ${params.rmPhiX} \\
        --max_read_len ${params.max_read_len} \\
        --min_read_len ${params.min_read_len} \\
        --ncpus ${task.cpus}
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch "${meta.id}.trimmed.txt"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        variablefilter: \$(samtools --version |& sed '1!d ; s/samtools //')
    END_VERSIONS
    """
}
