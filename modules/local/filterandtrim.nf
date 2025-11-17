process ILLUMINA_DADA2_FILTER_AND_TRIM {
    tag "$meta.id"
    label 'process_medium'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}.R1.filtered.fastq.gz"), optional: true, emit: trimmed_R1
    tuple val(meta), path("${meta.id}.R2.filtered.fastq.gz"), optional: true, emit: trimmed_R2
    tuple val(meta), path("${meta.id}.R[12].filtered.fastq.gz"), optional: true, emit: trimmed
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
                        filt        = "${meta.id}.R1.filtered.fastq.gz",
                        rev         = if("${reads[1]}" == "null") NULL else "${reads[1]}",
                        filt.rev    = if("${reads[1]}" == "null") NULL else "${meta.id}.R2.filtered.fastq.gz",
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
    touch ${prefix}.R1.filtered.fastq.gz
    touch ${prefix}.R2.filtered.fastq.gz
    touch ${prefix}.trimmed.txt
    """
}

process PACBIO_CUTADAPT_FILTER_AND_TRIM {
    tag { "PacBioTrim_${meta.id}" }

    // container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    // TODO: Note the channel name here should probably be changed
    tuple val(meta), path(reads)

    output:
    // tuple val(meta), file("${meta.id}.R1.filtered.fastq.gz") optional true into filteredReadsR1
    tuple val(meta), file("${meta.id}.noprimer.fastq.gz"), optional: true, emit: cutadapt_trimmed
    file("*.cutadapt.out"), emit: cutadapt_report
    file("${meta.id}.untrimmed.fastq.gz"), emit: cutadapt_untrimmed

    when:
    !(params.precheck)

    script:
    strictness = params.cutadapt_strict_match ? '-g' : '-a'
    """
    # Logic: we should trim out the HiFi reads and require *both* primers be present (-g).
    # This should also reorient the sequence to match the primers (--rc).
    # Keep anything longer than 50bp, and allow users to filter their data by length later
    revprimer_rc=\$( echo -n ${params.rev_primer} | tr "[ATGCUNYRSWKMBDHV]" "[TACGANRYSWMKVHDB]" | rev )

    cutadapt --rc \\
        ${strictness} "${params.fwd_primer}...\${revprimer_rc}" \\
        -m 50 \\
        -j ${task.cpus} \\
        --untrimmed-output "${meta.id}.untrimmed.fastq.gz" \\
        -o "${meta.id}.noprimer.fastq.gz" \\
        ${reads} > "${meta.id}.noprimer.cutadapt.out"
    """
}

process PACBIO_DADA2_FILTER_AND_TRIM {
    tag "$meta.id"
    label 'process_medium'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}.R1.filtered.fastq.gz"), optional: true, emit: trimmed
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
                        filt = "${meta.id}.R1.filtered.fastq.gz",
                        maxEE = ${params.maxEEFor},
                        maxN = ${params.maxN},
                        maxLen = ${params.maxLen},
                        minLen = ${params.minLen},
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
    touch ${prefix}.R1.filtered.fastq.gz
    touch ${prefix}.R2.filtered.fastq.gz
    touch ${prefix}.trimmed.txt
    """
}