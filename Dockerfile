FROM rocker/shiny:4.2.2

RUN apt-get update \
 && apt-get install -y --no-install-recommends default-jdk \
 && rm -rf /var/lib/apt/lists/*

RUN R -e 'install.packages(c("DT", "shinymaterial"), repos="http://cran.us.r-project.org",dependencies=TRUE, verbose=T, quiet=T, clean=T)' \
 && rm -rf /tmp/Rtmp*

COPY . /app
WORKDIR /app

RUN make build install

RUN cp -R shiny/ /srv/shiny-server/sample-apps/rpm

