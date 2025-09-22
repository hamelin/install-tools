include config.mk
SHELL = /bin/bash

ROOT_PKG = timc_vector_toolkit
DIST = $(addprefix dist/,$(1))
PKG = $(call DIST,$(ROOT_PKG)-$(VERSION).tar.gz $(ROOT_PKG)-$(VERSION)-py3-none-any.whl)
PUBLISHED = $(addsuffix .published,$(1))
PKG_PUBLISHED = $(call PUBLISHED,$(PKG))

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


# --- timc-vector-toolkit Python package -------------------------------------

.PHONY: help
help:
	@cat help-makefile.txt

.PHONY: pkg.build
pkg.build: $(PKG)

$(PKG) &: config.mk $(wildcard src/timc_vector_toolkit/*)
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


# --- Docker image -----------------------------------------------------------

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


# --- Offline installer ------------------------------------------------------

out/%.sh: out/%-install.sh $(call COMMON_ARTIFACTS,%) out/%.wheels out/%.extras
	cat $< <(cd out && tar cf - $*-artifacts) >$@
	chmod +x $@
	test -f $@ -a $$(stat --format %s $@) -gt 1048576 || (rm -f $@ ; exit 1)

out/%.extras: %/extras.mk $(wildcard %/tasks/*.sh)
	$(MAKE) -f $< SHELL=/bin/bash DIR_ARTIFACTS="$(call DIR_ARTIFACTS,$*)" BOOTSTRAP="out/$*-bootstrap" FROM_BOOTSTRAP="$(call FROM_BOOTSTRAP,$*)"
	mkdir -p $(call DIR_ARTIFACTS,$*)/tasks
	cp -v $*/tasks/*.sh $(call DIR_ARTIFACTS,$*)/tasks
	touch $@
.PRECIOUS: out/%.extras

out/%-install.sh: install.sh %/python_version $(CONSTRUCTOR)
	mkdir -p $(@D)
	$(call RESOLVE,$*) <$< >$@
.PRECIOUS: out/%-install.sh
	
.PHONY: out/%/common-artifacts
out/%/common-artifacts: $(call COMMON_ARTIFACTS,%)
	@true

$(call DIR_ARTIFACTS,%)/requirements.txt: %/requirements.txt
	mkdir -p $(@D)
	cp $< $@
.PRECIOUS: $(call DIR_ARTIFACTS,%)/requirements.txt

$(call DIR_ARTIFACTS,%)/startshell: startshell
	mkdir -p $(@D)
	cp $< $@
.PRECIOUS: $(call DIR_ARTIFACTS,%)/startshell
		
$(call DIR_ARTIFACTS,%)/enable-python.sh: enable-python.sh
	mkdir -p $(@D)
	cp $< $@
.PRECIOUS: $(call DIR_ARTIFACTS,%)/enable-python.sh

out/%.wheels: %/requirements.txt $(call BOOTSTRAP_PIP,%)
	mkdir -p $(call DIR_ARTIFACTS,$*)
	$(call FROM_BOOTSTRAP,$*) && $(call BOOTSTRAP_PIP,$*) wheel --wheel-dir $(call DIR_ARTIFACTS,$*)/wheels --no-cache-dir -r $<
	touch $@
.PRECIOUS: out/%.wheels

.PHONY: out/%/bootstrap
out/%/bootstrap: $(call BOOTSTRAP_PIP,%)
	
$(call BOOTSTRAP_PIP,%): %/bootstrap.yaml %/python_version $(CONSTRUCTOR)
	$(call RESOLVE,$*) <$< >out/$*-bootstrap.yaml
	$(FROM_GROUND) && conda env create --prefix $(call BOOTSTRAP,$*) --file out/$*-bootstrap.yaml --yes
.PRECIOUS: $(call BOOTSTRAP_PIP,%)

$(call DIR_ARTIFACTS,%)/install-python.sh: %/construct.yaml %/python_version $(CONSTRUCTOR)
	mkdir -p $(@D)
	$(call RESOLVE,$*) <$< >out/$*-construct.yaml
	DIRTEMP=$$(mktemp -d) \
		&& trap "rm -rf \"$$DIRTEMP\"" EXIT \
		&& $(FROM_GROUND) \
		&& constructor --output-dir $$DIRTEMP --config-file=$*-construct.yaml out \
		&& cat "$$DIRTEMP"/*.sh >$@ \
		|| rm -f $@
.PRECIOUS: $(call DIR_ARTIFACTS,%)/install-python.sh

$(CONSTRUCTOR): $(MINICONDA_INSTALLER)
	./$(MINICONDA_INSTALLER) -bf -p $(dir $(@D))
	$(FROM_GROUND) \
		$(foreach ch,main r,&& conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/$(ch)) \
		&& conda install --override-channels --channel defaults --yes constructor

$(MINICONDA_INSTALLER):
	mkdir -p $(@D)
	curl -o $@ https://repo.anaconda.com/miniconda/$(MINICONDA) && chmod +x $@ || rm $@

.PHONY: testbed.build
testbed.build:
	docker build --file Dockerfile.testbed $(and $(TEST_BASE),--build-arg TEST_BASE=$(TEST_BASE)) -t testbed-$(or $(TEST_BASE),ubuntu) .

.PHONY: testbed.run
testbed.run: testbed.build $(INSTALLER)
	chmod a+rX $(OUTPUT)/
	docker run -ti --rm --mount type=bind,src=$$(pwd)/$(OUTPUT),dst=/ext testbed-$(or $(TEST_BASE),ubuntu)
	
clean:
	test -f $(CONSTRUCTOR) && $(FROM_GROUND) && constructor --clean || exit 0
	rm -rf out

veryclean: clean
	rm -rf $(DIR_MINICONDA)
