FROM ubuntu:24.04 AS base
SHELL ["/bin/bash", "-c"]
RUN apt update && apt install --yes curl bzip2
RUN useradd --home /home/user --create-home --shell /bin/bash user
USER user
WORKDIR /home/user

FROM base AS install-python
RUN curl -o install-miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
RUN chmod +x install-miniconda.sh && ./install-miniconda.sh -b -p /home/user/miniconda3
RUN source /home/user/miniconda3/bin/activate /home/user/miniconda3 \
    && conda create --yes --prefix /home/user/timc python pip numpy scipy scikit-learn setuptools setuptools-rust wheel conda-forge::compilers
ADD --chown=user requirements.txt requirements.txt
RUN source /home/user/miniconda3/bin/activate /home/user/miniconda3 \
    && conda activate /home/user/timc \
    && pip install -r requirements.txt \
    && rm requirements.txt

FROM base AS final
COPY --from=install-python --chown=user /home/user/timc /home/user/timc
RUN echo 'export PATH="/home/user/timc/bin:$PATH"' >>/home/user/.bashrc
