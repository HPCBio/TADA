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
   dada2_pooled_seqtable.R \\
       --readmode ${readmode} \\
       --rescue_unmerged ${params.rescue_unmerged} \\
       --min_overlap ${params.min_overlap} \\
       --max_mismatch ${params.max_mismatch} \\
       --trim_overhang ${params.trim_overhang} \\
       --just_concatenate ${params.just_concatenate} \\
       --min_asv_len ${params.min_asv_len} \\
       --max_asv_len ${params.max_asv_len}
   """

   stub:
   def args = task.ext.args ?: ''
   """
   # add some real stuff here
   """
}
