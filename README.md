# Installation and deployment of Tutte Institute tools

The [Tutte Institute for Mathematics and Computing](https://github.com/TutteInstitute/),
as part of its data science research programs,
publishes multiple Python libraries for exploratory data analysis and complex network science.
While we compose these tools together all the time,
their joint setup is documented nowhere.
This repository provides this documentation,
as well as a set of tools for addressing some deployment edge cases.

This README file exposes various methods for installing,
in particular,
the Institute's data exploration and mapping libraries,
including [HDBSCAN](https://github.com/scikit-learn-contrib/hdbscan)
and [UMAP](https://github.com/lmcinnes/umap).

Shortcuts to the various installation and deployment procedures:

- [Installing from PyPI (or a mirror)](#installing-from-pypi-or-a-mirror)
- [Using a Docker image](#using-a-docker-image)
- [Deploying on modern UNIX hosts in an air-gapped network](#deploying-within-an-air-gapped-network)


## Installing from PyPI (or a mirror)

The main release channel for Tutte Institute libraries is the [Python Package Index](https://pypi.org/).
The simplest and best-supported approach to deploy these tools is thus simply to use `pip install`.
One may fetch file [exploration.txt](https://raw.githubusercontent.com/TutteInstitute/install-tools/refs/heads/main/exploration.txt)
and use it as a [requirements file](https://pip.pypa.io/en/stable/reference/requirements-file-format/),
invoking

```sh
pip install -r exploration.txt
```

In addition to `exploration.txt`,
this repository also provides another requirements file named [`science.txt`](https://raw.githubusercontent.com/TutteInstitute/install-tools/refs/heads/main/science.txt).
This one complements `exploration.txt` with further libraries and tools
that the data scientists of the Tutte Institute use in their day-to-day research and data analysis work.

**Requirements**

1. Access to the Internet (or to a PyPI mirror for using which `pip` is [duly](https://pip.pypa.io/en/stable/cli/pip_install/#cmdoption-i)[configured](https://pip.pypa.io/en/stable/topics/configuration/))
1. A C/C++ compilation toolchain

**Examples**

Using a [Python virtual environment](https://docs.python.org/3/library/venv.html)
on a modern UNIX (GNU/Linux, *BSD, MacOS and so on) host and a Bourne-compatible interactive shell (Bash or Zsh).
In this case,
the user has already set up a C/C++ compilation toolchain using their operating system's package manager
(e.g. on Debian/Ubuntu, `sudo apt-get install build-essential`).

```sh
python -m venv timc-tools
. timc-tools/bin/activate
python -m pip install -r exploration.txt
```

Using a [Conda](https://docs.conda.io/en/latest/) environment.
Remark that the following example includes a Conda package that brings up a generic C/C++ toolchain.

```sh
conda create -n timc-tools python=3.13 pip conda-forge::compilers
conda activate timc-tools
pip install -r exploration.txt
```

Using [uv](https://docs.astral.sh/uv/) to start [Jupyter Lab](https://jupyter.org/)
with a Python kernel that includes Tutte Institute tools.

```sh
uv run --with-requirements exploration.txt --with jupyterlab jupyter lab
```

uv's excellent package and environment caching avoids managing an environment explicitly on the side of the code development.


## Using a Docker image

This repository includes a [Dockerfile](Dockerfile)
to generate a pair of Docker images published on [Docker Hub](https://hub.docker.com/u/tutteinstitute).

1. `tutteinstitute/data-science` is a batteries-included image hosting a Python distribution including the data exploration libraries published by the institute, as well as the favorite tools of the data scientists that work in the Tutte Institute. It may be used to launch regular Python scripts, as well as [IPython](https://ipython.readthedocs.io/en/stable/), [Jupyter](https://jupyter.org/) Lab/Notebook and [Marimo](https://marimo.io/).
1. `tutteinstitute/data-exploration` is a minimal image hosting a Python distribution with only the tools from [exploration.txt](exploration.txt) (and their dependencies) deployed. It is best used as a base for folks to build their own images, appending the installation of their favorite tools.

Both images deploy the Python environment under an unprivileged account named `user`.
The `HOME` environment variable is set `/home/user`,
and the `PATH` environment variable is made to include `/home/user/timc/bin`,
as the parent directory `/home/user/timc` contains the Python distribution.
This user account is made to be writable by all users,
so that distinct host users
(determined through the `-u/--user` option of `docker run`)
can change the Python distribution as they wish.

**Requirements**

1. Ability to run [Docker](https://www.docker.com/)
1. Either access to [Docker Hub](https://hub.docker.com/) on the Internet, or have configuration to access an image repository index that mirrors the Tutte Institute images


**Examples**

Run Marimo on a notebook directory mounted to a container.

```sh
docker run --rm \
    --volume $(pwd)/my_notebooks:/notebooks \
    --workdir /notebooks \
    --port 2718:2718 \
    --user $(id -u) \
    tutteinstitute/data-science:latest \
    marimo edit --host 0.0.0.0
```

Customize the `data-exploration` image to run a Streamlit app that accesses a PostgreSQL database.
The Dockerfile:

```dockerfile
FROM tutteinstitute/data-exploration:latest
RUN pip install psycopg[binary] streamlit
ADD myapp.py /home/user/myapp.py
ENTRYPOINT ["streamlit", "run", "myapp.py", "--server.address", "0.0.0.0", "--server.port", 5000]
```

Build the new image and run the container:

```sh
docker build --tag myapp .
docker run --rm --publish 5000:5000 myapp
```
