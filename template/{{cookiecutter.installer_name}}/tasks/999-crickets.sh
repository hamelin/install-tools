# All files in this directory are collected into the installer bundle and
# sourced in alphanumeric order after the Python environment has been built.
# Use such scripts to deploy further artifacts into the Python computing
# environment, or beyond. Remark, however, that these scripts may not be
# running with administrative (root) privileges, so what you may do is
# constrained by the intended use of the installer.
#
# When the task scripts are sourced, the Python environment is completely
# deployed, and it is active (command 'python' invokes the Python interpreter
# that lives in the environment, etc.). You may expect the following
# environment variables to be defined for your usage:
#
# dir_artifacts
#     Directory of the unarchived bundle of installation artifacts that
#     were collected when the installer was compiled.

echo "Crickets sing: $(cat $dir_artifacts/crickets)"
