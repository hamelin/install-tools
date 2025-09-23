# Add here Makefile rules to collect any other install artifacts to add
# to the installer bundle. Use scripts in the tasks/ subdirectory to
# deploy these artifacts at install time. These are automatically put
# in the artifacts directory, so you do not have to handle their
# transfer using this Makefile.
#
# This Makefile is used in a Make invocation where no target is supplied
# at the command line. Thus, its top target will be resolved. It should
# thus be built in such a way as to put everything needed in the directory
# of installation artifacts.
#
#You may rely on the following variables to build your rules.
#
# DIR_ARTIFACTS
#     Directory of all files that will be bundled in the installation script.
#     If something should be deployed as part of the computing environment
#     you expect to build on the target workstations, it should be stored
#     here. Note that at the moment this Makefile is run, the Python wheels of
#     the transitive dependency closure of the packages required to compose
#     the target environment have been collected in $(DIR_ARTIFACTS)/wheels.
#     It can be useful and quick to augment the bootstrap environment with any
#     of these to collect artifacts that depend on running Python code
#     requiring these packages.
#     
# BOOTSTRAP
#     Directory to the bootstrap Python environment.
#
# FROM_BOOTSTRAP
#     Utility macro that activates the bootstrap environement. Use it to
#     run a command that should be aware of this environment, such as
#
#     $(FROM_BOOTSTRAP) && pip install --no-index --find-links $(DIR_ARTIFACTS)/wheels some_dependency_collected_earlier

.PHONY: extras
extras: $(DIR_ARTIFACTS)/crickets

$(DIR_ARTIFACTS)/crickets:
	echo 'chirp chirp chirp' >$@
