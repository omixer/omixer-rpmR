# omixer-rpmR
An R interface to [omixer-rpm](https://github.com/raeslab/omixer-rpm), the tool for metabolic module profiling of microbiome samples

#### Dependencies 
R and Java 21 or newer (check with `java -version`). Docker users, please make sure Java8 is part of the R image.

#### Installation
Download the latest release from [the release page](https://github.com/omixer/omixer-rpmR/releases) and install it
after replacing x.y.z by the correct version:

<code>R CMD INSTALL omixer-rpmR-x.y.z.tar.gz</code>

Or install using latest source, from R:

<code>remotes::install_github("omixer/omixer-rpmR")</code>


#### Web interface (Shiny)
Upload a KO table, choose the database and the options of `rpm()`, then browse and download the module abundance and
coverage tables, and charts of them. The app needs packages that are not installed with omixer-rpmR:
<pre>
install.packages(c("shiny", "bslib", "DT", "ggplot2", "plotly", "r2d3"))
omixerRpm::runShinyRpm()
</pre>

Or with Docker, from this directory:
```bash
make docker
docker run --rm -p 3838:3838 omixer/shinyrpm:0.6.0
```
then open the browser at http://localhost:3838/rpm/

#### Usage

##### Mapping example
Download the example [matrix.tsv](https://github.com/omixer/omixer-rpmR/blob/main/tests/data/matrix.tsv) ([raw link](https://raw.githubusercontent.com/omixer/omixer-rpmR/main/tests/data/matrix.tsv)) from the test [data](https://github.com/omixer/omixer-rpmR/tree/main/tests/data).

<pre>library(omixerRpm)
# read a functional profile matrix into R or create it inside R. Please note that row.names should not be used while reading the matrix, and that check.names = FALSE keeps the sample names as they are.
dat &lt;- read.table("matrix.tsv", header=T, sep="\t", check.names=FALSE)
# Run the module mapping on the loaded table.
mods &lt;- rpm(dat, minimum.coverage=0.3, annotation = 1)

# alternatively run the mapping without loading the table into R.
mods &lt;- rpm("matrix.tsv", minimum.coverage=0.3, annotation = 1)

# require every subunit of a complex step (comma-separated KOs) instead of at least one
mods &lt;- rpm(dat, minimum.coverage=0.3, annotation = 1, complex.rule = "all")

# Load the default mapping database
db &lt;- loadDefaultDB()
# get the name of the first predicted module
getNames(db, mods@annotation[1,])

# get the abundance|coverage as a data.frame with module id and description
coverage <- asDataFrame(mods, "coverage")
</pre>

##### HUMAnN input
`annotation = "humann"` reads a [HUMAnN](https://github.com/biobakery/humann) (3, or 2) gene family table regrouped
to KEGG KOs, optionally renormalized and joined into one table:
<pre>
humann_regroup_table --input S1_genefamilies.tsv --groups uniref90_ko --output S1_ko.tsv
humann_renorm_table --input S1_ko.tsv --units cpm --output S1_ko_cpm.tsv
humann_join_tables --input tables/ --output ko.tsv --file_name ko_cpm
</pre>
<pre>
# modules per taxon of each sample, from the stratified rows (KO|taxon, HUMAnN's unclassified included)
mods &lt;- rpm("ko.tsv", annotation = "humann")
# modules per sample, from the community total rows (never added to their strata)
mods &lt;- rpm("ko.tsv", annotation = "humann", ignore.taxonomy = TRUE)
</pre>
A table without strata (`humann --remove-stratified-output`) gives one result per sample. Rows such as `UNMAPPED` and
`UNGROUPED` and KO names added by `humann_rename_table` are ignored, and sample names lose HUMAnN's `_Abundance`
suffix. Give the table as a file path: `rpm()` refuses a data.frame for HUMAnN input, because `read.table()` treats
the header line (it starts with `#`) as a comment and turns the first row of data into the header.


##### Using an alternative database, several options are available

1. load one of the bundled databases. Type listDB() to check the list of available databases
<pre>
db &lt;- loadDB("GBMs.v1.0")
</pre>

2. load an external database. Please refer to this [module.list](https://github.com/omixer/omixer-rpmR/blob/master/inst/extdata/GMMs.v1.07.txt) and [module.names](https://github.com/omixer/omixer-rpmR/blob/master/inst/extdata/GMMs.v1.07.names) for examples
<pre>
db &lt;- ModuleDB(directory = "/path/to/moduledb/", modules = "module.list", module.names.file="module.names")
</pre>

#### Bundled databases
1. Gut Brain Modules, [Valles-Colomer et al. 2019](https://www.nature.com/articles/s41564-018-0337-x), The neuroactive potential of the human gut microbiota in quality of life and depression, Nature Microbiology 2019.
2. Gut Metabolic Modules, [Vieira-Silva et al. 2016](https://www.nature.com/articles/nmicrobiol201688), Species-function relationships shape ecological properties of the human gut microbiome, Nature Microbiology 2016.

#### Citing omixer-rpmR
omixer-rpmR was developed as part of GOmixer. If you use omixer-rpmR in your work please cite: 

Youssef Darzi, Gwen Falony, Sara Silva, Jeroen Raes. [Towards biome-specific analysis of meta-omics data](https://www.nature.com/articles/ismej2015188), The ISME journal, 2015.

#### License
MIT (the R code of this package), see [LICENSE](LICENSE).
The bundled omixer-rpm.jar is licensed under an [Academic Non-commercial Software License Agreement](https://github.com/raeslab/omixer-rpm/blob/master/LICENSE)
