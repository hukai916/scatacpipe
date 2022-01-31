// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process ARCHR_FOOTPRINTING_CLUSTERS {
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir: 'archr_footprinting_clusters', publish_id:'') }
    container "hukai916/r_sc:0.5"

    input:
    path archr_project
    val archr_thread

    output:
    path "save_archr_project/Plots/jpeg", emit: jpeg // to also publish the jpeg folder
    path "report_jpeg/archr_footprinting_clusters", emit: report

    script:

    """
    echo '
    library(ArchR)

    addArchRThreads(threads = $archr_thread)

    proj <- readRDS("$archr_project", refhook = NULL)

    # Footprinting of motif:
    motifPositions <- getPositions(proj)

    if ("$options.motifs" == "default") {
      plotVarDev <- getVarDeviations(proj, name = "MotifMatrix", plot = TRUE)
      VarDev     <- getVarDeviations(proj, name = "MotifMatrix", plot = FALSE)
      motifs     <- VarDev\$name[1:min(10, length(VarDev\$name))]
    } else {
      motifs <- str_trim(str_split("$options.motifs", ",")[[1]], side = "both")
    }
    markerMotifs <- unlist(lapply(motifs, function(x) grep(x, names(motifPositions), value = TRUE)))

    seFoot <- getFootprints(
                ArchRProj = proj,
                positions = motifPositions[markerMotifs],
                groupBy   = "Clusters"
              )
    plotName <- paste0("Footprints", "-", "$options.norm_method", "-Bias")
    out <- tryCatch(
      expr = {
        plotFootprints(
          seFoot      = seFoot,
          ArchRProj   = proj,
          normMethod  = "$options.norm_method",
          plotName    = plotName,
          $options.args
        )
      },
      error = function(e) {
        return("Footprint plotting failed.")
      }
    )

    # Footprinting of TSS (custom) Features
    seTSS <- getFootprints(
              ArchRProj = proj,
              positions = GRangesList(TSS = getTSS(proj)),
              groupBy   = "Clusters",
              flank     = $options.tss_flank
             )
    out <- tryCatch(
      expr = {
        plotFootprints(
          seFoot      = seTSS,
          ArchRProj   = proj,
          normMethod  = "$options.tss_norm_method",
          plotName    = paste0("TSS-", "$options.tss_norm_method", "-Normalization"),
          addDOC      = FALSE,
          flank       = $options.tss_flank,
          flankNorm   = $options.flank_norm
          )
      },
      error = function(e) {
        return("Footprint plotting failed.")
      }
    )

    ' > run.R

    Rscript run.R

    # Convert to jpeg:
    rm -rf save_archr_project/Plots/jpeg
    mkdir -p save_archr_project/Plots/jpeg
    x=( \$(find ./save_archr_project/Plots -name "*.pdf") )
    for item in \${x[@]+"\${x[@]}"}
    do
      {
        filename=\$(basename -- "\$item")
        filename="\${filename%.*}"
        pdftoppm -jpeg -r 300 \$item ./save_archr_project/Plots/jpeg/\$filename
        convert -append ./save_archr_project/Plots/jpeg/\${filename}* ./save_archr_project/Plots/jpeg/\${filename}.jpg
        rm ./save_archr_project/Plots/jpeg/\${filename}-*.jpg
      } || {
        echo "Pdf to jpeg failed!" > bash.log
      }
    done

    # For reporting:
    mkdir -p report_jpeg/archr_footprinting_clusters
    cp -r save_archr_project/Plots/jpeg report_jpeg/archr_footprinting_clusters

    """
}
