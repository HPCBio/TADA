// TODO: rename file to dada2pooledseqtable
process DADA2_POOLED_SEQTABLE {
   label 'process_medium'

   container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

   input:
   path(dds)
   path(filts)

   output:
   path("seqtab.lengthfiltered.RDS"), emit: filtered_seqtable
   path("all.merged.RDS"), optional: true, emit: merged_seqs
   path("seqtab.full.RDS"), emit: full_seqtable// we keep this for comparison and possible QC    
   path("*.csv"), emit: readtracking

   when:
   task.ext.when == null || task.ext.when

   script:
   def args = task.ext.args ?: ''
   def readmode = dds.size() == 2 ? 'merged' : 'R1'

   """
   #!/usr/bin/env Rscript
   suppressPackageStartupMessages(library(dada2))
   suppressPackageStartupMessages(library(tidyverse))

   rescuePairs <- as.logical("${params.rescue_unmerged}")

   mergePairsRescue <- function(dadaF, derepF, dadaR, derepR,
                           minOverlap = 12, maxMismatch=0, returnRejects=FALSE,
                           propagateCol=character(0), justConcatenate=FALSE,
                           trimOverhang=FALSE, verbose=FALSE, rescueUnmerged=FALSE, ...) {
      if(is(dadaF, "dada")) dadaF <- list(dadaF)
      if(is(dadaR, "dada")) dadaR <- list(dadaR)
      if(is(derepF, "derep")) derepF <- list(derepF)
         else if(is(derepF, "character") && length(derepF)==1 && dir.exists(derepF)) derepF <- parseFastqDirectory(derepF)
      if(is(derepR, "derep")) derepR <- list(derepR)
         else if(is(derepR, "character") && length(derepR)==1 && dir.exists(derepR)) derepR <- parseFastqDirectory(derepR)
      
      if( !(is.list.of(dadaF, "dada") && is.list.of(dadaR, "dada")) ) {
         stop("dadaF and dadaR must be provided as dada-class objects or lists of dada-class objects.")
      }
      if( !( (is.list.of(derepF, "derep") || is(derepF, "character")) &&
            (is.list.of(derepR, "derep") || is(derepR, "character")) )) {
       stop("derepF and derepR must be provided as derep-class objects or as character vectors of filenames.")
      }
      nrecs <- c(length(dadaF), length(derepF), length(dadaR), length(derepR))
      if(length(unique(nrecs))>1) stop("The dadaF/derepF/dadaR/derepR arguments must be the same length.")

      rval <- lapply(seq_along(dadaF), function (i)  {
      mapF <- getDerep(derepF[[i]])\$map
      mapR <- getDerep(derepR[[i]])\$map
      if(!(is.integer(mapF) && is.integer(mapR))) stop("Incorrect format of \$map in derep-class arguments.")
      #    if(any(is.na(rF)) || any(is.na(rR))) stop("Non-corresponding maps and dada-outputs.")
      if(!(length(mapF) == length(mapR) && 
           max(mapF, na.rm=TRUE) == length(dadaF[[i]]\$map) &&
           max(mapR, na.rm=TRUE) == length(dadaR[[i]]\$map))) {
         stop("Non-corresponding derep-class and dada-class objects.")
      }
      rF <- dadaF[[i]]\$map[mapF]
      rR <- dadaR[[i]]\$map[mapR]

      pairdf <- data.frame(sequence = "", abundance=0, forward=rF, reverse=rR)
      ups <- unique(pairdf) # The unique forward/reverse pairs of denoised sequences
      keep <- !is.na(ups\$forward) & !is.na(ups\$reverse)
      ups <- ups[keep, ]
      if (nrow(ups)==0) {
         outnames <- c("sequence", "abundance", "forward", "reverse",
                       "nmatch", "nmismatch", "nindel", "prefer", "accept")
         ups <- data.frame(matrix(ncol = length(outnames), nrow = 0))
         names(ups) <- outnames
         if(verbose) {
           message("No paired-reads (in ZERO unique pairings) successfully merged out of ", nrow(pairdf), " pairings) input.")
         }
         return(ups)
      } else {
         Funqseq <- unname(as.character(dadaF[[i]]\$clustering\$sequence[ups\$forward]))
         Runqseq <- rc(unname(as.character(dadaR[[i]]\$clustering\$sequence[ups\$reverse])))
         if (justConcatenate == TRUE) {
            # Simply concatenate the sequences together
            ups\$sequence <- mapply(function(x,y) paste0(x,"NNNNNNNNNN", y),
                                  Funqseq, Runqseq, SIMPLIFY=FALSE);
            ups\$nmatch <- 0
            ups\$nmismatch <- 0
            ups\$nindel <- 0
            ups\$prefer <- NA
            ups\$accept <- TRUE
         } else {
            # Align forward and reverse reads.
            # Use unbanded N-W align to compare forward/reverse
            # Adjusting align params to prioritize zero-mismatch merges
            tmp <- getDadaOpt(c("MATCH", "MISMATCH", "GAP_PENALTY"))
            if(maxMismatch==0) {
             setDadaOpt(MATCH=1L, MISMATCH=-64L, GAP_PENALTY=-64L)
            } else {
             setDadaOpt(MATCH=1L, MISMATCH=-8L, GAP_PENALTY=-8L)
            }
            alvecs <- mapply(function(x,y) nwalign(x,y,band=-1,...), Funqseq, Runqseq, SIMPLIFY=FALSE)
            setDadaOpt(tmp)
            outs <- t(sapply(alvecs, function(x) C_eval_pair(x[1], x[2])))
            ups\$nmatch <- outs[,1]
            ups\$nmismatch <- outs[,2]
            ups\$nindel <- outs[,3]
            ups\$prefer <- 1 + (dadaR[[i]]\$clustering\$n0[ups\$reverse] > dadaF[[i]]\$clustering\$n0[ups\$forward])
            ups\$accept <- (ups\$nmatch >= minOverlap) & ((ups\$nmismatch + ups\$nindel) <= maxMismatch)
            # Make the sequence
            ups\$sequence <- mapply(C_pair_consensus, sapply(alvecs,`[`,1), sapply(alvecs,`[`,2), ups\$prefer, trimOverhang);
            # Additional param to indicate whether 1:forward or 2:reverse takes precedence
            # Must also strip out any indels in the return
            # This function is only used here.
         }

         # Add abundance and sequence to the output data.frame
         tab <- table(pairdf\$forward, pairdf\$reverse)
         ups\$abundance <- tab[cbind(ups\$forward, ups\$reverse)]
         if (rescueUnmerged == TRUE) {
            rescue <- which(!ups\$accept)
            ups\$sequence[rescue] <- mapply(function(x,y) paste0(x,"NNNNNNNNNN", y),
                                  Funqseq[rescue], Runqseq[rescue], SIMPLIFY=FALSE);
         } else {
            ups\$sequence[!ups\$accept] <- ""
         }
         # Add columns from forward/reverse clustering
         propagateCol <- propagateCol[propagateCol %in% colnames(dadaF[[i]]\$clustering)]
         for(col in propagateCol) {
           ups[,paste0("F.",col)] <- dadaF[[i]]\$clustering[ups\$forward,col]
           ups[,paste0("R.",col)] <- dadaR[[i]]\$clustering[ups\$reverse,col]
         }
         # Sort output by abundance and name
         ups <- ups[order(ups\$abundance, decreasing=TRUE),]
         rownames(ups) <- NULL
         if(verbose) {
            message(sum(ups\$abundance[ups\$accept]), " paired-reads (in ", sum(ups\$accept), " unique pairings) successfully merged out of ", sum(ups\$abundance), " (in ", nrow(ups), " pairings) input.")
         }
         if(!returnRejects) { ups <- ups[ups\$accept,] }

         if(any(duplicated(ups\$sequence))) {
            message("Duplicate sequences in merged output.")
         }
         return(ups)
       }
     })
     if(!is.null(names(dadaF))) names(rval) <- names(dadaF)
     if(length(rval) == 1) rval <- rval[[1]]

     return(rval)
   }

   # this is to ensure this acts as if in the dada2 package (so uses any functions definted within)
   environment(mergePairsRescue) <- asNamespace('dada2')

   # read in denoised reads for both
   ddFs <- readRDS("all.dd.R1.RDS")

   if (file.exists("all.dd.R2.RDS")) {
      # Note we only load these if we need to, since the dereps
      # will take a fair bit of memory
      
      # File parsing (these come from the process input channel)
      derep_files_r1 <- list.files('.', pattern="R1.derep.RDS", full.names = TRUE)
      derepsF <- lapply(derep_files_r1, readRDS)
      names(derepsF) <- sapply(derepsF, function(x) { x\$file })

      ddRs <- readRDS("all.dd.R2.RDS")
      
      # File parsing (these come from the process input channel)
      derep_files_r2 <- list.files('.', pattern="R2.derep.RDS", full.names = TRUE)
      derepsR <- lapply(derep_files_r2, readRDS)
      names(derepsR) <- sapply(derepsR, function(x) { x\$file })

      mergers <- if(rescuePairs) {
         mergePairsRescue(ddFs, derepsF, ddRs, derepsR,
          returnRejects = TRUE,
          minOverlap = ${params.min_overlap},
          maxMismatch = ${params.max_mismatch},
          trimOverhang = as.logical("${params.trim_overhang}"),
          justConcatenate = as.logical("${params.just_concatenate}"),
          rescueUnmerged=rescuePairs,
          verbose = TRUE
          ) 
         } else {
         mergePairs(ddFs, derepsF, ddRs, derepsR,
          returnRejects = TRUE,
          minOverlap = ${params.min_overlap},
          maxMismatch = ${params.max_mismatch},
          trimOverhang = as.logical("${params.trim_overhang}"),
          justConcatenate = as.logical("${params.just_concatenate}"),
          verbose = TRUE
          )
         }

      # TODO: make this a single item list with ID as the name, this is lost
      # further on
      saveRDS(mergers, "all.merged.RDS")

      mergers_summary <- as.data.frame(sapply(mergers, function(x) sum(getUniques(x %>% filter(accept)))))
      colnames(mergers_summary) <- c("dada2.pooled.merged")
      nms <- gsub(".R1.filtered.fastq.gz", "", rownames(mergers_summary))
      mergers_summary <- mergers_summary %>% 
         as_tibble() %>%
         mutate(SampleID = nms, .before = 1)
      write_csv(as_tibble(mergers_summary), "all_merged.pooled.csv")

      # go ahead and make seqtable
      seqtab <- makeSequenceTable(mergers)
   } else {
      # No merging, just make a seqtable off R1 only
      seqtab <- makeSequenceTable(ddFs)
   }

   saveRDS(seqtab, "seqtab.full.RDS")

   seqtab_stats <- rowSums(seqtab)
   nms <- gsub(".R1.filtered.fastq.gz", "", names(seqtab_stats))
   seqtab_stats <- as_tibble_col(seqtab_stats, column_name = "dada.pooled.seqtab.raw") %>%
      mutate(SampleID = nms, .before = 1)

   write_csv(seqtab_stats, "seqtab.original.pooled.${readmode}.csv")

   # this is an optional filtering step to remove *merged* sequences based on 
   # min/max length criteria
   if (${params.min_asv_len} > 0) {
      seqtab <- seqtab[,nchar(colnames(seqtab)) >= ${params.min_asv_len}]
   }

   if (${params.max_asv_len} > 0) {
      seqtab <- seqtab[,nchar(colnames(seqtab)) <= ${params.max_asv_len}]
   }
   saveRDS(seqtab, "seqtab.lengthfiltered.RDS")

   if (${params.min_asv_len} > 0 | ${params.max_asv_len} > 0) {
      seqtab_stats <- rowSums(seqtab)
      nms <- gsub(".R1.filtered.fastq.gz", "", names(seqtab_stats))
      seqtab_stats <- as_tibble_col(seqtab_stats, column_name = "dada.pooled.seqtab.lengthfiltered") %>%
         mutate(SampleID = nms, .before = 1)
      write_csv(seqtab_stats, "seqtab.${readmode}.lengthfiltered.csv")
   }
   """

   stub:
   def args = task.ext.args ?: ''
   """
   # add some real stuff here
   """
}
