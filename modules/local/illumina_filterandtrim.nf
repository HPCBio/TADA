process ILLUMINA_DADA2_FILTER_AND_TRIM {
    tag "$meta.id"
    label 'process_medium'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}.R[12].trim.fastq.gz"), optional: true, emit: trimmed
    path("*.trimmed.txt"), emit: trimmed_report

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages(library(dada2))

    out <- filterAndTrim(fwd        = "${reads[0]}",
                        filt        = "${meta.id}.R1.trim.fastq.gz",
                        rev         = if("${reads[1]}" == "null") NULL else "${reads[1]}",
                        filt.rev    = if("${reads[1]}" == "null") NULL else "${meta.id}.R2.trim.fastq.gz",
                        trimLeft    = if("${reads[1]}" == "null") ${params.trim_for} else  c(${params.trim_for}, ${params.trim_rev}),
                        truncLen    = if("${reads[1]}" == "null") ${params.trunc_for} else c(${params.trunc_for}, ${params.trunc_rev}),
                        maxEE       = if("${reads[1]}" == "null") ${params.maxEE_for} else c(${params.maxEE_for}, ${params.maxEE_rev}), 
                        truncQ      = ${params.truncQ},
                        maxN        = ${params.maxN},
                        rm.phix     = as.logical("${params.rmPhiX}"),
                        maxLen      = ${params.max_read_len},
                        minLen      = ${params.min_read_len},
                        compress    = TRUE,
                        verbose     = TRUE,
                        multithread = ${task.cpus}
                        )

    colnames(out) <- c('input', 'filtered')

    write.csv(out, "${meta.id}.trimmed.txt")
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