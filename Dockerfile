FROM ubuntu:24.04

# Common settings for building from Ubuntu images.
SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

# Need Python 3 and a C/C++ toolchain.
RUN apt-get update && apt-get install --yes python-is-python3 python3-pip python3-full build-essential

# Make the environment.
RUN python -m venv /timc

# These settings effectively activate the environment permanently.
ENV VIRTUAL_ENV=/timc PATH=/timc/bin:$PATH

# Populate the environment.
RUN pip install setuptools setuptools-rust "timc-vector-toolkit"
