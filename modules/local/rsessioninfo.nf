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
    #!/usr/bin/env Rscript
    pkgs <- c(
    "RCurl",
    "tidyverse",
    "pander",
    "phangorn",
    "dplyr",
    "dada2",
    "DECIPHER",
    "digest",
    "biomformat",
    "optparse"
    )
    lapply(pkgs, require, character.only = TRUE)

    sink('sessionInfo.Rmd')
    rmd <- pander(sessionInfo(), compact = FALSE)
    sink()
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    """
}
