VERSION = 2025.02
PLATFORM = $(shell uname -s)
ARCH = $(shell uname -m)

BOOTSTRAP = /out/bootstrap
bootstrapped = source $(BOOTSTRAP)/bin/activate $(BOOTSTRAP) && $1

TIMC_INSTALLER = timc-installer-$(VERSION)
DIR_GOODIES = /out/$(TIMC_INSTALLER)
ARCH_INSTALLER = /out/$(TIMC_INSTALLER).tar
BASE = $(DIR_GOODIES)/base-$(VERSION)-$(PLATFORM)-$(ARCH).sh
SCRIPT_INSTALLER = /out/$(TIMC_INSTALLER).sh
SIZE_UPSTALL = 6144

STAGING = /out/staging
staged = source $(STAGING)/bin/activate $(STAGING) && $1

.PHONY: installer
installer: $(SCRIPT_INSTALLER)
$(SCRIPT_INSTALLER): /out/upstall-run.large $(ARCH_INSTALLER)
	cat $^ >$@
	chmod +x $@

/out/upstall-run.large: /src/upstall-run.sh
	test "$$(stat --format='%s' $<)" -lt $(SIZE_UPSTALL)
	cp $< $@
	truncate --size=$(SIZE_UPSTALL) $@

$(ARCH_INSTALLER): $(DIR_GOODIES)/complete
	cd $(@D); tar cvf $@ $$(basename $(<D))

$(DIR_GOODIES)/complete: $(BASE) $(DIR_GOODIES)/wheels $(DIR_GOODIES)/requirements.txt $(DIR_GOODIES)/dmp-cache.zip $(DIR_GOODIES)/hfmodels
	touch $@

.PHONY: base
base: $(BASE)
$(BASE): /src/construct.yaml
	rm -f $@
	mkdir -p $(@D)
	$(call bootstrapped,constructor --output-dir $(@D) $(<D))


.PHONY: requirements
requirements: $(DIR_GOODIES)/requirements.txt
$(DIR_GOODIES)/requirements.txt: /src/requirements.txt
	sed 's~^git+https://github.com/tutteinstitute/~~;s~\.git$~~~;' $< >$@
	
.PHONY: wheels
wheels: $(DIR_GOODIES)/wheels
$(DIR_GOODIES)/wheels: $(STAGING)/init /src/requirements.txt
	mkdir -p $(@D)
	rm -f $(@D)/*.whl
	$(call staged,pip wheel -w $(@D) -r /src/requirements.txt)
	touch $@

.PHONY: staging-init
staging-init: $(STAGING)/init
$(STAGING)/init: $(BASE)
	rm -rf $(@D)
	sh $< -b -f -p $(@D)
	touch $@

.PHONY: staging-final
staging-final: $(STAGING)/final
$(STAGING)/final: $(DIR_GOODIES)/requirements.txt $(DIR_GOODIES)/wheels
	$(call staged,pip install --no-index --find-links $(DIR_GOODIES) -r $<)
	touch $@

.PHONY: dmpcache
dmpcache: $(DIR_GOODIES)/dmp-cache.zip
$(DIR_GOODIES)/dmp-cache.zip: $(STAGING)/final
	rm -f $@
	$(call staged,dmp_offline_cache --export $@)

.PHONY: hfmodels
hfmodels: $(DIR_GOODIES)/hfmodels
$(DIR_GOODIES)/hfmodels: $(STAGING)/final /src/getmodels.py
	rm -rf $$HOME/.cache/huggingface $(@D)/huggingface-cache
	$(call staged,python /src/getmodels.py)
	mv $$HOME/.cache/huggingface $(@D)/huggingface-cache
	# mkdir $(@D)/huggingface-cache && touch $(@D)/huggingface-cache/mites
	touch $@
