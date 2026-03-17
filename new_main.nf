#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Parameters
params.reads = 'data/*_{1,2}.fq.gz'
params.outdir = 'outputs/'
params.adapters = 'adapters.fa'
params.lg12 = 'LG12.fasta'

// Create read channel
read_pairs_ch = Channel.fromFilePairs(params.reads, checkIfExists: true).map { sample, reads -> tuple(sample, reads.collect { it.toAb
solutePath() }) }
adapter_ch = Channel.fromPath(params.adapters)
ref_genome_ch = Channel.fromPath("LG12.fasta*").collect()

// Include Modules
include { fastqc } from './modules/fastqc'
include { trimmomatic } from './modules/trimmomatic'
include { bwa_mem2 } from './modules/bwa_mem2'

// Run the workflow
workflow {
    read_pairs_ch.view()
    fastqc(read_pairs_ch)
    trimmomatic(read_pairs_ch, adapter_ch)
    bwa_mem2(trimmomatic.out.trimmed_reads, ref_genome_ch)
}
