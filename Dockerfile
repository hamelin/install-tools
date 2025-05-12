ARG IMAGE_BASE=ubuntu:latest

FROM ${IMAGE_BASE} AS base
SHELL ["/bin/bash", "-c"]
RUN apt update && apt install --yes curl bzip2
RUN useradd --home /home/user --create-home --shell /bin/bash --key UMASK=0 --key HOME_MODE=0777 user
USER user
WORKDIR /home/user
RUN chmod -R a+rwX .

FROM base AS conda
RUN curl -o install-miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
RUN chmod +x install-miniconda.sh && ./install-miniconda.sh -b -p /home/user/miniconda3
ARG VERSION
ARG PYTHON_VERSION
RUN source /home/user/miniconda3/bin/activate /home/user/miniconda3 \
    && conda create \
        --override-channels \
        --channel defaults \
        --yes \
        --prefix /home/user/timc \
        python=${PYTHON_VERSION} pip numpy scipy scikit-learn setuptools setuptools-rust wheel conda-forge::compilers
ADD --chown=user exploration.txt requirements.txt
RUN source /home/user/miniconda3/bin/activate /home/user/miniconda3 \
    && conda activate /home/user/timc \
    && pip install -r requirements.txt \
    && rm requirements.txt

FROM base AS data-exploration
COPY --from=conda --chown=user --chmod=777 /home/user/timc /home/user/timc
ENV HOME=/home/user PATH=/home/user/timc/bin:$PATH

FROM data-exploration AS data-science
ADD --chown=user science.txt requirements.txt
RUN umask 0000 \
    && pip install -r requirements.txt \
    && rm requirements.txt
