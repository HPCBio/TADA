/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { DADA2_READMAP2ASV      } from '../modules/local/readmap2asv'

include { PRE_QC                 } from '../subworkflows/local/pre_qc'
include { FILTER_AND_TRIM        } from '../subworkflows/local/filter_and_trim'
include { DADA2_DENOISE          } from '../subworkflows/local/dada2_denoise'
include { CHIMERA_REMOVAL        } from '../subworkflows/local/chimera_removal'
include { TAXONOMY               } from '../subworkflows/local/taxonomy'
include { PHYLOGENY              } from '../subworkflows/local/phylogeny'
include { QUALITY_CONTROL        } from '../subworkflows/local/qualitycontrol'
include { GENERATE_OUTPUT        } from '../subworkflows/local/generate_output'
include { MMSEQS_FILTER          } from '../subworkflows/local/mmseqs_profile_filter'

include { paramsSummaryMap       } from 'plugin/nf-validation'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_tada_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow TADA {

    take:
    ch_samplesheet // channel: [val(meta), path(reads)]

    main:
    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()
    ch_readtracking = Channel.empty()

    // Make sure this is used throughout the workflow instead of params.platform
    def platform = params.platform.toLowerCase()

    if (!(["illumina","pacbio"].contains(platform))) {
        exit 1, "Only supported platforms (--platform argument) are currently 'pacbio' or 'illumina'"
    }

    if (params.learnerrors_function == "makeBinnedQualErrfun" && params.learnerrors_quality_bins == "") {
        exit 1, "Using makeBinnedQualErrfun requires explicitly setting quality_bins"
    }

    // Make sure the older quality_binning setting and the newer selection for error model function don't collide
    if (params.quality_binning && params.learnerrors_function == "makeBinnedQualErrfun") {
            exit 1, "${params.learnerrors_function} is selected with standard quality bin correction turned on!"
    }

    // TODO: implement any alternative inputs?
    
    // TODO: implement seqtable input?
    // // ${deity} there has to be a better way to check this!
    // if ( (params.seqTables && params.reads) || 
    //      (params.input  && params.reads) || 
    //      (params.seqTables && params.input)) {
    //     exit 1, "Only one of --reads, --input, or --seqTables is allowed!"
    // }

    // TODO: rethink this step and what the expected inputs mean
    // if ( params.trimming && (!(params.fwd_adaptor) || !(params.rev_adapter))) ) {
    //     log.info "Both --fwdprimer and --revprimer should be set unless skipping all trimming steps.\n" 
    //     log.info "[These options will become requirements in future releases]"
    // } else { 
    //     // this is a check if the primers are supplied but trimming is also set, which is almost certainly a mistake
    //     if ( params.trim_for != 0 || params.trim_rev != 0 ) {
    //         log.info "trim_for and/or trim_rev are set along with one or more primers (fwd_adapter/rev_adapter).\n" 
    //         log.info "This will trim additional bases *in addition to* the supplied primers!"
    //     }
    // }

    // if (params.aligner == 'infernal' && params.infernalCM == false){
    //     exit 1, "Must set covariance model using --infernalCM when using Infernal"
    // }

    if (!(['simple','md5'].contains(params.id_type))) {
        exit 1, "--id_type can currently only be set to 'simple' or 'md5', got ${params.id_type}"
    }

    if (!(['mmseqs','none'].contains(params.search_filter))) {
        exit 1, "--search_filter can currently only be set to 'none' or 'mmseqs', got ${params.id_type}"
    }

    PRE_QC(
        ch_samplesheet,
        params.skip_FASTQC,
        params.skip_dadaQC,
        params.skip_merging_check,
        params.skip_ee_check
    )

    ch_multiqc_files = ch_multiqc_files.mix(PRE_QC.out.zip.collect{it[1]})
    ch_versions = ch_versions.mix(PRE_QC.out.versions)
    
    ch_trimmed = ch_samplesheet

    if (params.preqc_only) {
        ch_trimmed = Channel.empty()
    } else if (!params.skip_trimming) {
        FILTER_AND_TRIM (
            ch_samplesheet
        )
        ch_multiqc_files = ch_multiqc_files.mix(FILTER_AND_TRIM.out.ch_multiqc_files)
        ch_readtracking = ch_readtracking.mix(FILTER_AND_TRIM.out.trimmed_report)

        ch_trimmed = FILTER_AND_TRIM.out.trimmed 
    }

    // Most of the DADA2-specific denoising steps are now in subworkflows, 
    // so now possible we can combine them into one parent DADA2-specific
    // subworkflow should we want to adapt alternative protocols.

    DADA2_DENOISE(
        ch_trimmed
    )

    ch_readtracking = ch_readtracking.mix(
        DADA2_DENOISE.out.readtracking
    )

    CHIMERA_REMOVAL(
        DADA2_DENOISE.out.filtered_seqtable
    )

    ch_filtered_readmap_rds = CHIMERA_REMOVAL.out.readmap
    ch_filtered_seqtab_rds = CHIMERA_REMOVAL.out.seqtable_renamed
    ch_filtered_asvs = CHIMERA_REMOVAL.out.nonchimeric_asvs

    ch_readtracking = ch_readtracking.mix(CHIMERA_REMOVAL.out.readtracking)

    // Currently implementing only MMSeqs search filtering
    if (params.search_filter == "mmseqs") {
        // TODO: needs a sanity check
        // TODO: this should also be a general filter subworkflow 
        // (not just mmseqs)
        // TODO: note that readmap + ASVs are redundant here
        MMSEQS_FILTER(
            ch_filtered_seqtab_rds,
            ch_filtered_asvs,
            ch_filtered_readmap_rds
        )
        ch_filtered_asvs= MMSEQS_FILTER.out.ch_filtered_asvs
        ch_filtered_seqtab_rds  = MMSEQS_FILTER.out.ch_filtered_seqtab
        ch_filtered_readmap_rds = MMSEQS_FILTER.out.ch_filtered_readmap
        ch_readtracking = ch_readtracking.mix(ch_filtered_seqtab_rds)
    }

    // Subworkflows-Taxonomic assignment (optional)
    ch_taxtab = Channel.empty()
    ch_taxtab_rds = Channel.empty()
    ch_metrics_rds =  Channel.empty()

    if (params.reference) {
        ref_file = file(params.reference, checkIfExists: true)
        species_file = params.species ? file(params.species, checkIfExists: true) : file("${projectDir}/assets/dummy_file")

        // TODO: add alternative callers:
        //      DECIPHER, USEARCH/VSEARCH, BLAST
        // TODO: because there is some inconsistency with input formats between tools, 
        //      there is some redundancy here. Could be rectified somewhat, e.g. using 
        //      a FASTA instead of the readmap.
        TAXONOMY(
            ch_filtered_asvs,
            ch_filtered_readmap_rds,
            ref_file,
            species_file,
            ch_filtered_seqtab_rds
        )
        ch_taxtab_rds = TAXONOMY.out.ch_taxtab_rds
        ch_metrics_rds = TAXONOMY.out.ch_taxmetrics_rds
        ch_filtered_seqtab_rds = TAXONOMY.out.ch_seqtab_rds
        ch_filtered_readmap_rds = TAXONOMY.out.ch_readmap_rds
        ch_readtracking = ch_readtracking.mix(TAXONOMY.out.readtracking)
    }
    
    // For now, we need to convert the readmap back to ASVs
    // here. But we could use the readmap in the subworkflows
    // where an ASV FASTA input is needed. May defer this when
    // we introduce an alternative denoising workflow 
    // (USEARCH/VSEARCH)
    
    DADA2_READMAP2ASV(ch_filtered_readmap_rds)
    ch_filtered_asvs = DADA2_READMAP2ASV.out.asvs

    PHYLOGENY(ch_filtered_asvs)

    // Post-QC, TODO needs some checking 
    QUALITY_CONTROL(
        ch_readtracking,
        // DADA2_DENOISE.out.merged_seqs,
        ch_filtered_seqtab_rds,
        ch_filtered_asvs
    )

    GENERATE_OUTPUT(
        ch_filtered_seqtab_rds,
        ch_taxtab_rds,
        ch_metrics_rds,
        ch_filtered_asvs,
        PHYLOGENY.out.ch_alignment,
        PHYLOGENY.out.ch_unrooted_tree,
        PHYLOGENY.out.ch_rooted_tree
    )

    ch_versions = ch_versions.mix(GENERATE_OUTPUT.out.versions)

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(storeDir: "${params.outdir}/pipeline_info", name: 'nf_core_pipeline_software_mqc_versions.yml', sort: true, newLine: true)
        .set { ch_collated_versions }

    //
    // MODULE: MultiQC
    //
    ch_multiqc_config                     = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config              = params.multiqc_config ? Channel.fromPath(params.multiqc_config, checkIfExists: true) : Channel.empty()
    ch_multiqc_logo                       = params.multiqc_logo ? Channel.fromPath(params.multiqc_logo, checkIfExists: true) : Channel.empty()
    summary_params                        = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary                   = Channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(methodsDescriptionText(ch_multiqc_custom_methods_description))
    ch_multiqc_files                      = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files                      = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files                      = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml', sort: false))

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        []
    )

    emit:
    multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

