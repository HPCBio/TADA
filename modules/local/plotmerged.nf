process PLOT_MERGED_HEATMAP {
    label 'process_low'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path(mergers)

    output:
    path("read-overlap-heatmap.pdf"), emit: mergers_plot
    path("read-overlap-heatmap.RDS"), emit: mergers_rds

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages(library(tidyverse))

    mergers <- readRDS("${mergers}")

    # filter out any samples w/o reads (nrows == 0)
    all_mergers <- mergers %>% discard( \\(x) nrow(x) == 0 ) %>% bind_rows(.id = 'SampleID')

    all_mergers\$SampleID <- factor(gsub(".R1.filtered.fastq.gz", "", all_mergers\$SampleID))

    # we only keep those that pass here (accept == TRUE)

    gg <- all_mergers %>%
        filter(accept) %>% 
        ggplot(aes(x = nmatch, y = SampleID)) + 
        stat_bin2d(binwidth=c(2,1), aes(fill = after_stat(ncount))) + 
        scale_fill_viridis_c() + 
        theme_minimal()

    if (nlevels(all_mergers\$SampleID) > 40) {
        gg <- gg + theme(axis.text.y=element_blank())
    }

    if (${params.min_asv_len} > 0) {
        gg <- gg + geom_vline(xintercept=${params.min_asv_len}, linetype="dashed", color = "blue")
    }

    if (${params.max_asv_len} > 0) {
        gg <- gg + geom_vline(xintercept=${params.max_asv_len}, linetype="dashed", color = "red")
    }

    img_height <- ifelse(nlevels(all_mergers\$SampleID) <= 50, 0.09 * nlevels(all_mergers\$SampleID), 9)

    ggsave('read-overlap-heatmap.pdf', 
        plot=gg, device = 'pdf', width = 7, height = img_height, units = 'in')

    # save the plot; we may want to make this dynamic (e.g. plotly)
    saveRDS(gg, 'read-overlap-heatmap.RDS')
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    """
}
