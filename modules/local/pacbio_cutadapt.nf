process PACBIO_CUTADAPT {
    tag "${meta.id}"

    container 'quay.io/biocontainers/cutadapt:5.0--py39hbcbf7aa_0'

    input:
    tuple val(meta), path(reads)
    val(for_primer)
    val(rev_primer_rc)

    output:
    tuple val(meta), path("${meta.id}.R1.filtered.fastq.gz"), optional: true, emit: trimmed
    path("${meta.id}.cutadapt.out"), emit: trimmed_report // to merging data
    path("${meta.id}.untrimmed.fastq.gz"), emit: cutadapt_untrimmed
    path("${meta.id}.cutadapt.json"), emit: cutadapt_json  // to MultiQC

    when:
    task.ext.when == null || task.ext.when

    script:
    maxN = params.maxN >=0 ? "--max-n ${params.maxN}" : ""
    maxEE = "--max-ee ${[params.maxEE_for,params.maxEE_rev].max()}"
    strictness = params.cutadapt_strict_match ? '-g' : '-a'
    min_len = params.min_read_len ? "-m ${params.min_read_len}" : "-m 50" 
    max_len = params.max_read_len != "Inf" ? "-M ${params.max_read_len}" : ""
    """
    cutadapt --rc \\
        --report=minimal \\
        --json=${meta.id}.cutadapt.json \\
        ${strictness} "${for_primer}...${rev_primer_rc}" \\
        -j ${task.cpus} ${min_len} ${max_len} ${maxEE} ${maxN} \\
        --untrimmed-output "${meta.id}.untrimmed.fastq.gz" \\
        -o "${meta.id}.R1.filtered.fastq.gz" \\
        ${reads} > "${meta.id}.cutadapt.out"

    if [ -n "\$(gunzip <${meta.id}.R1.filtered.fastq.gz | head -c 1 | tr '\\0\\n' __)" ]; then
        echo "Sequences present"
    else
        rm ${meta.id}.R1.filtered.fastq.gz
    fi
    """
}
