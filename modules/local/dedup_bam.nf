// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process DEDUP_BAM {
    label 'process_high'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir: 'dedup_bam', publish_id:'') }
    container "hukai916/sinto_kai:0.2"

    input:
    val sample_name
    path bam

    output:
    val sample_name, emit: sample_name
    path "*.dedup.bam", emit: bam

    script:

    """
    # Deduplicate bam file with remove_duplicate.py:
    remove_duplicate.py --inbam $bam --outdir ./ --outbam ${sample_name}.dedup.bam --nproc $task.cpus

    """

}
