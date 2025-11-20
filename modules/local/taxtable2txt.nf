process DADA2_TAXTABLE2TEXT {

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path(taxtab_rds)
    path(metrics_rds)

    output:
    path("taxtab.txt"), emit: taxtab
    path("metrics.txt"), emit: metrics
    path("taxtab.RDS"), emit: taxtab_final_rds
    path("taxmetrics.RDS"), emit: taxmetrics_final_rds

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    
    """
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages(library(dada2))
    suppressPackageStartupMessages(library(tidyverse))

    tax <- readRDS("${taxtab_rds}")

    # Generate table output
    # Note that we use the old ASV ID for output here

    write.table(data.frame('ASVID' = row.names(tax), tax),
        file = 'taxtab.txt',
        row.names = FALSE,
        col.names=c('#OTU ID', colnames(tax)), sep = "\\t")

    taxa_combined <- apply(tax, 1, function(x) paste(x, collapse=";"))
    taxa_out <- data.frame(names(taxa_combined), taxa_combined)
    colnames(taxa_out) <- c("#OTU ID", "taxonomy")

    write.table(data.frame('ASVID' = row.names(tax), tax),
        file = 'taxtab.full.txt',
        row.names = FALSE,
        col.names=c('#OTU ID', colnames(tax)), sep = "\\t")

    if (file.exists("${metrics_rds}")) {
        boots <- readRDS("${metrics_rds}")
        write.table(data.frame('ASVID' = row.names(boots), boots),
            file = 'metrics.txt',
            row.names = FALSE,
            col.names=c('#OTU ID', colnames(boots)), sep = "\\t")
    }

    # Write modified data
    saveRDS(tax, "taxtab.RDS")
    saveRDS(boots, "taxmetrics.RDS")
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    """
}
