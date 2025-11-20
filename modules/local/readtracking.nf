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
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages(library(dada2))
    suppressPackageStartupMessages(library(tidyverse))

    tracking_files <- c(
      list.files(".", "all.trimmed.csv"),             # trimmed (optional)
      list.files(".", "dada2.denoised.*csv"),         # denoised
      list.files(".", "all_merged.*csv"),             # merged (optional)
      list.files(".", "seqtab.original.*.csv"),       # post-seqtable   
      list.files(".", "seqtab.*lengthfiltered.csv"),  # length-filtered (optional)
      list.files(".", "seqtab.nonchimera.csv"),       # non-chimera (optional)
      list.files(".", "searchfiltered.summary.csv"),  # search-filtered (optional)
      list.files(".", "taxfiltered.summary.csv")      # tax-filtered (optional)
    )

    readtracking <- lapply(tracking_files, read_csv) %>% 
      reduce( function(x,y) {
        left_join(x,y, by="SampleID")
      } ) %>%
      relocate(SampleID, .before = 1)

    # dropped data in later steps gets converted to NA on the join
    # these are effectively 0
    readtracking[is.na(readtracking)] <- 0

    write_csv(readtracking, "readtracking.csv")
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    """
}
