FROM rocker/shiny:4.6.1

# libuv1t64: the fs package (bslib -> sass -> fs) is a binary linked against it
RUN apt-get update \
 && apt-get install -y --no-install-recommends openjdk-21-jre-headless libuv1t64 \
 && rm -rf /var/lib/apt/lists/*

RUN install2.r --error --skipinstalled shiny bslib DT ggplot2 plotly r2d3 \
 && rm -rf /tmp/Rtmp* /tmp/downloaded_packages

COPY . /app
WORKDIR /app

RUN R CMD build . && R CMD INSTALL omixerRpm_*.tar.gz && rm omixerRpm_*.tar.gz

# owned by the shiny user, so that the app can write its cache next to it
RUN cp -R inst/shiny /srv/shiny-server/rpm && chown -R shiny:shiny /srv/shiny-server/rpm
