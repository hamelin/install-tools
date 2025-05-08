include config.mk

MINICONDA = Miniconda3-latest-$(PLATFORM).sh
DIR_MINICONDA = miniconda
MINICONDA_INSTALLER = $(DIR_MINICONDA)/$(MINICONDA)

BASE = $(OUTPUT)/base
CONSTRUCTOR = $(BASE)
BOOTSTRAP = $(OUTPUT)/bootstrap
IN_ENV = source $(BASE)/bin/activate && conda activate $(1)

CONCRETIZE = mkdir -p $(dir $(2)) && $(call IN_ENV,base) && python -c 'import sys; print(sys.stdin.read().format(platform="$(PLATFORM)", version="$(VERSION)", after_header=str($(SIZE_HEADER) + 1), python_version="$(PYTHON_VERSION)", dir_installer="./$(SUBDIR_INSTALL)"))' <$(1) >$(2) || (rm -f $(2); exit 1)
SUBDIR_INSTALL = timc-installer-py$(PYTHON_VERSION)-${VERSION}
GOODIE = $(OUTPUT)/$(SUBDIR_INSTALL)

INSTALLER_BASE=$(GOODIE)/base-$(VERSION)-$(PLATFORM).sh
WHEEL=$(GOODIE)/wheels/$(1)
WHEELS=$(OUTPUT)/wheels-gathered
INSTALLER=$(OUTPUT)/timc-installer-$(VERSION)-py$(PYTHON_VERSION)-$(PLATFORM).sh

GOODIES = $(INSTALLER_BASE) $(WHEELS) $(GOODIE)/requirements.txt $(GOODIE)/startshell
GOODIES_GATHERED = $(OUTPUT)/goodies-gathered

IMAGES = data-exploration data-science


# -------------------------------------------------------------------

.PHONY: all
all: installer dockerimages

.PHONY: dockerimages
dockerimages: $(foreach image,$(IMAGES),build/$(image))

build/%:
	docker build . \
		--target $(@F) \
		--tag $(call TAG,$(@F),$(VERSION)) \
		--build-arg IMAGE_BASE=$(IMAGE_BASE) \
		--build-arg VERSION=$(VERSION) \
		--build-arg PYTHON_VERSION=$(PYTHON_VERSION)
	docker tag $(call TAG,$(@F),$(VERSION)) $(call TAG,$(@F),latest)

.PHONY: dockerpush
dockerpush: $(foreach image,$(IMAGES),push/$(image))

push/%:
	docker push --all-tags $(call TAG,$(@F),)

.PHONY: dockerclean
dockerclean:
	docker images --format '{{.Repository}}:{{.Tag}}' | grep '$(call TAG,,)' | xargs --max-args=1 --no-run-if-empty docker image rm

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
	
$(GOODIE)/requirements.txt: exploration.txt
	mkdir -p $(@D)
	cp $< $@

$(GOODIE)/startshell: startshell
	mkdir -p $(@D)
	cp $< $@
	
$(WHEELS): exploration.txt $(BOOTSTRAP)/ready
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

clean:
	test -d $(CONSTRUCTOR) && $(call IN_ENV,$(CONSTRUCTOR)) && constructor --clean || exit 0
	rm -rf $(OUTPUT)

veryclean: clean
	rm -rf $(DIR_MINICONDA)
