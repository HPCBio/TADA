include { DADA2_LEARN_ERRORS                                          } from '../../modules/local/learnerrors'
include { DADA2_DEREP_SEQS                                            } from '../../modules/local/dada2derepseqs'
include { DADA2_POOLED_DENOISE                                        } from '../../subworkflows/local/dada2_pooled_denoise'
include { DADA2_PER_SAMPLE_DENOISE                                    } from '../../subworkflows/local/dada2_per_sample_denoise'

// TODO: experimental!!
include { DADA2_PER_SAMPLE_DENOISE as DADA2_PER_SAMPLE_DENOISE_ROUND1 } from '../../subworkflows/local/dada2_per_sample_denoise'
include { DADA2_PER_SAMPLE_DENOISE as DADA2_PER_SAMPLE_DENOISE_ROUND2 } from '../../subworkflows/local/dada2_per_sample_denoise'

workflow DADA2_DENOISE {

    take:
    ch_trimmed
 
    main:
    // topic channels
    ch_versions = Channel.empty()
    ch_readtracking = Channel.empty()

    ch_errs = Channel.empty()
    ch_dereps = Channel.empty()

    ch_inferred = Channel.empty()
    ch_filtered_seqtab = Channel.empty()
    ch_merged = Channel.empty()
    
    // START: DADA2-specific

    // Channel setup

    // We need to group data depending on which downstream steps are needed.  There
    // are two combinations possible

    // 1. The immediate downstream QC steps can use the meta info and the read pairs.
    //    Instead of doing handstands reusing the two channels above, we emit channels 
    //    with the reads paired if needed. ch_trimmed_parallel

    // 2. LearnErrors and the pooled denoising branch requires all R1 in one run and all 
    //    R2 in another, but the two groups can be processed in parallel.  So we set up
    //    the channels with this in mind. No sample ID info is really needed.
    //    For this 'batch' run, we use two channels combining the data and 
    //    include whether they are R1 or R1 (a 'readmode') to distinguish them. ch_trimmed_batch

    ch_trimmed_per_read = ch_trimmed
        .map { 
            [ 'R1', it[0].single_end ? it[1] : it[1][0] ]
        }
        .concat(
            ch_trimmed
                .filter { !it[0].single_end }
                .map {
                    [ 'R2', it[1][1] ]
                }
        )
        .groupTuple(sort: true)

    DADA2_LEARN_ERRORS(ch_trimmed_per_read) 
    ch_errs = DADA2_LEARN_ERRORS.out.error_models

    // deal with priors here, which are optional inputs
    for_priors = params.for_priors ? file(params.for_priors, checkIfExists: true) : file("${projectDir}/assets/dummy_file")
    rev_priors = params.rev_priors ? file(params.rev_priors, checkIfExists: true) : file("${projectDir}/assets/dummy_file")

    if (params.pool == "parallel" || params.pool == "parallel-pseudo") {
        // TODO: this can be removed completely
        DADA2_DEREP_SEQS(ch_trimmed)
        ch_dereps = DADA2_DEREP_SEQS.out.derep_rds
        per_sample_errs = ch_errs.map {it -> it[1]}.collect()
        if (params.pool == "parallel") {
            DADA2_PER_SAMPLE_DENOISE(
                ch_dereps,
                per_sample_errs,
                for_priors,
                rev_priors,
                "single-pass")

            ch_merged = DADA2_PER_SAMPLE_DENOISE.out.merged_seqs
            ch_filtered_seqtab = DADA2_PER_SAMPLE_DENOISE.out.filtered_seqtable
            ch_versions = ch_versions.mix(DADA2_PER_SAMPLE_DENOISE.out.versions)
            ch_readtracking = ch_readtracking.mix(DADA2_PER_SAMPLE_DENOISE.out.readtracking)
        } else {
            // For now we keep these separate since this method is *highly* 
            // experimental!!!!

            // Round 1, generate a new set of priors
            // Note this can also take an older set of prior data
            DADA2_PER_SAMPLE_DENOISE_ROUND1(
                ch_dereps,
                per_sample_errs,
                for_priors,
                rev_priors,
                "Round1")
            rnd1_for_priors = DADA2_PER_SAMPLE_DENOISE_ROUND1.out.for_priors
            rnd1_rev_priors = DADA2_PER_SAMPLE_DENOISE_ROUND1.out.rev_priors
            ch_readtracking = ch_readtracking.mix(DADA2_PER_SAMPLE_DENOISE_ROUND1.out
                    .inferred
                    .map { it[1] } 
                    .collect())
            ch_versions = ch_versions.mix(DADA2_PER_SAMPLE_DENOISE_ROUND1.out.versions)
            
            // Round 2, using priors from round 1 but same error models and dereps
            DADA2_PER_SAMPLE_DENOISE_ROUND2(
                ch_dereps,
                per_sample_errs,
                rnd1_for_priors,
                rnd1_rev_priors,
                "Round2")
            ch_merged = DADA2_PER_SAMPLE_DENOISE_ROUND2.out.merged_seqs
            ch_filtered_seqtab = DADA2_PER_SAMPLE_DENOISE_ROUND2.out.filtered_seqtable
            rnd2_for_priors = DADA2_PER_SAMPLE_DENOISE_ROUND2.out.for_priors
            rnd2_rev_priors = DADA2_PER_SAMPLE_DENOISE_ROUND2.out.rev_priors
            ch_versions = ch_versions.mix(DADA2_PER_SAMPLE_DENOISE_ROUND2.out.versions)
        }
    } else {
        // TODO: can we even use priors with 'true' or 'pseudo'?

        // this runs standard denoising using DADA2, which sequentially processes data
        // Currently this is the only way to run pooling

        // We also stash a copy of the full RDS with *all* derep seqs
        // to make sure these are consistent between the learnErrors step
        // and this step, which optionally pools them. For really large runs
        // this will use a ton of memory

        DADA2_POOLED_DENOISE(
            ch_errs, ch_trimmed_per_read
        )

        ch_merged = DADA2_POOLED_DENOISE.out.merged_seqs
        ch_filtered_seqtab = DADA2_POOLED_DENOISE.out.filtered_seqtable
        ch_versions = ch_versions.mix(DADA2_POOLED_DENOISE.out.versions)
        ch_readtracking = ch_readtracking.mix(
            DADA2_POOLED_DENOISE.out.readtracking
        )
    }

    emit:
    merged_seqs = ch_merged
    filtered_seqtable = ch_filtered_seqtab
    versions = ch_versions
    readtracking = ch_readtracking
}

