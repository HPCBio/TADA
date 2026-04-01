process SESSION_INFO {

    label 'process_low'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    output:
    path "sessionInfo.Rmd", emit: session_info
    
    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    session_info.R
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    """
}
