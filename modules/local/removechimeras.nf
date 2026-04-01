process DADA2_REMOVE_CHIMERAS {
    label 'process_medium'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path(st)

    output:
    path("seqtab.nonchim.RDS"), emit: nonchim_seqtable
    path("seqtab.nonchimera.csv"), emit: readtracking

    when:
    task.ext.when == null || task.ext.when

    script:
    def chimOpts = params.removeBimeraDenovo_options ? "--extra_opts '${params.removeBimeraDenovo_options}'" : ""
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix
    """
    remove_chimeras.R \\
        --seqtab ${st} \\
        --ncpus ${task.cpus} \\
        ${chimOpts}
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix
    """

    """
}
