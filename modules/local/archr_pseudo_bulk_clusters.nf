// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process ARCHR_PSEUDO_BULK_CLUSTERS {
    label 'process_low'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir: 'archr_pseudo_bulk_clusters', publish_id:'') }
    container "hukai916/r_sc:0.5"

    input:
    path archr_project
    path user_rlib
    val archr_thread

    output:
    path "archr_project.rds", emit: archr_project
    path "save_archr_project", emit: archr_dir

    script:

    """
    echo '
    library(ArchR)
    .libPaths("user_rlib") # for user installed packages

    addArchRThreads(threads = $archr_thread)

    proj  <- readRDS("$archr_project", refhook = NULL)

    clusters <- c("Clusters_Seurat_IterativeLSI", "Clusters_Scran_IterativeLSI", "Clusters_Seurat_Harmony", "Clusters_Scran_Harmony", "Clusters2_Seurat_IterativeLSI", "Clusters2_Scran_IterativeLSI", "Clusters2_Seurat_Harmony", "Clusters2_Scran_Harmony")
    for (cluster in clusters) {
      tryCatch({
        proj2 <- addGroupCoverages(ArchRProj = proj, groupBy = "Clusters", force = TRUE)
      },
        error=function(e) {
          message(paste0("Skipping adding pseudo-bulk for ", cluster, "!"))
        }
      )
    }

    saveRDS(proj2, file = "archr_project.rds")

    ' > run.R

    Rscript run.R

    """
}
