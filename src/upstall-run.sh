#!/bin/bash
set -e


path_default="$HOME/miniconda3"


commands="\
setup
    Simply sets up the environment then exits.

sh or shell
    Starts a login shell (using one's default shell) set up to include the settings
    of the computing environment. Arguments that follow sh or shell are appended
    to the shell's command line.

bash
    Starts a Bash login shell set up to include the settings of the computing
    environment. Arguments that follow are appended to the /bin/bash command line.

Any other command, e.g. jupyter, python, conda...
    Runs that command with settings such as to include the computing environment.
    Arguments that follow the first word are appended to the command line. Examples:

    $0 conda init bash   # Set up your bash start-up to include the computing environment
    $0 jupyter lab       # Start Jupyter Lab directly from the environment.
    $0 python script.py  # Runs the given script using the environment."

function exit_help() {
    cat <<HELP
This self-contained script sets up a Python computing environment that includes
common data science and data engineering tools, as well as the libraries developed
by the Tutte Institute for unsupervised learning and data exploration.

Usage:
    $0 [-h|--help] [-p path] command [args ...]

Options:
    -h, --help
        Prints out this help and exits.
    -p path
        Sets the path to the directory where to set up the computing environment,
        or where such an environment has been previously set up. By default, this is
        $path_default

Commands:

$commands

HELP
    exit 0
}


function exit_suggestion() {
    echo "Run with argument -h for a summary of usage and options."
    exit 1
}


function die_no_environment() {
    echo "Cannot proceed without an environment that's been duly set up."
    echo "Please set the path to this environment using option -p, or run through the setup process."
    exit 2
    
}


path_install="$path_default"
version="2025.02"
platform="Linux"
arch="x86_64"
dir_installer="timc-installer-$version"

arg=""
while getopts ":hp:" arg; do
    case "$arg" in
    h)
        exit_help
        ;;
    p)
        path_install="$OPTARG"
        ;;
    esac
done
case "$arg" in
?)
    if [ -n "$OPTARG" ]; then
        echo "Unknown argument: ${OPTARG}"
        exit_suggestion
    fi
    ;;
:)
    case "$OPTARG" in
    p)
        echo "Path is missing for -p option."
        die_suggestion
        ;;
    *)
        echo "Option with missing argument: ${OPTARG}"
        die_suggestion
        ;;
    esac
    ;;
*)
    echo "Unknown argument parsing failure."
    die_suggestion
    ;;
esac
if ! grep -q '^/' <<<"$path_install"; then
    $path_install="./$path_install"
fi

shift $((OPTIND - 1))
command=${1:-nocommand}
[ "$command" = "--help" ] && exit_help
shift || true

must_install=""
prompt=""
if [ ! -d "$path_install" ]; then
    must_install="yes"
    if [ "$path_install" != "$path_default" ]; then
        prompt="Non-standard environment path $path_install does not exist. Install?"
    fi
elif [ ! -f "$path_install/bin/activate" -o ! -f "$path_install/bin/python" ]; then
    must_install="yes"
    prompt="Environment at $path_install seems to lack some critical components. Reinstall?"
fi
if [ -n "$prompt" ]; then
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
    echo "--- Setting up the computing environment ---"
    tail -c +6145 "$0" | tar xf -
    trap "rm -rf '$dir_installer'" EXIT
    rm -rf "$path_install" || true
    bash "$dir_installer/base-$version-$platform-$arch.sh" -b -p "$path_install" -f
    source "$path_install/bin/activate" "$path_install"
    pip install --no-index --find-links "$dir_installer" -r "$dir_installer/requirements.txt"
    dmp_offline_cache --import "$dir_installer/dmp_cache.zip"
    mkdir -p "$HOME/.cache"
    rm -rf "$HOME/.cache/huggingface"
    mv "$dir_installer/huggingface-cache" "$HOME/.cache/huggingface"
    echo "--- Environment setup in $path_install successful ---"
else
    source "$path_install/bin/activate" "$path_install"
fi

case "$command" in
setup)
    # Already done!
    ;;
nocommand)
    cat <<-NOCOMMAND
You have not provided any follow-on command. You may re-run this script with any of the
following commands:

$commands

Happy computing!
NOCOMMAND
    ;;
bash)
    exec /bin/bash --login $@
    ;;
shell|sh)
    shell=$(getent passwd $(whoami) | awk -F: '{print $NF}')
    exec "$shell" --login $@
    ;;
*)
    exec $command $@
    ;;
esac
exit 0
