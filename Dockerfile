FROM nfcore/base
LABEL authors="Harshil Patel" \
      description="Docker image containing majority of requirements for nf-core/imcyto pipeline"

## Install gcc for pip CellProfiler install
RUN apt-get update && apt-get install -y gcc g++ && apt-get clean -y

## Set environment variables beforehand for pip CellProfiler install
ENV JAVA_HOME /opt/conda/envs/nf-core-imcyto-1.0dev
ENV PATH /opt/conda/envs/nf-core-imcyto-1.0dev/bin:$PATH

## Create CellProfiler environment
COPY environment.yml /
RUN conda env create -f /environment.yml && conda clean -a
