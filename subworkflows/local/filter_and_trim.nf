include { ILLUMINA_DADA2_FILTER_AND_TRIM   } from '../../modules/local/illumina_filterandtrim'
include { PACBIO_DADA2_FILTER_AND_TRIM     } from '../../modules/local/pacbio_filterandtrim'
include { CUTADAPT as SHORT_READ_CUTADAPT  } from '../../modules/nf-core/cutadapt'
include { CUTADAPT as LONG_READ_CUTADAPT   } from '../../modules/nf-core/cutadapt'
include { MERGE_TRIM_TABLES                } from '../../modules/local/mergetrimtables'

workflow FILTER_AND_TRIM {

    take:
    ch_input

    main:
    ch_versions = Channel.empty() 
    ch_reports = Channel.empty()
    ch_trimmed = Channel.empty()
    ch_trimmed_R1 = Channel.empty()
    ch_trimmed_R2 = Channel.empty()
    ch_multiqc_files = Channel.empty()

    for_primer_rc = params.for_primer ? reverse_complement(params.for_primer) : ""
    rev_primer_rc = params.rev_primer ? reverse_complement(params.rev_primer) : ""

    // Two modules/subworkflows for Illumina data:
    //       DADA2 trimming and filtering (PE and SE currently) - implemented
    //       cutadapt-based (primers + Ns) + vsearch (EE) - implemented
    // Two modules/subworkflows for PacBio:
    //       DADA2 filtering (filter) - NYI
    //       cutadapt (trim) - implemented

    // TODO: we don't have both trimmers implemented for platforms, so
    // we force any pacbio runs to be cutadapt for now
    def trimmer = params.platform == "pacbio" ? "cutadapt" : params.trimmer
    if (params.platform == "pacbio") {

        LONG_READ_CUTADAPT(
            ch_input
                .map { meta, reads -> 
                    [  
                    [ id:         meta.id, 
                      single_end: meta.single_end,
                      for:        params.for_primer, 
                      rev:        params.rev_primer,
                      for_rc:     for_primer_rc,
                      rev_rc:     rev_primer_rc],
                      reads
                    ]
                    }
        )

        // TODO: this could be modified/split into a `DADA2`-only step
        // PACBIO_DADA2_FILTER_AND_TRIM(
        //     PACBIO_CUTADAPT.out.cutadapt_trimmed
        // )
        ch_trimmed = PACBIO_CUTADAPT.out.trimmed
        ch_reports = PACBIO_CUTADAPT.out.trimmed_report.collect()
        ch_multiqc_files = ch_multiqc_files.mix(PACBIO_CUTADAPT.out.cutadapt_json)
    } else {
        // this handles both paired and single-end data
        if (trimmer == "dada2") {
            ILLUMINA_DADA2_FILTER_AND_TRIM(
                ch_input 
            )
            ch_trimmed = ILLUMINA_DADA2_FILTER_AND_TRIM.out.trimmed
            ch_reports = ILLUMINA_DADA2_FILTER_AND_TRIM.out.trimmed_report.collect()
        } else if (trimmer == "cutadapt") {

            // this currently requires passing in the primers via meta 
            // for each sample
            SHORT_READ_CUTADAPT(
                ch_input
                .map { meta, reads -> 
                    [  
                    [ id:         meta.id, 
                      single_end: meta.single_end,
                      for:        params.for_primer, 
                      rev:        params.rev_primer,
                      for_rc:     for_primer_rc,
                      rev_rc:     rev_primer_rc],
                      reads
                    ]
                    }
            )
            ch_trimmed = SHORT_READ_CUTADAPT.out.reads
            ch_reports = SHORT_READ_CUTADAPT.out.log.collect{it[1]}
            // ch_multiqc_files = ch_multiqc_files.mix(SHORT_READ_CUTADAPT.out.log.collect{it[1]})
            ch_versions = ch_versions.mix(SHORT_READ_CUTADAPT.out.versions)
        }
    }

    MERGE_TRIM_TABLES(
        ch_reports,
        trimmer
    )

    emit:
    trimmed_report = MERGE_TRIM_TABLES.out.trimmed_report // channel: [ RDS ]
    trimmed = ch_trimmed
    versions = ch_versions
    ch_multiqc_files
}

def reverse_complement(primer) {
    // returns the revcomp, handles IUPAC ambig codes
    // tr "[ATGCUNYRSWKMBDHV]" "[TACGANRYSWMKVHDB]"
    return primer.reverse().collect { 
        switch (it) {
            case 'A': return 'T'
            case 'T': return 'A'
            case 'G': return 'C'
            case 'C': return 'G'
            case 'U': return 'A'
            case 'N': return 'N'
            case 'Y': return 'R'
            case 'R': return 'Y'
            case 'S': return 'S'
            case 'W': return 'W'
            case 'K': return 'M'
            case 'M': return 'K'
            case 'B': return 'V'
            case 'D': return 'H'
            case 'H': return 'D'
            case 'V': return 'B'
            default: return it // handle invalid characters if needed
        }
    }.join('')
}

// NYI; meant to deal with cutadapt-like primer settings
// def clean_primers(primer) {
//     // returns a clean primer string, IUPAC codes 
//     // w/o any metadata or anchors (e.g. cutadapt)
// }

