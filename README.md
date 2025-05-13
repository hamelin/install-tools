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

### Requirements

1. Access to the Internet (or to a PyPI mirror for using which `pip` is [duly](https://pip.pypa.io/en/stable/cli/pip_install/#cmdoption-i) [configured](https://pip.pypa.io/en/stable/topics/configuration/))
1. A C/C++ compilation toolchain

### Examples

<a id="venv"></a>
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

### Requirements

1. Ability to run [Docker](https://www.docker.com/)
1. Either access to [Docker Hub](https://hub.docker.com/) on the Internet, or have configuration to access an image repository index that mirrors the Tutte Institute images


### Examples

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


## Deploying on modern UNIX hosts in an air-gapped network

This repository comprises tools to build a self-contained Bash script that deploys a full Python distribution.
This distribution includes the tools enumerated in [`exploration.txt`](exploration.txt) and their dependency tree.

### Requirements

1. Either a GLibC-based GNU/Linux system **OR** a MacOS system
    * If you don't know whether your GNU/Linux system is based on GLibC, it likely is. The requirement enables using [Conda](https://learn.microsoft.com/en-us/windows/wsl/about). GNU/Linux distributions known not work are those based on [musl libc](https://musl.libc.org/), including [Alpine Linux](https://alpinelinux.org/).
1. Common UNIX utilities (such as included in [GNU Coreutils](https://www.gnu.org/software/coreutils/))

For the installer build step, these extra requirements should also be met:

3. [GNU Make](https://www.gnu.org/software/make/)
4. A C/C++ compilation toolchain
5. Full Internet access is expected

Remark that the installation building and deployment tools have only been tested on
Ubuntu Linux, MacOS and [WSL2/Ubuntu](https://learn.microsoft.com/en-us/windows/wsl/about) systems running on Intel x86-64 hardware.
Other GLibC-based Linux systems are supported on Intel x86-64 hardware;
alternative hardware platforms ARM64 (aarch64), IBM S390 and PowerPC 64 LE are likely to work, but are not supported.
Idem for 32-bits hardware platforms x86 and ARM7.
Finally, it sounds possible to make the tools work on non-WSL Windows,
but it has not been tested by the author and it is not supported.
\*BSD platforms are also excluded from support,
as no [Conda binary](https://repo.anaconda.com/miniconda/) is being distributed for them.

### Setup and deployment

Having cloned this repository, `cd` into your local copy and invoke

```sh
make
```

Provided everything works smoothly, you end up with a (quite large!) installation Bash script at path

```
out/timc-installer-<VERSION>-py<PYTHON VERSION>-<SYSTEM NAME>-<HARDWARE PLATFORM>.sh
```

The **SYSTEM NAME** and **HARDWARE PLATFORM** are determined by the system the installer is built on.
Thus, it is not possible to cross-build a MacOS installer on a GNU/Linux-x86_64 host.
However, one can change the Python version to another one they would rather target by editing file `config.mk`.
Change the line of the form

```
PYTHON_VERSION = 3.13
```

for an alternative value.
Please remark that,
as a whole,
the Tutte Institute tools are targeted to the minimum Python 3.9 version.
Anything lower is not supported.
In addition, the top supported Python version,
at any moment,
is the default value of `PYTHON_VERSION` in file `config.mk` on the `main` branch of this repository.

Bring this script over to each host of the air-gapped network where you mean to run the installer
(a shared network filesystem such as NFS works as well).
It can be run by any unprivileged user or as root,
enabling further downstream customization of the Python distribution and environment
(assuming the air-gapped network includes a [simple package repository](https://peps.python.org/pep-0503/)
or some other distribution infrastructure).
Using the `-h` flag shows some terse documentation:

```
This self-contained script sets up a Python computing environment that
includes common data science and data engineering tools, as well as the
libraries developed by the Tutte Institute for unsupervised learning
and data exploration.

Usage:
    ./out/timc-installer-20250508-py3.13-Linux-x86_64.sh [-h|--help]
    [-n name] [-p path] [-q]

Options:
    -h, --help
        Prints out this help and exits.
    -n name
        If the system has Conda set up, these tools will be installed
        as the named Conda environment. Do not use -p if you use -n.
    -p path
        Sets the path to the directory where to set up the computing
        environment, or where such an environment has been previously
        set up. Do not use -n if you use -p.
    -q
        Skips any interactive confirmation, proceeding with the default
        answer.

Without any of the -n or -p options, the installer simply deploys the
Tutte Institute tools in the current Conda environment or Python virtual
environment (venv).
```

There are three ways in which the installation can be run.

1. The most complete approach deploys the full Python distribution, over which it lays out the packages from [`exploration.txt`](exploration.txt), in a named directory. For this, use option `-p PATH-WHERE-TO-INSTALL`.
1. If [Conda](https://docs.conda.io/en/latest/) is also deployed on the host, the path can be chosen so that the distribution is deployed in a named Conda environment. For this, use option `-n DESIRED-ENVIRONMENT-NAME`.
    - Remark that if the host has Conda, it will still see the Python distribution deployed using `-p` as an environment, but not an environment with a *name* unless the path is a child of a directory listed under `envs_dirs` (check `conda config --show envs_dirs`).
1. If one would like to use a Python distribution that is already deployed on the system, one can create and activate a [virtual environment](#venv), then run the installer _without_ any of the options `-n` or `-p`. This will `pip`-install the wheels corresponding to the Tutte Institute tools and their dependencies _in the currently active environment_.

Finally, installation tasks are, by default, confirmed interactively in the shell.
To bypass this confirmation and just carry on in any case, use option `-q`.

### Using the installed Python distribution

Depending on the installation type,
one either gets a Python virtual environment or a Conda environment.
In the former case,
one uses it by *activating* the environment per usual.
For the usual Bash/Zsh shell,

```sh
source path/to/environment/bin/activate
```

There are alternative activation scripts for Powershell, Tcsh or Fish.

If instead the installation was *complete*,
as performed using either the `-n` or `-p` flags of the installer,
then the distribution works as a *Conda environment*.
If Conda is also deployed
(and set up for the user's shell)
on this air-gapped host,
one can use

```sh
conda activate name-of-environment  # Instealled with -n name-of-environment
conda activate path-to-environment  # Installed with -p path/to/environment
```

Short of using Conda,
*activating* such an environment merely involves tweaking the value of a set of environment variables.
For a basic Python distribution,
the only variable that strictly needs tweaking is `PATH`.
Thus, running in one's shell the Bash/Zsh equivalent to

```sh
export PATH="$(realpath path/to/environment):$PATH"
```

should suffice to make the distribution's `python`, `pip` and other executables pre-eminent,
and thus the environment *active*.
For the sake of convenience,
the distribution comes with a utility script named `startshell`.
This tool starts a subshell
(using the user's `$SHELL`, falling back on `/bin/bash`)
where this `PATH` tweaking is done.
`startshell` takes and relays all its parameters to the shell it starts,
so it can also be used as a launcher for the tools in the environment.
For instance:

```sh
path/to/environment/bin/startshell -c 'echo $PATH'
```

yields

```
/root/to/working/directory/path/to/environment/bin:<rest of what was in PATH>
```

More typically, one simply runs

```sh
path/to/environment/bin/startshell
```

so as to have a shell duly set up for using the installed Python distribution and tools.

### Installer customization

**TBD**
