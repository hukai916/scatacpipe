// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process SPLIT_FASTQ {
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir: 'split_fastq', publish_id:'') }
    container "hukai916/sinto_xenial:0.1"

    input:
    tuple val(sample_name), path(read1_fastq), path(read2_fastq), path(barcode_fastq)
    val sample_count

    output:
    val sample_name
    path "R1_*.fastq.gz", emit: read1_fastq
    path "R2_*.fastq.gz", emit: read2_fastq
    path "barcode_*.fastq.gz", emit: barcode_fastq

    // tuple val(sample_name), path("R1/*barcoded*"), path("R2/*barcoded*"), emit: reads_0
    // val sample_count
    // val chunk_count

    script:

    """
    zcat $read1_fastq | split --lines=2000000 --filter='gzip > \${FILE}.fastq.gz' - R1_${sample_name}_${sample_count}_
    zcat $read2_fastq | split --lines=2000000 --filter='gzip > \${FILE}.fastq.gz' - R2_${sample_name}_${sample_count}_
    zcat $barcode_fastq | split --lines=2000000 --filter='gzip > \${FILE}.fastq.gz' - barcode_${sample_name}_${sample_count}_

    """
}