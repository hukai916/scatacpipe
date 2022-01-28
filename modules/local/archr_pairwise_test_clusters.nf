// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process ARCHR_PAIRWISE_TEST_CLUSTERS {
    label 'process_low'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir: 'archr_pairwise_test_clusters', publish_id:'') }
    container "hukai916/r_sc:0.5"

    input:
    path archr_project
    val useGroups
    val bgdGroups
    val archr_thread

    output:
    path "Plots/*-Markers-MA-Volcano.pdf", emit: archr_markers_ma_volcano
    path "markerTest.rds", emit: archr_marker_test
    path "Plots/jpeg", emit: jpeg // to also publish the jpeg folder
    path "report_jpeg/archr_pairwise_test_clusters", emit: report

    script:

    """
    echo '
    library(ArchR)

    addArchRThreads(threads = $archr_thread)

    proj <- readRDS("$archr_project")

    markerTest <- getMarkerFeatures(
      ArchRProj = proj,
      useMatrix = "PeakMatrix",
      groupBy = "Clusters",
      useGroups = "$useGroups",
      bgdGroups = "$bgdGroups",
      $options.args
    )
    saveRDS(markerTest, file = "markerTest.rds")

    pma <- markerPlot(seMarker = markerTest, name = "$useGroups", cutOff = "$options.cutoff", plotAs = "MA")
    pv <- markerPlot(seMarker = markerTest, name = "$useGroups", cutOff = "$options.cutoff", plotAs = "Volcano")

    plotPDF(pma, pv, name = paste0("$useGroups", "-vs-", "$bgdGroups", "-Markers-MA-Volcano"), width = 5, height = 5, ArchRProj = NULL, addDOC = FALSE)

    ' > run.R

    Rscript run.R

    # Convert to jpeg:
    mkdir Plots/jpeg
    x=( \$(find ./Plots -name "*.pdf") )
    for item in "\${x[@]}"
    do
      {
        filename=\$(basename -- "\$item")
        filename="\${filename%.*}"
        pdftoppm -jpeg -r 300 \$item ./Plots/jpeg/\$filename
        convert -append ./Plots/jpeg/\${filename}* ./Plots/jpeg/\${filename}.jpg
        rm ./Plots/jpeg/\${filename}-*.jpg
      } || {
        echo "Pdf to jpeg failed!" > bash.log
      }
    done

    # For reporting:
    mkdir -p report_jpeg/archr_pairwise_test_clusters
    cp -r Plots/jpeg report_jpeg/archr_pairwise_test_clusters

    """
}
