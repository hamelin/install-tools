GOODIES += $(GOODIE)/font-js-cache.zip

$(GOODIE)/font-js-cache.zip: $(TARGET)/ready
	mkdir -p $(@D)
	$(call IN_ENV,$(TARGET)) && dmp_offline_cache --export $@ --yes
