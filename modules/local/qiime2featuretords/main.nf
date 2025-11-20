process QIIME2_FEATURE_TO_RDS {
    label 'process_low'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path(taxtab_qiime2_tsv)
    
    output:
    path("taxtab.qiime2.RDS"), emit: taxtab_rds
    path("confidence.qiime2.RDS"), emit: metrics_rds
    
    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages(library(tidyverse))

    # TODO: add option to switch ranks
    ranks <- c("Domain", "Phylum", "Class", "Order", "Family", "Genus", "Species")

    # this splits the ranks into separate columns
    qiime2 <- read_tsv("${taxtab_qiime2_tsv}") %>% 
      rename(TaxID = "Feature ID") %>%
      separate(Taxon, sep = ";", into = ranks, fill = "right")

    taxa <- qiime2 %>% 
      select(-c(Confidence, TaxID)) %>%
      as.data.frame()

    rownames(taxa) <- qiime2\$TaxID

    saveRDS(taxa, "taxtab.qiime2.RDS")
    saveRDS(qiime2, "confidence.qiime2.RDS")
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    """
}