process DADA2_ASSIGN_TAXA_SPECIES {
    label 'process_medium'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path(st)
    path(ref)
    path(sp)
    
    output:
    path("taxtab.original.RDS"), emit: taxtab_rds
    path("bootstraps.original.RDS"), emit: metrics_rds
    
    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def runSpecies = sp.name != "dummy_file" ? "TRUE" : "FALSE"
    """
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages(library(dada2))

    seqs <- readRDS("${st}")
    seqtab <- seqs\$seq

    # Assign taxonomy
    tax <- NULL
    boots <- NULL

    if ( ${params.tax_batch} == 0 | length(seqtab) < ${params.tax_batch} ) { # no batch, run normally
        cat("Running all samples\\n")
        tax <- assignTaxonomy(seqtab, "${ref}",
                        multithread=${task.cpus},
                        tryRC = TRUE,
                        outputBootstraps = TRUE,
                        minBoot = ${params.min_boot},
                        verbose = TRUE)
        boots <- tax\$boot
        if (${runSpecies}) {
            tax <- addSpecies(tax\$tax, "${sp}",
                 tryRC = TRUE,
                 verbose = TRUE)
        } else {
            tax <- tax\$tax
        }
    } else {
        # see https://github.com/benjjneb/dada2/issues/1429 for this
        to_split <- seq(1, length(seqtab), by = ${params.tax_batch})
        to_split2 <- c(to_split[2:length(to_split)]-1, length(seqtab))

        for(i in 1:length(to_split)){
            cat(paste("Running all samples from",to_split[i], "to", to_split2[i], "\\n"))
            seqtab2 <- seqtab[to_split[i]:to_split2[i]]
            tax2 <- assignTaxonomy(seqtab2, "${ref}",
                    multithread=${task.cpus},
                    tryRC = TRUE,
                    outputBootstraps = TRUE,
                    minBoot = ${params.min_boot},
                    verbose = TRUE)

            if (is.null(boots)) {
                boots <- tax2\$boot
            } else {
                boots <- rbind(boots, tax2\$boot)
            }

            if (${runSpecies}) {
                tax2 <- addSpecies(tax2\$tax, 
                    refFasta = "${sp}", 
                    tryRC = TRUE,
                    verbose = TRUE)
            } else {
                tax2 <- tax2\$tax
            }
            if (is.null(tax)) {
                tax <- tax2
            } else {
                tax <- rbind(tax, tax2)
            }
        }
    }

    # make sure these are the same order
    # they should be, but we don't assume this
    rownames(tax) <- seqs[rownames(tax),]\$id
    rownames(boots) <- seqs[rownames(boots),]\$id

    # Write original data
    saveRDS(tax, "taxtab.original.RDS")
    saveRDS(boots, "bootstraps.original.RDS")
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    """
}
