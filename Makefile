NAME=cmake
VERSION=3.8.2
ITERATION=1.lru
PREFIX=/usr/local
LICENSE=BSD-3-Clause
VENDOR="Kitware"
MAINTAINER="Ryan Parman"
DESCRIPTION="CMake is an open-source, cross-platform family of tools designed to build, test and package software."
URL=https://cmake.org
ACTUALOS=$(shell osqueryi "select * from os_version;" --json | jq -r ".[].name")
EL=$(shell if [[ "$(ACTUALOS)" == "Amazon Linux AMI" ]]; then echo alami; else echo el; fi)
RHEL=$(shell [[ -f /etc/centos-release ]] && rpm -q --queryformat '%{VERSION}' centos-release)

#-------------------------------------------------------------------------------

all: info clean install-deps compile install-tmp package move

#-------------------------------------------------------------------------------

.PHONY: info
info:
	@ echo "NAME:        $(NAME)"
	@ echo "VERSION:     $(VERSION)"
	@ echo "ITERATION:   $(ITERATION)"
	@ echo "PREFIX:      $(PREFIX)"
	@ echo "LICENSE:     $(LICENSE)"
	@ echo "VENDOR:      $(VENDOR)"
	@ echo "MAINTAINER:  $(MAINTAINER)"
	@ echo "DESCRIPTION: $(DESCRIPTION)"
	@ echo "URL:         $(URL)"
	@ echo "OS:          $(ACTUALOS)"
	@ echo "EL:          $(EL)"
	@ echo "RHEL:        $(RHEL)"
	@ echo " "

#-------------------------------------------------------------------------------

.PHONY: clean
clean:
	rm -Rf /tmp/installdir* cmake* CMake*

#-------------------------------------------------------------------------------

.PHONY: install-deps
install-deps:

	yum -y install \
		gcc \
		gcc-c++ \
	;

#-------------------------------------------------------------------------------

.PHONY: compile
compile:
	git clone -q -b v$(VERSION) https://github.com/Kitware/CMake.git
	cd CMake && \
		./bootstrap && \
		make \
	;

#-------------------------------------------------------------------------------

.PHONY: install-tmp
install-tmp:
	mkdir -p /tmp/installdir-$(NAME)-$(VERSION);
	cd CMake && \
		make install DESTDIR=/tmp/installdir-$(NAME)-$(VERSION);

#-------------------------------------------------------------------------------

.PHONY: package
package:

	# Main package
	fpm \
		-f \
		-s dir \
		-t rpm \
		-n $(NAME) \
		-v $(VERSION) \
		-C /tmp/installdir-$(NAME)-$(VERSION) \
		-m $(MAINTAINER) \
		--replaces cmake \
		--replaces cmake3 \
		--iteration $(ITERATION) \
		--license $(LICENSE) \
		--vendor $(VENDOR) \
		--prefix / \
		--url $(URL) \
		--description $(DESCRIPTION) \
		--rpm-defattrdir 0755 \
		--rpm-digest md5 \
		--rpm-compression gzip \
		--rpm-os linux \
		--rpm-changelog CHANGELOG.txt \
		--rpm-dist $(EL)$(RHEL) \
		--rpm-auto-add-directories \
		usr/local/bin \
		usr/local/share \
	;

	# Documentation package
	fpm \
		-f \
		-d "$(NAME) = $(VERSION)-$(ITERATION).$(EL)$(RHEL)" \
		-s dir \
		-t rpm \
		-n $(NAME)-doc \
		-v $(VERSION) \
		-C /tmp/installdir-$(NAME)-$(VERSION) \
		-m $(MAINTAINER) \
		--replaces cmake-doc \
		--replaces cmake3-doc \
		--iteration $(ITERATION) \
		--license $(LICENSE) \
		--vendor $(VENDOR) \
		--prefix / \
		--url $(URL) \
		--description $(DESCRIPTION) \
		--rpm-defattrdir 0755 \
		--rpm-digest md5 \
		--rpm-compression gzip \
		--rpm-os linux \
		--rpm-changelog CHANGELOG.txt \
		--rpm-dist $(EL)$(RHEL) \
		--rpm-auto-add-directories \
		usr/local/doc \
	;

#-------------------------------------------------------------------------------

.PHONY: move
move:
	[[ -d /vagrant/repo ]] && mv *.rpm /vagrant/repo/
