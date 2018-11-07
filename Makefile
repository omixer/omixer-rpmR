OMIXER_RPM_JAR=https://github.com/raeslab/omixer-rpm/releases/download/1.0/omixer-rpm-1.0.jar

build: clean
	R CMD build .

devbuild: clean
	wget -O inst/java/omixer-rpm.jar $(OMIXER_RPM_JAR)
	R CMD build .

clean:
	rm -f omixerRpm_*.tar.gz TestMain.Rout

install: build
	sudo R CMD INSTALL --byte-compile omixerRpm_*.tar.gz

testSuite:
	R CMD BATCH test/TestMain.R
	grep "^Number of" TestMain.Rout
