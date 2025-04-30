#!/bin/bash
set -e


function exit_help() {{
    cat <<HELP
This self-contained script sets up a Python computing environment that includes
common data science and data engineering tools, as well as the libraries developed
by the Tutte Institute for unsupervised learning and data exploration.

Usage:
    $0 [-h|--help] [-p path]

Options:
    -h, --help
        Prints out this help and exits.
    -n name
        If the system has Conda set up, these tools will be installed as the named
        Conda environment. Do not use -p if you use -n.
    -p path
        Sets the path to the directory where to set up the computing environment,
        or where such an environment has been previously set up. Do not use -n if you
        use -p. By default, this is $path_install
    -q
        Skips any interactive confirmation, proceeding with the default answer.

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
path_install="$HOME/timc-{version}"
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
            cat <<-NOENVSDIRS
Cannot get Conda to reveal where the user can write its environments.
Use option -p instead.
NOENVSDIRS
            exit 5
        fi
        path_install="$dir_candidate/$name_env"
    else
        cat <<-NOCONDA
You specified the -n option, but you don't have Conda, or it is improperly set up for
your shell. Get your Conda in order or use the -p option instead.
NOCONDA
        exit 4
    fi
fi
if ! grep -q '^/' <<<"$path_install"; then
    path_install="./$path_install"
fi

shift $((OPTIND - 1))
[ "$1" = "--help" ] && exit_help

must_install=""
prompt=""
if [ ! -d "$path_install" ]; then
    must_install="yes"
    prompt="About to install in new directory $path_install. Proceed?"
elif [ ! -f "$path_install/bin/activate" -o ! -f "$path_install/bin/dmp_offline_cache" ]; then
    must_install="yes"
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

if [ "$must_install" = "yes" ]; then
    if [ -d "$dir_installer" ]; then
        cat <<-ERRMSG
This installer uses local subdirectory $dir_installer as a temporary
place to store intermediate files critical to the installation process.
It assumes this directory would not exist when it runs, but as it were,
it does exist. Please rename or destroy this directory before running
this installer; until then we abort the install process.
ERRMSG
        exit 3
    fi
    echo "--- Setting up the computing environment ---"
    tail -c +{after_header} "$0" | tar xf -
    trap "rm -rf $dir_installer" EXIT
    rm -rf "$path_install" || true
    bash "$dir_installer/base-$version-$platform.sh" -b -p "$path_install" -f
    cp "$dir_installer/startshell" "$path_install/bin/startshell"
    "$path_install/bin/startshell" -- <<-SETUP
    set -x
    pip install --no-index --find-links "$dir_installer/wheels" -r "$dir_installer/requirements.txt"
SETUP
    echo "--- Environment setup in $path_install successful ---"
else
    source "$path_install/bin/activate" "$path_install"
fi

exit 0
