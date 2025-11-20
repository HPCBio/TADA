process TAXFILTER {
    tag "tax_filter:${params.tax_filter_rank}"
    label 'process_single'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path readmap
    path seqtab
    path taxtab
    path metrics

    output:
    path "seqtab.tax_filtered.RDS", emit: seqtab_tax_filtered_rds
    path "taxfiltered.summary.csv", emit: readtracking
    path "taxtab.tax_filtered.RDS", emit: taxtab_tax_filtered_rds
    path "taxmetrics.tax_filtered.RDS", emit: taxmetrics_tax_filtered_rds
    path "readmap.tax_filtered.RDS", emit: readmap_tax_filtered_rds
    path "asvs.tax_filtered.fna", emit: asvs_tax_filtered
    // path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def rank = params.tax_filter_rank
    """
    #!/usr/bin/env Rscript

    # TODO: quick hack script, could be cleaned up
    suppressPackageStartupMessages(library(dada2))
    suppressPackageStartupMessages(library(ShortRead))
    suppressPackageStartupMessages(library(tidyverse))

    taxtab <- readRDS("${taxtab}")
    taxtab_filtered <- taxtab %>% as_tibble(rownames = "TaxID") %>% filter( !is.na( ${rank} ))
    ids <- taxtab_filtered\$TaxID

    readmap <- readRDS("${readmap}")
    readmap_filtered <- readmap[readmap\$id %in% ids,]

    seqtab <- readRDS("${seqtab}")
    seqtab_filtered <- seqtab[,ids]

    # read tracking
    seqtab.taxfilter <- rowSums(seqtab_filtered)
    nms <- names(seqtab.taxfilter)
    seqtab.taxfilter <- as_tibble_col(seqtab.taxfilter, column_name = "dada2.taxfilter") %>%
      mutate(SampleID = nms, .before = 1)
    write_csv(seqtab.taxfilter, "taxfiltered.summary.csv")

    metrics <- readRDS("${metrics}")
    metrics_filtered <- metrics[ids,]

    asvs_filtered <- DNAStringSet(readmap_filtered\$seq)
    names(asvs_filtered) <- readmap_filtered\$id

    taxtab_filtered <- taxtab_filtered %>% column_to_rownames(var="TaxID") %>% as.matrix()

    writeXStringSet(asvs_filtered, file="asvs.tax_filtered.fna")
    # Write modified data
    saveRDS(seqtab_filtered, "seqtab.tax_filtered.RDS")
    saveRDS(taxtab_filtered, "taxtab.tax_filtered.RDS")
    saveRDS(metrics_filtered, "taxmetrics.tax_filtered.RDS")
    saveRDS(readmap_filtered, "readmap.tax_filtered.RDS")
    """

    // stub:
    // def args = task.ext.args ?: ''
    
    // // TODO nf-core: A stub section should mimic the execution of the original module as best as possible
    // //               Have a look at the following examples:
    // //               Simple example: https://github.com/nf-core/modules/blob/818474a292b4860ae8ff88e149fbcda68814114d/modules/nf-core/bcftools/annotate/main.nf#L47-L63
    // //               Complex example: https://github.com/nf-core/modules/blob/818474a292b4860ae8ff88e149fbcda68814114d/modules/nf-core/bedtools/split/main.nf#L38-L54
    // """
    // touch ${prefix}.bam

    // cat <<-END_VERSIONS > versions.yml
    // "${task.process}":
    //     dada2taxfilter: \$(samtools --version |& sed '1!d ; s/samtools //')
    // END_VERSIONS
    // """
}
