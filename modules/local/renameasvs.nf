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
    rename_asvs.R \\
        --seqtab ${st} \\
        --raw_seqtab ${rawst} \\
        --id_type ${params.id_type}
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    """
}
