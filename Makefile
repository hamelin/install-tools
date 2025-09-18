include config.mk

ROOT_PKG = timc_vector_toolkit
DIST = $(addprefix dist/,$(1))
PKG = $(call DIST,$(ROOT_PKG)-$(VERSION).tar.gz $(ROOT_PKG)-$(VERSION)-py3-none-any.whl)
PUBLISHED = $(addsuffix .published,$(1))
PKG_PUBLISHED = $(call PUBLISHED,$(PKG))

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
TASK = $(GOODIE)/tasks
TARGET = $(OUTPUT)/target

INSTALLER_BASE=$(GOODIE)/base-$(VERSION)-$(PLATFORM).sh
WHEEL=$(GOODIE)/wheels/$(1)
WHEELS=$(OUTPUT)/wheels-gathered
INSTALLER=$(OUTPUT)/timc-installer-$(VERSION)-py$(PYTHON_VERSION)-$(PLATFORM).sh

GOODIES = $(INSTALLER_BASE) $(WHEELS) $(GOODIE)/requirements.txt $(GOODIE)/startshell
GOODIES += $(foreach task,$(wildcard local/*.sh),$(TASK)/$(notdir $(task)))
GOODIES_GATHERED = $(OUTPUT)/goodies-gathered


# -------------------------------------------------------------------

.PHONY: help
help:
	@cat help-makefile.txt

.PHONY: pkg.build
pkg.build: $(PKG)

$(PKG) &: config.mk
	uv version $(VERSION)
	git diff --exit-code pyproject.toml || uv lock --upgrade
	uv build

.PHONY: pkg.publish
pkg.publish: $(PKG_PUBLISHED)

$(PKG_PUBLISHED) &: $(PKG)
	@test -n "$$UV_PUBLISH_TOKEN" || (echo "UV_PUBLISH_TOKEN undefined, so cannot publish."; false)
	uv publish $(PKG)
	touch $(PKG_PUBLISHED)

.PHONY: pkg.clean
pkg.clean:
	rm -rf dist

.PHONY: docker.build
docker.build: config.mk pkg.publish
	docker build . \
		--tag $(call TAG,vector-toolkit,$(VERSION)) \
		--build-arg IMAGE_BASE=$(IMAGE_BASE) \
		--build-arg VERSION=$(VERSION) \
		--build-arg PYTHON_VERSION=$(PYTHON_VERSION)
	docker tag $(call TAG,vector-toolkit,$(VERSION)) $(call TAG,vector-toolkit,latest)

.PHONY: docker.publish
docker.publish: docker.build
	docker push --all-tags $(call TAG,vector-toolkit,)

.PHONY: docker.clean
docker.clean:
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

.PHONY: ls-goodies
ls-goodies:
	@echo $(GOODIES) | xargs -n1

$(GOODIES_GATHERED): $(GOODIES)
	touch $@

$(TARGET)/ready: $(GOODIE)/requirements.txt $(INSTALLER_BASE) $(WHEELS) $(GOODIE)/requirements.txt
	@rm -f $@
	$(INSTALLER_BASE) -b -p $(@D)
	$(call IN_ENV,$(TARGET)) && pip install --no-index --find-links $(WHEEL) --requirement $<
	touch $@

$(TASK)/%.sh: local/%.sh
	mkdir -p $(@D)
	$(call CONCRETIZE,$<,$@)

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

-include $(sort $(wildcard local/*.mk))

$(MINICONDA_INSTALLER):
	mkdir -p $(@D)
	curl -o $@ https://repo.anaconda.com/miniconda/$(MINICONDA) && chmod +x $@ || rm $@

clean:
	test -d $(CONSTRUCTOR) && $(call IN_ENV,$(CONSTRUCTOR)) && constructor --clean || exit 0
	rm -rf $(OUTPUT)

veryclean: clean
	rm -rf $(DIR_MINICONDA)
