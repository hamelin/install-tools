#!/bin/bash
set -e


msg=$(command -v fmt || echo cat)


function exit_help() {{
    $msg <<-HELP
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
HELP
    exit 0
}}


function exit_suggestion() {{
    echo "Run with argument -h for a summary of usage and options."
    exit 1
}}


function die_no_environment() {{
    echo "Cannot proceed without an environment that's been duly set up."
    echo "Please set the path to this environment using option -p, or run through the setup process."
    exit 2
}}


name_env=""
path_install="."
version="{version}"
platform="{platform}"
dir_installer="{dir_installer}"
interactive=yes

arg=""
while getopts ":hn:p:q" arg; do
    case "$arg" in
    h)
        exit_help
        ;;
    n)
        name_env="$OPTARG"
        ;;
    p)
        path_install="$OPTARG"
        ;;
    q)
        interactive=""
        ;;
    esac
done
case "$arg" in
?)
    if [ -n "$OPTARG" ]; then
        echo "Unknown argument: ${{OPTARG}}"
        exit_suggestion
    fi
    ;;
:)
    case "$OPTARG" in
    n)
        echo "Environment name is missing for -n option."
        ;;
    p)
        echo "Path is missing for -p option."
        ;;
    *)
        echo "Option with missing argument: ${{OPTARG}}"
        ;;
    esac
    exit_suggestion
    ;;
*)
    echo "Unknown argument parsing failure."
    exit_suggestion
    ;;
esac
if [ -n "$name_env" ]; then
    if command -v conda >/dev/null && [ -n "$CONDA_DEFAULT_ENV$CONDA_PREFIX" ]; then
        dir_candidate="$(conda info --json | python -c 'import json, os, sys; print(next(p for p in json.load(sys.stdin)["envs_dirs"] if os.path.isdir(p) and os.access(p, os.W_OK)))')"
        if [ -z "$dir_candidate" ]; then
            $msg <<-NOENVSDIRS
Cannot get Conda to reveal where the user can write its environments.
Use option -p instead.
NOENVSDIRS
            exit 5
        fi
        path_install="$dir_candidate/$name_env"
    else
        $msg <<-NOCONDA
You specified the -n option, but you don't have Conda, or it is improperly set up for
your shell. Get your Conda in order or use the -p option instead.
NOCONDA
        exit 4
    fi
fi

shift $((OPTIND - 1))
[ "$1" = "--help" ] && exit_help

must_install=""
prompt=""
if [ "$path_install" = "." ]; then
    if [ -n "$VIRTUAL_ENV" -o -n "$CONDA_DEFAULT_ENV" ]; then
        if ! command -v dmp_offline_cache >/dev/null; then
            must_install="pip"
            if [ -n "$VIRTUAL_ENV" ]; then
                prompt="About to install the tools in the current venv ($VIRTUAL_ENV). Proceed?"
            elif [ -n "$CONDA_DEFAULT_ENV" ]; then
                prompt="About to install the tools in the current Conda environment ($CONDA_DEFAULT_ENV). Proceed?"
            else
                echo "Incoherent venv/Conda env settings detected. Use the -p or -n option."
                exit 7
            fi
        fi
    fi
elif [ ! -d "$path_install" ]; then
    must_install="conda+pip"
    prompt="About to install Python and Tutte Institute tools in new directory $path_install. Proceed?"
elif [ ! -f "$path_install/bin/activate" -o ! -f "$path_install/bin/dmp_offline_cache" ]; then
    must_install="conda pip"
    prompt="Environment at $path_install seems to lack some critical components. Reinstall?"
fi
if [ -n "$interactive" -a -n "$prompt" ]; then
    read -e -p "$prompt [Yn] "
    case "$REPLY" in
    [yY]*)
        # Proceed with setup!
        ;;
    "")
        # Same
        ;;
    [^nN]*)
        echo "Reply unclear. Assuming refusal."
        die_no_environment
        ;;
    [nN]*)
        die_no_environment
        ;;
    esac
fi

if [ -n "$must_install" ]; then
    if [ -d "$dir_installer" ]; then
        $msg <<-ERRMSG
This installer uses local subdirectory $dir_installer as a temporary
place to store intermediate files critical to the installation process.
It assumes this directory would not exist when it runs, but as it were,
it does exist. Please rename or destroy this directory before running
this installer; until then we abort the install process.
ERRMSG
        exit 3
    fi
    echo "--- Extracting installation components ---"
    trap "rm -rf $dir_installer" EXIT
    tail -c +{after_header} "$0" | tar xf -
    pip_cmd="pip install --no-index --find-links \"$dir_installer/wheels\" -r \"$dir_installer/requirements.txt\""
    if grep -q 'conda' <<<"$must_install"; then
        echo "--- Set up the base for a Python computing environment ---"
        rm -rf "$path_install" || true
        bash "$dir_installer/base-$version-$platform.sh" -b -p "$path_install" -f
        cp "$dir_installer/startshell" "$path_install/bin/startshell"
        export PATH="$path_install/bin:$PATH"
    else
        python_version_here="$(python -c 'import sys; print(f"{{sys.version_info.major}}.{{sys.version_info.minor}}")')"
        if [ "$python_version_here" != "{python_version}" ]; then
            $msg <<-WRONGPYTHON
The Python wheels included in this package were compiled for Python {python_version},
but the Python version deployed in this environment is $python_version_here. Therefore,
these wheels cannot be deployed as requested. Use option -p in order to deploy a distinct
Python distribution with which the wheels included herein can be used.
WRONGPYTHON
            exit 9
        fi
    fi

    echo "--- Install Tutte Institute tools and their dependencies ---"
    eval $pip_cmd
    echo "--- Environment setup is successful ---"
else
    echo "--- Python environment is already complete ---"
fi

tasks=$(ls "$dir_installer"/tasks/*.sh | sort)
num_tasks=$(wc -w <<<"$tasks")
echo "--- Post-install tasks ---"
i=0
for task in $tasks; do
    i=$(($i + 1))
    step="[$i/$num_tasks]"
    source "$task"
done

exit 0
