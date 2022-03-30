.PHONY: prepare

prepare:
	$(MAKE) -C antora-bundle bundle
	$(MAKE) -C site-generator setup
