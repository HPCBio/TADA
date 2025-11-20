process PER_SAMPLE_MERGE {
    tag "$meta.id"
    label 'process_low'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    tuple val(meta), path(dds), path(dereps)
    val(stage)

    output:
    tuple val(meta), path("${meta.id}.${stage}.merged.RDS"), emit: merged_reads

    when:
    meta.single_end == false && (task.ext.when == null || task.ext.when)

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages(library(dada2))
    suppressPackageStartupMessages(library(dplyr))

    ddF <- readRDS("${dds[0]}")
    ddR <- readRDS("${dds[1]}")
    derepF <- readRDS("${dereps[0]}")
    derepR <- readRDS("${dereps[1]}")
    merger <- mergePairs(ddF, derepF, ddR, derepR,
        returnRejects = TRUE,
        minOverlap = ${params.min_overlap},
        maxMismatch = ${params.max_mismatch},
        trimOverhang = as.logical("${params.trim_overhang}"),
        justConcatenate=as.logical("${params.just_concatenate}")
    )

    saveRDS(merger, paste("${meta.id}.${stage}.merged.RDS", sep="."))
    """
}
