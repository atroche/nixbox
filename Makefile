BUILDER ?= qemu.qemu
VERSION ?= 23.05
ARCH ?= x86_64
REPO ?= nixos/nixos
all: help

help: ## This help
	@find . -name Makefile -o -name "*.mk" | xargs -n1 grep -hE '^[a-z0-9\-]+:.* ##' | sed 's/\: .*##/:/g' | sort | column  -ts':'

version:
	@echo "Build for ${ARCH} architecture and using the ${VERSION} NixOS iso version"

build: version nixos.pkr.hcl ## [BUILDER] [ARCH] [VERSION] Build packer image
	@packer build \
	-var arch=${ARCH} \
	-var builder="${BUILDER}" \
	-var version=${VERSION} \
	-var iso_checksum="$(shell curl -sL https://channels.nixos.org/nixos-${VERSION}/latest-nixos-minimal-${ARCH}-linux.iso.sha256 | grep -Eo '^[0-9a-z]{64}')" \
	--only=${BUILDER} \
	nixos.pkr.hcl

build-all: ## [BUILDER] [VERSION] Build packer image
	@${MAKE} BUILDER=${BUILDER} VERSION=${VERSION} ARCH=x86_64 build
	@${MAKE} BUILDER=${BUILDER} VERSION=${VERSION} ARCH=i686 build

vagrant-plugin:
	@vagrant plugin list | grep vagrant-nixos-plugin || vagrant plugin install vagrant-nixos-plugin

vagrant-add: vagrant-plugin ## Add vagrant box
	@test -f nixos-${VERSION}-${BUILDER}-${ARCH}.box && ARCH=${ARCH} vagrant box add --force nixbox-${ARCH} nixos-${VERSION}-${BUILDER}-${ARCH}.box	

vagrant-up: ## Try builded vagrant box
	@ARCH="${ARCH}" vagrant up

vagrant-ssh: ## Connect to vagrant box
	@ARCH="${ARCH}" vagrant ssh

vagrant-destroy: ## Destroy vagrant box
	@ARCH="${ARCH}" vagrant destroy

vagrant-push: vagrant-plugin ## Push builded vagrant box
	@test -f nixos-${VERSION}-${BUILDER}-${ARCH}.box && ARCH="${ARCH}" vagrant cloud publish \
	--force \
	--release \
	--no-private \
	--short-description "NixOS ${VERSION}" \
	${REPO}-${VERSION} ${VERSION} virtualbox nixos-${VERSION}-${BUILDER}-${ARCH}.box
