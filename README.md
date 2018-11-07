# omixer-rpmR
An R interface to [omixer-rpm](https://github.com/raeslab/omixer-rpm), the tool for metabolic module profiling of microbiome samples

#### Dependencies 
R and Java8

#### Installation
Download the latest release from [the release page](https://github.com/omixer/omixer-rpmR/releases), then install as follows after replacing x.y.z by the correct version 

<code>R CMD INSTALL omixeRpm_x.y.z.tar.gz</code>

#### Usage example
<pre>library(omixerRpm)
# read a functional profile matrix into R or create it inside R
dat &lt;- read.table("test/matrix.tsv", header=T, sep="\t")
# Run the module mapping on the loaded table.
mods &lt;- rpm(dat, minimum.coverage=0.3, annotation = 1)
# alternatively run the mapping without loading the table into R.
mods &lt;- rpm("test/matrix.tsv", minimum.coverage=0.3, annotation = 1)
# Load the default mapping database
db &lt;- loadDefaultDB()
# get the name of the first predicted module
getNames(db, mods@annotation[1,])
</pre>


#### Citing omixer-rpmR
omixer-rpmR was developed as part of GOmixer. If you use omixer-rpmR in your work please cite: 

Youssef Darzi, Gwen Falony, Sara Silva, Jeroen Raes. [Towards biome-specific analysis of meta-omics data](https://www.nature.com/articles/ismej2015188), The ISME journal, 2015

#### License
GNU General Public License v3.0. 
The bundled omixer-rpm.jar is licensed under an [Academic Non-commercial Software License Agreement](https://github.com/raeslab/omixer-rpm/blob/master/LICENSE)
