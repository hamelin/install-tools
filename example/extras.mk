$(DIR_ARTIFACTS)/font-js-cache.zip: $(BOOTSTRAP)/bin/dmp_offline_cache
	mkdir -p $(@D)
	$(FROM_BOOTSTRAP) && dmp_offline_cache --export $@ --yes

$(BOOTSTRAP)/bin/dmp_offline_cache:
	$(FROM_BOOTSTRAP) && pip install --no-index --find-links $(DIR_ARTIFACTS)/wheels datamapplot
