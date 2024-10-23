// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process MULTIQC {
    label 'process_low'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir: 'multiqc', publish_id:'') }
    container "hukai916/miniconda3_v24.7_amd64_bio:0.1"

    input:
    path res_files

    output:
    path "*.html", emit: html
    path res_files, emit: res_files

    script:

    """
    multiqc . --config *.yaml

    """
}
