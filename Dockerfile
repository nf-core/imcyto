FROM nfcore/base
LABEL authors="Harshil Patel" \
      description="Docker image containing all requirements for nf-core/imcyto pipeline"

COPY environment.yml /
RUN conda env create -f /environment.yml && conda clean -a
ENV PATH /opt/conda/envs/nf-core-imcyto-1.0dev/bin:$PATH
