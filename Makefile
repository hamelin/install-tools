SHELL = /bin/bash
OUTPUT = out
PLATFORM = $(shell uname -s)-$(shell uname -m)
VERSION = 20250428
SIZE_HEADER = 6144

MINICONDA = Miniconda3-latest-$(PLATFORM).sh
MINICONDA_INSTALLER = $(OUTPUT)/$(MINICONDA)
CHANNELS = defaults conda-forge

BOOTSTRAP = $(OUTPUT)/bootstrap
IN_BOOTSTRAP = source $(BOOTSTRAP)/bin/activate
PKGS_BOOTSTRAP = compilers constructor setuptools setuptools-rust wheel

CONCRETIZE = $(IN_BOOTSTRAP) && python -c 'import sys; print(sys.stdin.read().format(platform="$(PLATFORM)", version="$(VERSION)", after_header=str($(SIZE_HEADER) + 1), dir_installer="./$(SUBDIR_INSTALL)"))' <$(1) >$(2) || (rm -f $(2); exit 1)
SUBDIR_INSTALL = timc-installer-${VERSION}
GOODIE = $(OUTPUT)/$(SUBDIR_INSTALL)

INSTALLER_BASE=$(GOODIE)/base-$(VERSION)-$(PLATFORM).sh
WHEEL=$(GOODIE)/wheels/$(1)
WHEELS=$(OUTPUT)/wheels-gathered
INSTALLER=$(OUTPUT)/timc-installer-$(VERSION)-$(PLATFORM).sh
DOCKERIMAGE = $(OUTPUT)/docker-image-$(VERSION)
TAG = timc

GOODIES = $(INSTALLER_BASE) $(WHEELS) $(GOODIE)/requirements.txt $(GOODIE)/startshell
GOODIES_GATHERED = $(OUTPUT)/goodies-gathered


# -------------------------------------------------------------------


$(DOCKERIMAGE): $(INSTALLER) Dockerfile
	docker build --build-arg installer=$< --tag $(TAG):$(VERSION) .
	touch $@

$(INSTALLER): $(OUTPUT)/install.sh $(GOODIES_GATHERED)
	test -d $(GOODIE)/tmp && rmdir $(GOODIE)/tmp || true
	cat $< <(cd $(OUTPUT) && tar cvf - $(SUBDIR_INSTALL)) >$@
	chmod +x $@
	test -f $@ -a $$(stat --format %s $@) -gt 1048576 || (rm -f $@ ; exit 1)

$(OUTPUT)/install.sh: install.sh $(BOOTSTRAP)/ready
	test $$(stat --format="%s" $<) -lt $(SIZE_HEADER)
	mkdir -p $(@D)
	$(call CONCRETIZE,$<,$@)
	truncate --size=$(SIZE_HEADER) $@

$(GOODIES_GATHERED): $(GOODIES)
	touch $@
	
$(GOODIE)/requirements.txt: requirements.txt
	mkdir -p $(@D)
	cp $< $@

$(GOODIE)/startshell: startshell
	mkdir -p $(@D)
	cp $< $@
	
$(WHEELS): requirements.txt $(BOOTSTRAP)/ready
	$(IN_BOOTSTRAP) && pip wheel --wheel-dir $(WHEEL) --no-cache-dir -r $<
	touch $@

$(INSTALLER_BASE): $(BOOTSTRAP)/ready $(OUTPUT)/construct.yaml
	mkdir -p $(@D)
	$(IN_BOOTSTRAP) && constructor --output-dir $(@D) $(OUTPUT)

$(OUTPUT)/construct.yaml: construct.yaml
	$(call CONCRETIZE,$<,$@)

$(BOOTSTRAP)/ready: $(BOOTSTRAP)/deployed
	$(IN_BOOTSTRAP) && conda install --override-channels $(foreach ch,$(CHANNELS),--channel $(ch)) --yes $(PKGS_BOOTSTRAP)
	touch $@

$(BOOTSTRAP)/deployed:
	$(MAKE) $(MINICONDA_INSTALLER)
	bash $(MINICONDA_INSTALLER) -bf -p $(BOOTSTRAP)
	touch $< $@
	rm $(MINICONDA_INSTALLER)

$(MINICONDA_INSTALLER):
	mkdir -p $(dir $@)
	curl -o $(MINICONDA_INSTALLER) https://repo.anaconda.com/miniconda/$(MINICONDA)

cleanimage:
	docker image rm $(TAG):$(VERSION)

clean: cleanimage
	test -d $(BOOTSTRAP) && $(IN_BOOTSTRAP) && constructor --clean || exit 0
	rm -rf $(OUTPUT)
