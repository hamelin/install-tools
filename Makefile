SHELL = /bin/bash
ALL_INSTALLERS = $(patsubst %/python_version,out/%.sh,$(wildcard */python_version))


.PHONY: help
help:
	@echo 'Buildable installer targets: '
	@echo
	@echo $(ALL_INSTALLERS) | xargs -n1 | awk '{printf("    %s\n", $$1)}'
	@echo
	@echo You may also invoke _make all_ to build all of them.


MINICONDA = Miniconda3-latest-$(shell uname -s)-$(shell uname -m).sh
DIR_MINICONDA = miniconda
MINICONDA_INSTALLER = $(DIR_MINICONDA)/$(MINICONDA)
GROUND = $(DIR_MINICONDA)/ground
CONSTRUCTOR = $(GROUND)/bin/constructor
FROM_GROUND = source $(GROUND)/bin/activate
BOOTSTRAP = out/$(1)-bootstrap
FROM_BOOTSTRAP = $(FROM_GROUND) && conda activate $(call BOOTSTRAP,$(1))
RESOLVE = $(FROM_GROUND) && python resolve.py $(1)
BOOTSTRAP = out/$(1)-bootstrap
BOOTSTRAP_PIP = $(call BOOTSTRAP,$(1))/bin/pip
DIR_ARTIFACTS = out/$(1)-artifacts
COMMON_ARTIFACTS = $(addprefix $(call DIR_ARTIFACTS,$(1))/,requirements.txt startshell enable-python.sh install-python.sh)

.PHONY: all
all: $(ALL_INSTALLERS)
	
out/%.sh: out/%-install.sh $(call COMMON_ARTIFACTS,%) out/%.wheels out/%.extras
	cat $< <(cd out && tar cf - $*-artifacts) >$@
	chmod +x $@
	test -f $@ -a $$(stat --format %s $@) -gt 1048576 || (rm -f $@ ; exit 1)

out/%.extras: %/extras.mk $(wildcard %/tasks/*.sh)
	$(MAKE) -f $< SHELL=/bin/bash DIR_ARTIFACTS="$(call DIR_ARTIFACTS,$*)" BOOTSTRAP="out/$*-bootstrap" FROM_BOOTSTRAP="$(call FROM_BOOTSTRAP,$*)"
	mkdir -p $(call DIR_ARTIFACTS,$*)/tasks
	cp -v $*/tasks/*.sh $(call DIR_ARTIFACTS,$*)/tasks
	touch $@

out/%-install.sh: install.sh %/python_version $(CONSTRUCTOR)
	mkdir -p $(@D)
	$(call RESOLVE,$*) <$< >$@
	
.PHONY: out/%/common-artifacts
out/%/common-artifacts: $(call COMMON_ARTIFACTS,%)
	@true

$(call DIR_ARTIFACTS,%)/requirements.txt: %/requirements.txt
	mkdir -p $(@D)
	cp $< $@

$(call DIR_ARTIFACTS,%)/startshell: startshell
	mkdir -p $(@D)
	cp $< $@
		
$(call DIR_ARTIFACTS,%)/enable-python.sh: enable-python.sh
	mkdir -p $(@D)
	cp $< $@

out/%.wheels: %/requirements.txt $(call BOOTSTRAP_PIP,%)
	mkdir -p $(call DIR_ARTIFACTS,$*)
	$(call FROM_BOOTSTRAP,$*) && $(call BOOTSTRAP_PIP,$*) wheel --wheel-dir $(call DIR_ARTIFACTS,$*)/wheels --no-cache-dir -r $<
	touch $@

.PHONY: out/%/bootstrap
out/%/bootstrap: $(call BOOTSTRAP_PIP,%)
	
$(call BOOTSTRAP_PIP,%): %/bootstrap.yaml %/python_version $(CONSTRUCTOR)
	$(call RESOLVE,$*) <$< >out/$*-bootstrap.yaml
	$(FROM_GROUND) && conda env create --prefix $(call BOOTSTRAP,$*) --file out/$*-bootstrap.yaml --yes

$(call DIR_ARTIFACTS,%)/install-python.sh: %/construct.yaml %/python_version $(CONSTRUCTOR)
	mkdir -p $(@D)
	$(call RESOLVE,$*) <$< >out/$*-construct.yaml
	DIRTEMP=$$(mktemp -d) \
		&& trap "rm -rf \"$$DIRTEMP\"" EXIT \
		&& $(FROM_GROUND) \
		&& constructor --output-dir $$DIRTEMP --config-file=$*-construct.yaml out \
		&& cat "$$DIRTEMP"/*.sh >$@ \
		|| rm -f $@

.PRECIOUS: \
	out/%.extras \
	out/%-install.sh \
	$(call DIR_ARTIFACTS,%)/requirements.txt \
	$(call DIR_ARTIFACTS,%)/startshell \
	$(call DIR_ARTIFACTS,%)/enable-python.sh \
	out/%.wheels \
	$(call BOOTSTRAP_PIP,%) \
	$(call DIR_ARTIFACTS,%)/install-python.sh

$(CONSTRUCTOR): $(MINICONDA_INSTALLER)
	./$(MINICONDA_INSTALLER) -bf -p $(dir $(@D))
	$(FROM_GROUND) \
		$(foreach ch,main r,&& conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/$(ch)) \
		&& conda install --override-channels --channel defaults --yes constructor

$(MINICONDA_INSTALLER):
	mkdir -p $(@D)
	curl -o $@ https://repo.anaconda.com/miniconda/$(MINICONDA) && chmod +x $@ || rm $@

clean:
	test -f $(CONSTRUCTOR) && $(FROM_GROUND) && constructor --clean || exit 0
	rm -rf out

veryclean: clean
	rm -rf $(DIR_MINICONDA)
