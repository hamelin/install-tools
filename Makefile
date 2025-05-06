include config.mk

MINICONDA = Miniconda3-latest-$(PLATFORM).sh
DIR_MINICONDA = miniconda
MINICONDA_INSTALLER = $(DIR_MINICONDA)/$(MINICONDA)

BASE = $(OUTPUT)/base
CONSTRUCTOR = $(BASE)
BOOTSTRAP = $(OUTPUT)/bootstrap
IN_ENV = source $(BASE)/bin/activate && conda activate $(1)

CONCRETIZE = $(call IN_ENV,base) && python -c 'import sys; print(sys.stdin.read().format(platform="$(PLATFORM)", version="$(VERSION)", after_header=str($(SIZE_HEADER) + 1), python_version="$(PYTHON_VERSION)", dir_installer="./$(SUBDIR_INSTALL)"))' <$(1) >$(2) || (rm -f $(2); exit 1)
SUBDIR_INSTALL = timc-installer-py$(PYTHON_VERSION)-${VERSION}
GOODIE = $(OUTPUT)/$(SUBDIR_INSTALL)

INSTALLER_BASE=$(GOODIE)/base-$(VERSION)-$(PLATFORM).sh
WHEEL=$(GOODIE)/wheels/$(1)
WHEELS=$(OUTPUT)/wheels-gathered
INSTALLER=$(OUTPUT)/timc-installer-$(VERSION)-py$(PYTHON_VERSION)-$(PLATFORM).sh
DOCKERIMAGE = $(OUTPUT)/docker-image-$(VERSION)
TAG = data-exploration:$(VERSION)-py$(PYTHON_VERSION)

GOODIES = $(INSTALLER_BASE) $(WHEELS) $(GOODIE)/requirements.txt $(GOODIE)/startshell
GOODIES_GATHERED = $(OUTPUT)/goodies-gathered


# -------------------------------------------------------------------


$(DOCKERIMAGE): $(INSTALLER) Dockerfile
	docker build --build-arg installer=$< --tag $(TAG) .
	touch $@

.PHONY: installer
installer: $(INSTALLER)

$(INSTALLER): $(OUTPUT)/install.sh $(GOODIES_GATHERED)
	test -d $(GOODIE)/tmp && rmdir $(GOODIE)/tmp || true
	cat $< <(cd $(OUTPUT) && tar cvf - $(SUBDIR_INSTALL)) >$@
	chmod +x $@
	test -f $@ -a $$(stat --format %s $@) -gt 1048576 || (rm -f $@ ; exit 1)

$(OUTPUT)/install.sh: install.sh $(BOOTSTRAP)/ready config.mk
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
	$(call IN_ENV,$(BOOTSTRAP)) && pip wheel --wheel-dir $(WHEEL) --no-cache-dir -r $<
	touch $@

$(INSTALLER_BASE): $(OUTPUT)/construct.yaml $(BASE)/ready
	mkdir -p $(@D)
	$(call IN_ENV,$(CONSTRUCTOR)) && constructor --output-dir $(@D) $(<D)

$(OUTPUT)/construct.yaml: construct.yaml $(CONSTRUCTOR)/ready config.mk
	mkdir -p $(@D)
	$(call CONCRETIZE,$<,$@)

$(BOOTSTRAP)/ready: $(OUTPUT)/bootstrap.yaml $(BASE)/ready
	$(call IN_ENV,base) && conda env create --prefix $(@D) --file $< --yes
	touch $@

$(OUTPUT)/bootstrap.yaml: bootstrap.yaml config.mk $(BASE)/ready
	mkdir -p $(@D)
	$(call CONCRETIZE,$<,$@)

$(BASE)/ready: $(MINICONDA_INSTALLER)
	./$(MINICONDA_INSTALLER) -bf -p $(@D)
	$(call IN_ENV,base) && conda install --override-channels --channel defaults --yes constructor
	touch $@

$(MINICONDA_INSTALLER):
	mkdir -p $(@D)
	curl -o $@ https://repo.anaconda.com/miniconda/$(MINICONDA) && chmod +x $@ || rm $@

cleanimage:
	docker image rm $(TAG) || true

clean: cleanimage
	test -d $(CONSTRUCTOR) && $(call IN_ENV,$(CONSTRUCTOR)) && constructor --clean || exit 0
	rm -rf $(OUTPUT)

veryclean: clean
	rm -rf $(DIR_MINICONDA)
