process PER_SAMPLE_SEQTABLE {
   container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

   input:
   path(combined_reads)
   val(readmode)
   val(stage)

   output:
   path("seqtab.${stage}.${readmode}.RDS"), emit: filtered_seqtable
   path("all.${stage}.merged.RDS"), optional: true, emit: merged_seqs
   path("seqtab.original.${stage}.${readmode}.RDS"), emit: seqtabQC
   path("*.csv"), optional: true, emit: readtracking

   when:
   task.ext.when == null || task.ext.when

   script:
   """
   #!/usr/bin/env Rscript
   suppressPackageStartupMessages(library(dada2))
   suppressPackageStartupMessages(library(tidyverse))

   # important point; this instance covers both single-end 
   # and merged data. *Only merged data goes on to read tracking*

   combineFiles <- list.files(path = '.', pattern = '.${stage}.${readmode}.RDS\$')
   pairIds <- sub('.${stage}.${readmode}.RDS', '', combineFiles)
   combined <- lapply(combineFiles, function (x) readRDS(x))
   names(combined) <- pairIds
   seqtab <- makeSequenceTable(combined)
   saveRDS(seqtab, "seqtab.original.${stage}.${readmode}.RDS")

   seqtab_stats <- rowSums(seqtab)
   nms <- gsub(".dd", "", names(seqtab_stats))
   seqtab_stats <- as_tibble_col(seqtab_stats, column_name = "dada.${stage}.seqtab.raw") %>%
      mutate(SampleID = nms, .before = 1)

   write_csv(seqtab_stats, "seqtab.original.${stage}.${readmode}.csv")

   # this is an optional filtering step to remove *merged* sequences based on 
   # min/max length criteria
   if (${params.min_asv_len} > 0) {
      seqtab <- seqtab[,nchar(colnames(seqtab)) >= ${params.min_asv_len}, drop = FALSE]
   }

   if (${params.max_asv_len} > 0) {
      seqtab <- seqtab[,nchar(colnames(seqtab)) <= ${params.min_asv_len}, drop = FALSE]
   }

   saveRDS(seqtab, "seqtab.${stage}.${readmode}.RDS")

   if (${params.min_asv_len} > 0 | ${params.max_asv_len} > 0) {
      seqtab_stats <- rowSums(seqtab)
      nms <- gsub(".dd", "", names(seqtab_stats))
      seqtab_stats <- as_tibble_col(seqtab_stats, column_name = "dada.${stage}.seqtab.lengthfiltered") %>%
         mutate(SampleID = nms, .before = 1)
      write_csv(seqtab_stats, "seqtab.${stage}.${readmode}.lengthfiltered.csv")
   }

   if ("${readmode}" == "merged") {
      mergers <- as.data.frame(sapply(combined, function(x) sum(getUniques(x %>% filter(accept)))))
      colnames(mergers) <- c("dada2.${stage}.merged")
      mergers <- mergers %>% 
         as_tibble() %>%
         mutate(SampleID = rownames(mergers), .before = 1)
      write_csv(as_tibble(mergers), "all_merged.${stage}.csv")
      saveRDS(combined, "all.${stage}.merged.RDS")
   }
   """
}
