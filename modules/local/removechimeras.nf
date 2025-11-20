process DADA2_REMOVE_CHIMERAS {
    label 'process_medium'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path(st)

    output:
    path("seqtab.nonchim.RDS"), emit: nonchim_seqtable
    path("seqtab.nonchimera.csv"), emit: readtracking

    when:
    task.ext.when == null || task.ext.when

    script:
    chimOpts = params.removeBimeraDenovo_options ? ", ${params.removeBimeraDenovo_options}" : ""
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix
    """
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages(library(dada2))
    suppressPackageStartupMessages(library(tidyverse))
    st.all <- readRDS("${st}")

    # Remove chimeras
    seqtab <- removeBimeraDenovo(
        st.all, 
        method="consensus", 
        multithread=${task.cpus}, 
        verbose=TRUE ${chimOpts} 
        )

    saveRDS(seqtab, "seqtab.nonchim.RDS")

    # read tracking
    seqtab.nonchim <- rowSums(seqtab)
    nms <- gsub('.R1.filtered.fastq.gz', '',names(seqtab.nonchim))
    nms <- gsub(".dd\$", "", nms)
    seqtab.nonchim <- as_tibble_col(seqtab.nonchim, column_name = "dada2.nonchim") %>%
      mutate(SampleID = nms, .before = 1)
    write_csv(seqtab.nonchim, "seqtab.nonchimera.csv")
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix
    """

    """
}
