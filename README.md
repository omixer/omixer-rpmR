# omixer-rpmR
An R interface to [omixer-rpm](https://github.com/raeslab/omixer-rpm), the tool for metabolic module profiling of
microbiome samples.

## Dependencies
R and Java 21 or newer (check with `java -version`). `rpm()` uses the Java in `JAVA_HOME` when it is set, otherwise
`java` from the `PATH`.

## Installation
A release from [the release page](https://github.com/omixer/omixer-rpmR/releases):
```bash
R CMD INSTALL omixerRpm_x.y.z.tar.gz
```
Or the latest source, from R:
```r
remotes::install_github("omixer/omixer-rpmR")
```

## Web interface
Upload a KO table, run `rpm()` with the chosen options, then browse, chart and download the results. The app needs
packages that are not installed with omixerRpm:
```r
install.packages(c("shiny", "bslib", "DT", "ggplot2", "plotly", "r2d3"))
omixerRpm::runShinyRpm()
```
Or with Docker, from this directory, then open http://localhost:3838/rpm/:
```bash
make docker
docker run --rm -p 3838:3838 omixer/shinyrpm:0.7.1
```

## Usage
With the example [matrix.tsv](https://raw.githubusercontent.com/omixer/omixer-rpmR/main/tests/data/matrix.tsv):
```r
library(omixerRpm)
# check.names = FALSE keeps the sample names as they are
dat <- read.table("matrix.tsv", header = TRUE, sep = "\t", check.names = FALSE)
mods <- rpm(dat, minimum.coverage = 0.3, annotation = 1)
# or from the file
mods <- rpm("matrix.tsv", minimum.coverage = 0.3, annotation = 1)
# a complex step (comma-separated KOs) needs every subunit instead of one
mods <- rpm(dat, minimum.coverage = 0.3, annotation = 1, complex.rule = "all")

# module names
getNames(loadDefaultDB(), mods@annotation$Module)

# the results as data.frames with the module descriptions
abundance <- asDataFrame(mods, "abundance")
coverage <- asDataFrame(mods, "coverage")
# both in one table: one row per sample and reported module
merged <- asDataFrame(mods, "merged")
```

### HUMAnN input
`annotation = "humann"` reads a [HUMAnN](https://github.com/biobakery/humann) 3 (or 2) gene family table regrouped
to KEGG KOs, optionally renormalized and joined:
```bash
humann_regroup_table --input S1_genefamilies.tsv --groups uniref90_ko --output S1_ko.tsv
humann_renorm_table --input S1_ko.tsv --units cpm --output S1_ko_cpm.tsv
humann_join_tables --input tables/ --output ko.tsv --file_name ko_cpm
```
```r
# per taxon of each sample, from the stratified rows (KO|taxon)
mods <- rpm("ko.tsv", annotation = "humann")
# per sample, from the community totals
mods <- rpm("ko.tsv", annotation = "humann", ignore.taxonomy = TRUE)
```
Give the file path, not a data.frame: `read.table()` drops HUMAnN's header, which starts with `#`. Special rows
(`UNMAPPED`, `UNGROUPED`) are ignored, and sample names lose the `_Abundance` suffix.

### Other databases
```r
listDB()                  # the bundled databases
db <- loadDB("GBMs.v1.0")
# your own, in the format of the bundled GMMs.v1.07.txt and GMMs.v1.07.names (inst/extdata)
db <- ModuleDB(directory = "/path/to/moduledb/", modules = "module.list", module.names.file = "module.names")
mods <- rpm(dat, module.db = db)
```

## Bundled databases
1. Gut Brain Modules: Valles-Colomer et al., [The neuroactive potential of the human gut microbiota in quality of life
   and depression](https://www.nature.com/articles/s41564-018-0337-x), Nature Microbiology 2019.
2. Gut Metabolic Modules: Vieira-Silva et al., [Species-function relationships shape ecological properties of the
   human gut microbiome](https://www.nature.com/articles/nmicrobiol201688), Nature Microbiology 2016.

## Citing
omixerRpm was developed as part of GOmixer. Please cite:
Youssef Darzi, Gwen Falony, Sara Silva, Jeroen Raes. [Towards biome-specific analysis of meta-omics
data](https://www.nature.com/articles/ismej2015188), The ISME Journal, 2015.

## License
MIT for the R code ([LICENSE](LICENSE)). The bundled omixer-rpm.jar is under an [Academic Non-commercial Software
License Agreement](https://github.com/raeslab/omixer-rpm/blob/master/LICENSE).
