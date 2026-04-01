process MERGE_TRIM_TABLES {
    label 'process_low'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path(trimData)
    val(trimmer)

    output:
    path("all.trimmed.csv"), emit: trimmed_report

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix
    """
    merge_trim_tables.R --trimmer ${trimmer}
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix
    """
    touch "all.trimmed.csv"
    """
}
