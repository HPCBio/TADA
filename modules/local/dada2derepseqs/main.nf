process DADA2_DEREP_SEQS {
    tag "$meta.id"
    label 'process_medium'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.R[12].derep.RDS"), emit: derep_rds
    // path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def maxrecords = 100000
    // TODO: maybe we check this status 
    """
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages(library(dada2))

    derepsF <- derepFastq("${reads[0]}", 
                        n=${maxrecords}, 
                        verbose=TRUE)
    derepsF\$file <- basename("${reads[0]}")
    saveRDS(derepsF, "${meta.id}.R1.derep.RDS")

    if (!as.logical("${meta.single_end}")) {
        derepsR <- derepFastq("${reads[1]}", 
                            n=${maxrecords}, 
                            verbose=TRUE)

        derepsR\$file <- basename("${reads[1]}")
        saveRDS(derepsR, "${meta.id}.R2.derep.RDS")
    }
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    """
}
