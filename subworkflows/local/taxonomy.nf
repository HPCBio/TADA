include { DADA2_ASSIGN_TAXA_SPECIES    } from '../../modules/local/assigntaxaspecies'
include { DADA2_TAXTABLE2TEXT          } from '../../modules/local/taxtable2txt'
include { DADA2_TAXFILTER              } from '../../modules/local/dada2taxfilter'
include { QIIME2_TAXONOMY_CLASSIFIER   } from '../../subworkflows/local/qiime_assign_taxonomy'
// include { DADA2_TAXONOMY_CLASSIFIER    } from '../../subworkflows/local/dada2_assign_taxonomy'

workflow TAXONOMY {
    take:
    asv_fasta
    readmap      // TODO: redundant, should be modified to use simple FASTA
    ref_file     // General use
    species_file // DADA2-specific
    seqtab       // RDS (TODO: should make this CSV or TSV)

    main:
    ch_versions = Channel.empty()
    ch_taxtab_rds = Channel.empty()
    ch_taxmetrics_rds =  Channel.empty()
    ch_readtracking = Channel.empty()

    ch_readmap_rds = readmap
    ch_seqtab_rds =  seqtab

    // TODO: 
    // make these both subworkflows, then filter and 
    // generate the outputs right from these 
    // (move from 'generate_outputs')

    if (params.tax_assignment_method == 'rdp') {
        DADA2_TAXONOMY_CLASSIFIER(
            ch_readmap_rds,
            ref_file,
            species_file
        )

        ch_taxtab_rds = DADA2_ASSIGN_TAXA_SPECIES.out.taxtab_rds
        ch_taxmetrics_rds =  DADA2_ASSIGN_TAXA_SPECIES.out.metrics_rds
    } else if (params.tax_assignment_method == 'qiime2') {
        QIIME2_TAXONOMY_CLASSIFIER(
            asv_fasta,
            ref_file
        )

        ch_taxtab_rds = QIIME2_TAXONOMY_CLASSIFIER.out.taxtab_rds
        ch_taxmetrics_rds =  QIIME2_TAXONOMY_CLASSIFIER.out.metrics_rds
    } else {
        exit 1, "${params.tax_assignment_method} not yet supported!"
    }

    if (params.tax_filter) {
        // TODO: we should save the pre-filtered data here? This may require
        //       allowing for a suffix indicating this

        // TODO: we should add a QIIME2-specific way to filter here.
        //       However, note the current QIIME2 ranks are built into
        //       the names, so we may want to allow for 'p__'-like 
        //       rank-filtering.
        //       See: https://docs.qiime2.org/2024.10/tutorials/filtering/

        // if (params.tax_assignment_method == 'qiime2') {
        //     QIIME2_TAXFILTER(
                
        //     )

        //     ch_taxtab_rds = QIIME2_TAXONOMY_CLASSIFIER.out.taxtab_rds
        //     ch_taxmetrics_rds =  QIIME2_TAXONOMY_CLASSIFIER.out.metrics_rds
        // } else {

        DADA2_TAXFILTER(
            ch_readmap_rds,
            ch_seqtab_rds,
            ch_taxtab_rds,
            ch_taxmetrics_rds
        )
        ch_readmap_rds = DADA2_TAXFILTER.out.readmap_tax_filtered_rds
        ch_seqtab_rds = DADA2_TAXFILTER.out.seqtab_tax_filtered_rds
        ch_taxtab_rds = DADA2_TAXFILTER.out.taxtab_tax_filtered_rds
        ch_taxmetrics_rds = DADA2_TAXFILTER.out.taxmetrics_tax_filtered_rds
        ch_readtracking = ch_readtracking.mix(DADA2_TAXFILTER.out.readtracking)

        // }
    } 

    emit:
    ch_taxtab_rds = ch_taxtab_rds
    ch_taxmetrics_rds = ch_taxmetrics_rds
    ch_readmap_rds = ch_readmap_rds
    ch_seqtab_rds = ch_seqtab_rds
    readtracking = ch_readtracking
    versions = ch_versions                        // channel: [ versions.yml ]
}
