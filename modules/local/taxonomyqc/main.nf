process TAXONOMY_QC {
    label 'process_low'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path(taxtab_rds)
    
    output:
    path("assigned_taxonomy.pdf"), emit: taxtab_rds
    
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
    taxa <- readRDS("${taxtab_rds}") 

    freqs <- taxa %>%
      mutate(across(ranks, ~
                      as.factor(
                        case_when(
                          is.na(.) ~ "Unassigned",
                          str_detect(.,"__\$") ~ "Unclassified",
                          TRUE ~ "Classified"
                      )))) %>%
      pivot_longer(!`Feature ID`, names_to = "Rank", values_to = "Status") %>% 
      mutate(Rank = factor(Rank, levels = ranks)) %>%
      group_by(Rank) %>%
      count(Status) 

    bp <- ggplot(freqs, aes(x=Rank, y=n, fill=Status)) + 
      geom_bar(stat = "identity", position = "stack")

    ggsave("assigned_taxonomy.pdf", bp)
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    """
}