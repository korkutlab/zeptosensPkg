FROM rocker/binder:3.6.3

ARG NB_USER
ARG NB_UID

USER root
COPY . ${HOME}
RUN pwd
RUN ls -la
RUN ls -la .binder 

#RUN R -e 'source("~/.binder/installPackages.R"); installPackages("~/.binder/r-requirements.dcf")'
#RUN R -e 'devtools::install_github("korkutlab/targetscore", subdir="targetscore")'

RUN R -e 'devtools::install_github("cmap/morpheus.R", dependencies=TRUE, upgrade=FALSE)'
RUN R -e 'devtools::install("targetscore", quick=TRUE, dependencies=TRUE, upgrade=FALSE)'

RUN chown -R ${NB_USER} ${HOME}

USER ${NB_USER}
