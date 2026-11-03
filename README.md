# omixer-rpmR
An R interface to [omixer-rpm](https://github.com/raeslab/omixer-rpm), the tool for metabolic module profiling of microbiome samples

#### Dependencies 
R and Java 21 or newer (Docker users, please make sure Java 21 is part of the R image). The bundled omixer-rpm is
version 2.0.0-rc.1, a release candidate: same results as 1.2.1 apart from the bug fixes in its
[changelog](https://github.com/raeslab/omixer-rpm/blob/master/CHANGELOG.md), and new support for HUMAnN tables.

#### Installation
##### Binaries for Linux only (built and tested on Ubuntu 24.04 LTS with R 4.3.3) 
Download the latest binary (omixeRpm_x.y.z.tar.gz) from [the release page](https://github.com/omixer/omixer-rpmR/releases), then install it as 
follows after replacing x.y.z by the correct version 

<code>R CMD INSTALL omixeRpm_x.y.z.tar.gz</code>

##### From source
Download the latest source from [the release page](https://github.com/omixer/omixer-rpmR/releases), then install it as follows after replacing x.y.z by the correct version 

<code>R CMD INSTALL omixer-rpmR-x.y.z.tar.gz</code>

##### Docker Shiny [experimental]
Start the docker container 
```bash
docker run --rm -ti -p 3838:3838 -v $PWD:/workspace omixer/shinyrpm:0.1
```

then  open the browser at http://localhost:3838/sample-apps/rpm/

#### Usage

##### Mapping example
Download the example [matrix.tsv](https://github.com/omixer/omixer-rpmR/blob/master/test/matrix.tsv) ([raw link](https://raw.githubusercontent.com/omixer/omixer-rpmR/master/test/matrix.tsv)) form the test [directory](https://github.com/omixer/omixer-rpmR/blob/master/test).

<pre>library(omixerRpm)
# read a functional profile matrix into R or create it inside R. Please note that row.names should not be used while reading the matrix. 
dat &lt;- read.table("matrix.tsv", header=T, sep="\t")
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
