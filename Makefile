SHELL = /bin/bash


.PHONY: help
help:
	@cat help-makefile.txt


# --- timc-vector-toolkit Python package -------------------------------------

ROOT_PKG = timc_vector_toolkit
DIST = $(addprefix dist/,$(1))
PKG_VERSION = $(shell uv version --short)
PKG = $(call DIST,$(ROOT_PKG)-$(PKG_VERSION).tar.gz $(ROOT_PKG)-$(PKG_VERSION)-py3-none-any.whl)
PUBLISHED = $(addsuffix .published,$(1))
PKG_PUBLISHED = $(call PUBLISHED,$(PKG))

.PHONY: pkg.build
pkg.build: $(PKG)

$(PKG) &: $(wildcard src/timc_vector_toolkit/*)
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


# --- Docker image -----------------------------------------------------------

IMAGE_VERSION ?= $(shell date +%Y%m%d)
PYTHON_VERSION ?= 3.13  # Latest stable Python where TIMC tools work without issue.

.PHONY: docker.build
docker.build:
	docker build . \
		--tag tutteinstitute/vector-toolkit:$(IMAGE_VERSION)
	docker tag tutteinstitute/vector-toolkit:$(IMAGE_VERSION) tutteinstitute/vector-toolkit:latest

.PHONY: docker.publish
docker.publish: docker.build
	docker push --all-tags tutteinstitute/vector-toolkit

.PHONY: docker.clean
docker.clean:
	docker images --format '{{.Repository}}:{{.Tag}}' | grep 'tutteinstitute/vector_toolkit' | xargs --max-args=1 --no-run-if-empty docker image rm


# --- Offline installers -----------------------------------------------------

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
	$(call BOOTSTRAP_PIP,%)
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
