process READ_TRACKING {
    label 'process_low'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path(tracking)

    output:
    path("readtracking.csv"), emit: read_tracking

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    read_tracking.R
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    """
}
