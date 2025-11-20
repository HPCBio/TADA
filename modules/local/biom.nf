process BIOM {
    label 'process_low'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path(seqtab) 
    path(taxtab)

    output:
    path("final.biom"), emit: biom

    when:
    task.ext.when == null || task.ext.when || params.toBIOM == true

    script:
    def args = task.ext.args ?: ''
    
    """
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages(library(biomformat))
    packageVersion("biomformat")
    seqtab <- readRDS("${seqtab}")
    taxtab <- readRDS("${taxtab}")
    st.biom <- make_biom(t(seqtab), observation_metadata = taxtab)
    write_biom(st.biom, "final.biom")
    """

    stub:
    def args = task.ext.args ?: ''
    """
    """
}
