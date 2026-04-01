process DECIPHER {
    label 'process_medium'

    container "ghcr.io/hpcbio/tada:docker-DADA-1.36"

    input:
    path(seqs)

    output:
    path("asvs.aligned.fna"), optional: true, emit: alignment

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    decipher_align.R \\
        --seqs ${seqs} \\
        --ncpus ${task.cpus}
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    """
}
