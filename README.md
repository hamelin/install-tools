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
the Institute's unstructured data exploration and mapping tools,
including [HDBSCAN](https://github.com/scikit-learn-contrib/hdbscan)
and [UMAP](https://github.com/lmcinnes/umap).
These tools are collectively understood as the **TIMC vector toolkit**.

Shortcuts to the various installation and deployment procedures:

- [Installing from PyPI (or a mirror)](#installing-from-pypi-or-a-mirror)
- [Using a Docker image](#using-a-docker-image)
- [Deploying on modern UNIX hosts in an air-gapped network](#deploying-on-modern-unix-hosts-in-an-air-gapped-network)


## Installing from PyPI (or a mirror)

The main release channel for Tutte Institute libraries is the [Python Package Index](https://pypi.org/).
The simplest and best-supported approach to deploy these tools is thus simply to use `pip install`
(or the tools that supersede it, such as [uv](https://docs.astral.sh/uv/) or [Poetry](https://python-poetry.org/)).

```sh
pip install timc-vector-toolkit
```

This package includes the Institute libraries without upper-bounding their versions.
As such, newer versions of the package are mainly produced when adding new libraries
to the toolkit.
Please do not mistake the age of package `timc-vector-toolkit` for abandon.

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
python -m pip install timc-vector-toolkit
```

Using a [Conda](https://docs.conda.io/en/latest/) environment.
Remark that the following example includes a Conda package that brings up a generic C/C++ toolchain.

```sh
conda create -n timc-tools python=3.13 pip conda-forge::compilers
conda activate timc-tools
pip install timc-vector-toolkit
```

Using [uv](https://docs.astral.sh/uv/) to start [Jupyter Lab](https://jupyter.org/)
with a Python kernel that includes Tutte Institute tools.

```sh
uv run --with timc-vector-toolkit --with jupyterlab jupyter lab
```

uv's excellent package and environment caching avoids managing an environment explicitly on the side of the code development.


## Using a Docker image

This repository includes a [Dockerfile](Dockerfile)
to generate a Docker image published on [Docker Hub](https://hub.docker.com/u/tutteinstitute).
The image, named `tutteinstitute/vector-toolkit`,
is based on the latest Ubuntu LTS release
and its native Python 3 distribution.
We set up an environment that includes package `timc-vector-toolkit`.
Tags to this image reflect the time they were produced.
The image is presumed to be used as a base for further application packaging.
For example, one may augment this image to build an image that hosts Jupyter Lab
through an unprivileged user:

```dockerfile
FROM tutteinstitute/vector-toolkit:latest
RUN pip install jupyterlab ipywidgets matplotlib ipympl seaborn
RUN adduser --disabled-password --comment "" user
WORKDIR /home/user
USER user
EXPOSE 8888
ENTRYPOINT ["/timc/bin/jupyter", "lab", "--port", "8888", "--ip", "0.0.0.0", "--notebook-dir", "/notebooks"]
```

Running this image into a container,
one minds forwarding a port to 8888,
and mounting a universally writable volume to `/notebooks`.

### Requirements

1. Ability to run [Docker](https://www.docker.com/)
1. Either access to [Docker Hub](https://hub.docker.com/) on the Internet, or have configuration to access an image repository index that mirrors `tutteinstitute/vector_toolkit` tags


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

This repository comprises tools to build a self-contained Bash script that deploys an _all-dressed_ full Python distribution.
This distribution is designed to include `timc-vector-toolkit` and its dependencies,
but it can be customized to one's specific needs.
It can also include additional non-Python artifacts,
such as model files or web resources.

### Requirements

Both for building the installer **and** deploying the distribution:

1. Either a GLibC-based GNU/Linux system **OR** a MacOS system
    * If you don't know whether your GNU/Linux system is based on GLibC, it likely is. The requirement enables using [Conda](https://learn.microsoft.com/en-us/windows/wsl/about). GNU/Linux distributions known not to work are those based on [musl libc](https://musl.libc.org/), including [Alpine Linux](https://alpinelinux.org/).
    * A MacOS host system will build a distribution that can deploy on a MacOS target system; a GNU/Linux host system will build a distribution that can deploy on most GLibC-based GNU/Linux systems. Perform target tests ahead of committing much work into building the perfect installer.
1. Common UNIX utilities (such as included in [GNU Coreutils](https://www.gnu.org/software/coreutils/))

For the installer build step, these extra requirements should also be met:

3. [Cookiecutter](https://cookiecutter.readthedocs.io/en/stable/)
3. [GNU Make](https://www.gnu.org/software/make/)
4. A C/C++ compilation toolchain
5. Full Internet access is expected

The installation building and deployment tools have only been tested on
Ubuntu Linux, MacOS and [WSL2/Ubuntu](https://learn.microsoft.com/en-us/windows/wsl/about) systems running on Intel x86-64 hardware.
Other GLibC-based Linux systems are supported on Intel x86-64 hardware;
alternative hardware platforms ARM64 (aarch64), IBM S390 and PowerPC 64 LE are likely to work, but are not supported.
Idem for 32-bits hardware platforms x86 and ARM7.
Finally, it sounds possible to make the tools work on non-WSL Windows,
but it has not been tested by the author and it is not supported.
\*BSD platforms are also excluded from support,
as no [Conda binary](https://repo.anaconda.com/miniconda/) is being distributed for them.

### Step 1: preparing the distribution

This repository is organized to host multiple distribution installer _projects._
Each such project is composed in its own subdirectory.
An [example distribution project](example) is provided for examining and experimentation.

One's own project is initiated by running

```sh
cookiecutter template
```

The first question sets the name of the installer to produce through this project,
which will be appended with `.sh`.
For instance, using default value `my-installer` would,
as output to [building the installer](#step-2-building-the-installer),
For instance, using default value `my-installer` would,
yield a file named `out/my-installer.sh`.
The second question sets the minor Python version that would get distributed through the installer.
Choose a version that can run all the package dependencies you want deployed with your distribution.

Once all questions are answered, the project named like your answer to question 1 is created.
It contains the following files:

**`python_version`**

Specifies the minor Python version to base the distribution on.
Change it here rather than have to edit it throughout other files.

**`bootstrap.yaml`**

Specifies a Conda environment that will be used to put together the Python installer.
This rarely needs to be edited.

**`construct.yaml`**

This is a [Conda Constructor specification](https://conda.github.io/constructor/construct-yaml/)
used to put together the Python installer out of a set of Conda packages.
Under the `specs` section,
add any further Conda package you would like installed as part of your target distribution.
Other packages will be sourced out of the [Python Package Index](https://pypi.org/).

**`requirements.txt`**

This is the main file to edit the essential contents of the distribution your want deployed on your target systems.
Per [documentation](https://pip.pypa.io/en/stable/reference/requirements-file-format/),
you may specify version bounds for each package you include.

**`extras.mk`** and **`tasks`**

`extras.mk` is a small bit of [Makefile](https://www.gnu.org/software/make/manual/html_node/Simple-Makefile.html)
that specifies rules for gathering _extras_,
resources that should be bundled into the installers.
These can be model weights to downloads,
datasets,
web resources,
scripts &mdash; anything one can put in files.
At deployment time,
these extras are deployed on the target host by running the scripts under the `tasks` subdirectory in alphanumerical order.
Remark that the installer produced by this project is expected to be run with a user's own level of privileges,
which may or may not be root.
Determine how the installer will be used on the target network when setting up the list of install tasks,
so as to ensure success.

A header comment to `extras.mk` provides further Makefile variable definitions and details to guide and facilitate the implementation of extras gathering tasks.

### Step 2: building the installer

To build the installer, we use GNU Make.
Given project `my-installer`,
the installer script is produced by running

```sh
make out/my-installer.sh
```

You may still edit the constituent files of the project afterwards.
Running GNU Make again will rebuild the installer incrementally.
Remark, once again, that the host system and the target system are expected to match;
the closer they are, the better the odds the installer will work.
No cross-building of MacOS installers can be done from a GNU/Linux host,
or vice-versa.

### Step 3: deploying the distribution on target systems

Bring the installer script over to each host of the air-gapped network where you mean to run it
(a shared network filesystem such as NFS works as well).
It can be run by any unprivileged user or as root.
Using the `-h` flag shows some terse documentation:

```
This self-contained script sets up a Python computing environment that includes
common data science and data engineering tools, as well as the libraries developed
by the Tutte Institute for unsupervised learning and data exploration.

Usage:
    $0 [-h|--help] [-n name] [-p path] [-q]

Options:
    -h, --help
        Prints out this help and exits.
    -n name
        If the system has Conda set up, these tools will be installed as the named
        Conda environment. Do not use -p if you use -n.
    -p path
        Sets the path to the directory where to set up the computing environment,
        or where such an environment has been previously set up. Do not use -n if you
        use -p.
    -q
        Skips any interactive confirmation, proceeding with the default answer.

Without any of the -n or -p options, the installer simply deploys the Tutte Institute
tools in the current Conda environment or Python virtual environment (venv).
```

There are three ways in which the installation can be run.

1. The most complete approach deploys the full Python distribution, over which it lays out the packages from [`exploration.txt`](exploration.txt), in a named directory. For this, use option `-p PATH-WHERE-TO-INSTALL`.
1. If [Conda](https://docs.conda.io/en/latest/) is also deployed on the host, the path can be chosen so that the distribution is deployed in a named Conda environment. For this, use option `-n DESIRED-ENVIRONMENT-NAME`.
    - Remark that if the host has Conda, it will still see the Python distribution deployed using `-p` as an environment, but not an environment with a *name* unless the path is a child of a directory listed under `envs_dirs` (check `conda config --show envs_dirs`).
1. If one would like to use a Python distribution that is already deployed on the system, one can create and activate a [virtual environment](#venv), then run the installer _without_ any of the options `-n` or `-p`. This will `pip`-install the wheels corresponding to the Tutte Institute tools and their dependencies _in the currently active environment_.

Finally, installation tasks are, by default, confirmed interactively in the shell.
To bypass this confirmation and just carry on in any case, use option `-q`.

### Step 4: using the installed Python distribution

Depending on the installation type,
one either gets a Python virtual environment or a Conda environment.
<a id="activation"></a>
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
