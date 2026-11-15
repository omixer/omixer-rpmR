OMIXER_RPM_JAR=https://github.com/raeslab/omixer-rpm/releases/download/v2.0.0-rc.1/omixer-rpm-2.0.0-rc.1-all.jar

build: clean
	R CMD build .

devbuild: clean
	wget -O inst/java/omixer-rpm.jar $(OMIXER_RPM_JAR)
	R CMD build .

clean:
	rm -f omixerRpm_*.tar.gz

install: build
	sudo R CMD INSTALL --byte-compile omixerRpm_*.tar.gz

# man/ and NAMESPACE, from the roxygen comments in R/ (needs roxygen2)
doc:
	Rscript -e 'roxygen2::roxygenise()'

# the tidyverse style for all R code (needs styler)
style:
	Rscript -e 'for (d in c("R", "tests", "inst/shiny")) styler::style_dir(d, recursive = TRUE, include_roxygen_examples = TRUE)'

# the tests of the installed package; R CMD check runs them too
testSuite:
	cd tests && Rscript runTests.R

docker:
	docker build -t omixer/shinyrpm:$(shell sed -n "s/^Version: //p" DESCRIPTION) .