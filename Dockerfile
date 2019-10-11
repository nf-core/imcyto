FROM nfcore/base:1.7
LABEL authors="Harshil Patel" \
      description="Docker image containing majority of requirements for nf-core/imcyto pipeline"

## THIS DOCKER FILE ISNT REQUIRED FOR PIPELINE
## ALL DOCKER CONTAINERS ARE CURRENTLY OBTAINED FROM EXTERNAL SOURCES
## WAITING FOR LINT TESTS TO BE UPDATED BEFORE DELETING IT

COPY environment.yml /
RUN conda env create -f /environment.yml && conda clean -a
ENV PATH /opt/conda/envs/nf-core-imcyto-1.0dev/bin:$PATH
