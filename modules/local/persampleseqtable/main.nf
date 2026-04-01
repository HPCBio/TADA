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
   per_sample_seqtable.R \\
       --readmode ${readmode} \\
       --stage ${stage} \\
       --min_asv_len ${params.min_asv_len} \\
       --max_asv_len ${params.max_asv_len}
   """
}
