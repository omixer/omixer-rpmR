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

# the tests of the installed package; R CMD check runs them too
testSuite:
	cd tests && Rscript runTests.R

docker:
	docker build -t omixer/shinyrpm:$(shell sed -n "s/^Version: //p" DESCRIPTION) .