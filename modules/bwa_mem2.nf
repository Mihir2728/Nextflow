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
