SHELL := bash
SELF := $(realpath $(lastword $(MAKEFILE_LIST)))

ifdef PREFIX
BUILD_OPTS += --prefix='$(PREFIX)'
endif

ifeq ($(WITH_OPTIMIZATIONS),yes)
BUILD_OPTS += --enable-optimizations
endif

ifdef OPENSSL_DIR
PY_OPENSSL_BUILD_OPTS += --with-openssl='$(OPENSSL_DIR)'
endif

ifdef OPENSSL_RPATH
PY_OPENSSL_BUILD_OPTS += --with-openssl-rpath=$(OPENSSL_RPATH)
endif

ifeq ($(WITH_OPENSSL),yes)
BUILD_OPTS += $(PY_OPENSSL_BUILD_OPTS)
endif

ifeq ($(UPGRADE),yes)
PIP_OPTS += --upgrade $(UPGRADE)
endif

PIP_OPTS += $(PREFER_BINARY)
PIP_OPTS += $(BREAK_SYSTEM_PACKAGES)

.PHONY: deps-macos deps-alpine deps-ubuntu deps openssl python3 build requirements pip-init pip-clean venv-init venv-clean

deps-macos:

deps-alpine:
	apk add python3 py3-pip py3-virtualenv python3-dev zlib-dev libffi-dev bzip2-dev

deps-ubuntu:
	sudo apt install -y libbz2-dev libffi-dev zlib1g-dev python3-venv python3-dev

deps: deps-$(OS_NAME)

$(OPENSSL_DIR)/bin/openssl:
ifeq ($(WITH_OPENSSL),yes)
	[ -d $(DL) ] || mkdir -p $(DL)
	[ -f $(DL)/openssl-$(OPENSSL_VER).tar.gz ] || wget https://www.openssl.org/source/openssl-$(OPENSSL_VER).tar.gz --directory-prefix=$(DL)
	[ -d $(OPENSSL_DIR) ] || tar -zxf $(DL)/openssl-$(OPENSSL_VER).tar.gz -C $(DL)
	cd $(DL)/openssl-$(OPENSSL_VER) && ./config --prefix=$(OPENSSL_DIR) --openssldir=$(OPENSSL_DIR) no-ssl2
	cd $(DL)/openssl-$(OPENSSL_VER) && make
	cd $(DL)/openssl-$(OPENSSL_VER) && make install
endif

openssl: $(OPENSSL_DIR)/bin/openssl

$(DL)/$(TAR): $(OPENSSL_DIR)/bin/openssl
	[ -d $(DL) ] || mkdir -p $(DL)
	[ -f $(DL)/$(TAR) ] || cd $(DL) && wget $(DOWNLOAD_URL)
	touch $@

$(EXE): $(DL)/$(TAR)
	[ -d $(SRC) ] || tar -xf $(DL)/$(TAR) -C $(DL)
	[ -d $(PREFIX) ] || mkdir -p $(PREFIX)
	cd $(SRC) && \
		./configure $(BUILD_OPTS) && \
		make -j $(shell nproc)
	cd $(SRC) && sudo make altinstall
	touch $@

build: $(EXE)

$(PYTHON):
	make -f $(SELF) build

python3: openssl $(PYTHON)

$(VPYTHON):
	[ -d $(VENV_DIR) ] || mkdir -p $(VENV_DIR)
	$(PYTHON) -m venv --prompt='$(VENV_PROMT)' $(VENV_DIR)

venv-init: $(VPYTHON)

venv-clean:
	[ ! -d $(VENV_DIR) ] || rm -Rf $(VENV_DIR)

$(SITE_PACKAGES)/.upgrade: $(PYTHON)
	$(PYTHONUSERBASE) $(PIP) install $(PIP_OPTS) --upgrade $(UPGRADE)
	touch $@

$(SITE_PACKAGES)/.requirements: $(SITE_PACKAGES)/.upgrade $(REQUIREMENTS)
ifdef REQUIREMENTS
	$(PYTHONUSERBASE) $(PIP) install $(PIP_OPTS) -r $(REQUIREMENTS)
endif
	cp -f $(REQUIREMENTS) $(SITE_PACKAGES)/.requirements
	touch $@

requirements: $(SITE_PACKAGES)/.requirements

pip-init: requirements

pip-clean:
	$(PIP) uninstall -r $(REQUIREMENTS) -y
	[ ! -f $(SITE_PACKAGES)/.package-* ] || rm -fv $(SITE_PACKAGES)/.package-*
	[ ! -f $(SITE_PACKAGES)/.requirements ] || rm -fv $(SITE_PACKAGES)/.requirements
	[ ! -f $(SITE_PACKAGES)/.upgrade ] || rm -fv $(SITE_PACKAGES)/.upgrade
