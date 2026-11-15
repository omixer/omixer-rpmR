#' @details
#' [rpm()] turns KEGG KO profiles (with or without taxa, or HUMAnN KO tables) into module abundance and coverage,
#' with a bundled or own module database ([loadDB()]); [asDataFrame()] gives the result as a table.
#' [runShinyRpm()] starts a web interface.
#'
#' @references
#' omixerRpm was developed as part of GOmixer. If you use omixerRpm in your work please cite:
#' Darzi, et al. Towards biome-specific analysis of meta-omics data, The ISME journal, 2015.
#' <http://www.nature.com/articles/ismej2015188>
#'
#' In case you use the bundled GMMs database, please also cite Vieira-Silva, et al. Species-function relationships
#' shape ecological properties of the human gut microbiome, Nature Microbiology, 2016.
#' <http://www.nature.com/articles/nmicrobiol201688>
#'
#' @import methods
#' @importFrom utils read.table write.table
"_PACKAGE"
