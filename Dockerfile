ARG IMAGE_BASE=ubuntu:latest

FROM ${IMAGE_BASE}
ARG VERSION
ARG PYTHON_VERSION
SHELL ["/bin/bash", "-c"]
RUN apt update && apt install --yes python-is-python3 python3-pip python3-full build-essential
RUN pip install --break-system-packages uv && uv venv --python=${PYTHON_VERSION} /timc
ENV VIRTUAL_ENV=/timc PATH=/timc/bin:$PATH
RUN uv pip install setuptools setuptools-rust "timc-vector-toolkit==${VERSION}"
