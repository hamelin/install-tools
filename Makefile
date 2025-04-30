SHELL = /bin/bash
OUTPUT = out/$(1)
PLATFORM = $(shell uname -s)-$(shell uname -m)
VERSION = 20250428
SIZE_HEADER = 6144

MINICONDA = Miniconda3-latest-$(PLATFORM).sh
MINICONDA_INSTALLER = $(call OUTPUT,$(MINICONDA))
CHANNELS = defaults conda-forge

DOCKERIMAGE = $(call OUTPUT,docker-image-$(VERSION))
INSTALLER = $(call OUTPUT,timc-installer-$(VERSION).sh)

BOOTSTRAP = $(call OUTPUT,bootstrap/$(1))
IN_BOOTSTRAP = source $(call BOOTSTRAP,bin/activate) && $(1)
PKGS_BOOTSTRAP = compilers constructor setuptools setuptools-rust wheel

CONCRETIZE = $(call IN_BOOTSTRAP,python -c 'import sys; print(sys.stdin.read().format(platform="$(PLATFORM)", version="$(VERSION)", after_header=str($(SIZE_HEADER) + 1), dir_installer="./$(SUBDIR_INSTALL)"))' <$(1) >$(2) || (rm -f $(2); exit 1))
SUBDIR_INSTALL = timc-installer-${VERSION}
GOODIE = $(call OUTPUT,$(SUBDIR_INSTALL)/$(1))

INSTALLER_BASE=$(call GOODIE,base-$(VERSION)-$(PLATFORM).sh)
WHEEL=$(call GOODIE,wheels/$(1))
WHEELS=$(call OUTPUT,wheels-gathered)
INSTALLER=$(call OUTPUT,timc-installer-$(VERSION)-$(PLATFORM).sh)

GOODIES = $(INSTALLER_BASE) $(WHEELS) $(call GOODIE,requirements.txt) $(call GOODIE,startshell)
GOODIES_GATHERED = $(call OUTPUT,goodies-gathered)

# $(DOCKERIMAGE): $(INSTALLER)
	# echo 'not yet implemented'
	# exit 1

$(INSTALLER): $(call OUTPUT,install.sh) $(GOODIES_GATHERED)
	test -d $(call GOODIE,tmp) && rmdir $(call GOODIE,tmp) || true
	cat $< <(cd $(call OUTPUT,) && tar cvf - $(SUBDIR_INSTALL)) >$@
	chmod +x $@
	test -f $@ -a $$(stat --format %s $@) -gt 1048576 || (rm -f $@ ; exit 1)

$(call OUTPUT,install.sh): install.sh $(call BOOTSTRAP,ready)
	test $$(stat --format="%s" $<) -lt $(SIZE_HEADER)
	mkdir -p $(@D)
	$(call CONCRETIZE,$<,$@)
	truncate --size=$(SIZE_HEADER) $@

$(GOODIES_GATHERED): $(GOODIES)
	touch $@
	
$(call GOODIE,requirements.txt): requirements.txt
	mkdir -p $(@D)
	cp $< $@

$(call GOODIE,startshell): startshell
	mkdir -p $(@D)
	cp $< $@
	
$(WHEELS): requirements.txt $(call BOOTSTRAP,ready)
	$(call IN_BOOTSTRAP,pip wheel --wheel-dir $(call WHEEL,) --no-cache-dir -r $<)
	touch $@

$(INSTALLER_BASE): $(call BOOTSTRAP,ready) $(call OUTPUT,construct.yaml)
	mkdir -p $(@D)
	$(call IN_BOOTSTRAP,constructor --output-dir $(@D) $(call OUTPUT,))

$(call OUTPUT,construct.yaml): construct.yaml
	$(call CONCRETIZE,$<,$@)

$(call BOOTSTRAP,ready): $(call BOOTSTRAP,deployed)
	$(call IN_BOOTSTRAP,conda install --override-channels $(foreach ch,$(CHANNELS),--channel $(ch)) --yes $(PKGS_BOOTSTRAP))
	touch $@

$(call BOOTSTRAP,deployed):
	$(MAKE) $(MINICONDA_INSTALLER)
	bash $(MINICONDA_INSTALLER) -bf -p $(call BOOTSTRAP,)
	touch $< $@
	rm $(MINICONDA_INSTALLER)

$(MINICONDA_INSTALLER):
	mkdir -p $(dir $@)
	curl -o $(MINICONDA_INSTALLER) https://repo.anaconda.com/miniconda/$(MINICONDA)

clean:
	test -d $(call BOOTSTRAP,) && $(call IN_BOOTSTRAP,constructor --clean) || exit 0
	rm -rf $(call OUTPUT,)
