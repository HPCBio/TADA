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
    def speciesRef = sp.name != "dummy_file" ? "--species_ref ${sp}" : ""
    """
    assign_taxa_species.R \\
        --seqtab ${st} \\
        --ref ${ref} \\
        ${speciesRef} \\
        --tax_batch ${params.tax_batch} \\
        --min_boot ${params.min_boot} \\
        --ncpus ${task.cpus}
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    """
}
