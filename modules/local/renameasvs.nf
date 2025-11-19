process RENAME_ASVS {
    label 'process_low'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path(st)
    path(rawst)

    output:
    path("seqtab.${params.id_type}.RDS"), emit: seqtable_renamed
    path("asvs.${params.id_type}.nochim.fna"), emit: nonchimeric_asvs
    path("asvs.${params.id_type}.raw.fna"), emit: all_asvs
    path("readmap.RDS"), emit: readmap

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    
    """
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages(library(dada2))
    suppressPackageStartupMessages(library(ShortRead))
    suppressPackageStartupMessages(library(digest))

    # read RDS w/ data
    st <- readRDS("${st}")
    st.raw <- readRDS("${rawst}")

    # get sequences
    seqs <- colnames(st)
    seqs.raw <- colnames(st.raw)

    # get IDs based on idType
    ids_study <- switch("${params.id_type}", simple=paste("ASV", 1:ncol(st), sep = ""),
                                md5=sapply(colnames(st), digest, algo="md5"))
    ids_study.raw <- switch("${params.id_type}", simple=paste("ASV", 1:ncol(st.raw), sep = ""),
                                md5=sapply(colnames(st.raw), digest, algo="md5"))

    # sub IDs
    colnames(st) <- unname(ids_study)
    colnames(st.raw) <- unname(ids_study.raw)

    # generate FASTA
    seqs.dna <- ShortRead(sread = DNAStringSet(seqs), id = BStringSet(ids_study))
    # Write out fasta file.
    writeFasta(seqs.dna, file = 'asvs.${params.id_type}.nochim.fna')

    seqs.dna.raw <- ShortRead(sread = DNAStringSet(seqs.raw), id = BStringSet(ids_study.raw))
    writeFasta(seqs.dna.raw, file = 'asvs.${params.id_type}.raw.fna')

    # replace rownames
    rownames(st) <- gsub("(.R1)?.trim.fastq.gz", "", rownames(st))
    rownames(st) <- gsub(".dd\$", "", rownames(st))
    rownames(st.raw) <- gsub("(.R1)?.trim.fastq.gz", "", rownames(st.raw))
    rownames(st.raw) <- gsub(".dd\$", "", rownames(st.raw))

    # Write modified data (note we only keep the no-chimera reads for the next stage)
    saveRDS(st, "seqtab.${params.id_type}.RDS")
    saveRDS(data.frame(id = ids_study, seq = seqs), "readmap.RDS")
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    """
}
