#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.reads = 'data/*_{1,2}.fq.gz'
params.outdir = 'outputs/'
params.adapters = 'adapters.fa'
params.lg12 = 'LG12.fasta'
log.info """
      LIST OF PARAMETERS
================================
Reads            : ${params.reads}
Output-folder    : ${params.outdir}
Adapters         : ${params.adapters}
"""

// Create read channel
read_pairs_ch = Channel.fromFilePairs(params.reads, checkIfExists: true).map { sample, reads -> tuple(sample, reads.collect { it.toAbsolutePath() }) }
adapter_ch = Channel.fromPath(params.adapters)
ref_genome_ch = Channel.fromPath("LG12.fasta*").collect()

// Define fastqc process
process fastqc {
    publishDir "${params.outdir}/quality-control-${sample}/", mode: 'copy', overwrite: true

    input:
    tuple val(sample), path(reads)

    output:
    path("*_fastqc.{zip,html}")

    script:
    """
    fastqc ${reads}
    """
}

// Process trimmomatic
process trimmomatic {
    publishDir "${params.outdir}/trimmed-reads-${sample}/", mode: 'copy'

    input:
    tuple val(sample), path(reads)
    path adapters_file

    output:
    tuple val("${sample}"), path("${sample}*.trimmed.fq.gz"), emit: trimmed_reads
    tuple val("${sample}"), path("${sample}*.discarded.fq.gz"), emit: discarded_reads

    script:
    """
    trimmomatic PE -phred33 ${reads[0]} ${reads[1]} ${sample}_1.trimmed.fq.gz ${sample}_1.discarded.fq.gz ${sample}_2.trimmed.fq.gz ${sample}_2.discarded.fq.gz ILLUMINACLIP:${adapters_file}:2:30:10
    """
}

// Process bwa_mem2
process bwa_mem2 {
    publishDir "${params.outdir}/bwa_alignment/", mode: 'copy'
    
    input:
    tuple val(sample), path(trimmed_reads)
    path index_files

    output:
    tuple val(sample), path("${sample}.bam")

    script:
    """
    bwa-mem2 mem -t 4 LG12.fasta ${trimmed_reads[0]} ${trimmed_reads[1]} | samtools sort -@ 4 -o ${sample}.bam
    """
}


// Run the workflow
workflow {
    read_pairs_ch.view()
    fastqc(read_pairs_ch)
    trimmomatic(read_pairs_ch, adapter_ch)
    bwa_mem2(trimmomatic.out.trimmed_reads, ref_genome_ch)
}
