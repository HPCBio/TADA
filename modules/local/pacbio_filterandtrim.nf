process PACBIO_DADA2_FILTER_AND_TRIM {
    tag "$meta.id"
    label 'process_medium'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}.R1.trim.fastq.gz"), optional: true, emit: trimmed
    path("*.trimmed.txt"), emit: trimmed_report

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages(library(dada2))
    suppressPackageStartupMessages(library(ShortRead))
    suppressPackageStartupMessages(library(Biostrings))

    out2 <- filterAndTrim(fwd = "${reads}",
                        filt = "${meta.id}.R1.trim.fastq.gz",
                        maxEE = ${params.maxEE_for},
                        maxN = ${params.maxN},
                        maxLen = ${params.max_read_len},
                        minLen = ${params.min_read_len},
                        compress = TRUE,
                        verbose = TRUE,
                        multithread = ${task.cpus})

    #Change input read counts to actual raw read counts
    write.csv(out2, paste0("${meta.id}", ".trimmed.txt"))
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.R1.trim.fastq.gz
    touch ${prefix}.R2.trim.fastq.gz
    touch ${prefix}.trimmed.txt
    """
}