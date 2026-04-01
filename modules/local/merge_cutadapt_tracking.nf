process MERGE_CUTADAPT_TRACKING {
    tag "$meta.id"
    label 'process_low'


    input:
    cutadapt_reports.collect()

    output:
    file "all.trimmed.csv", emit: cutadapt_tracking
    // path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    merge_cutadapt_tracking.R
    """

    // stub:
    // def args = task.ext.args ?: ''
    // def prefix = task.ext.prefix ?: "${meta.id}"
    // """
    // """
}
