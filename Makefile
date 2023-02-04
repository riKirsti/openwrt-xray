include $(TOPDIR)/rules.mk

PKG_NAME:=openwrt-xray
PKG_VERSION:=1.7.3
PKG_RELEASE:=1

PKG_LICENSE:=MPLv2
PKG_LICENSE_FILES:=LICENSE
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/XTLS/Xray-core.git
PKG_SOURCE_VERSION=main
PKG_MIRROR_HASH:=skip
PKG_SOURCE_SUBDIR=Xray-core-$(PKG_VERSION)
PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

GO_PKG:=github.com/XTLS/Xray-core

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/../feeds/packages/lang/golang/golang-package.mk

define Package/$(PKG_NAME)
	SECTION:=Custom
	CATEGORY:=Extra packages
	TITLE:=Xray-core
	DEPENDS:=$(GO_ARCH_DEPENDS)
	PROVIDES:=xray-core
endef

define Package/$(PKG_NAME)/description
	Xray-core bare bones binary (compiled without cgo)
endef

define Package/$(PKG_NAME)/config
menu "Xray Configuration"
	depends on PACKAGE_$(PKG_NAME)
	
config PACKAGE_XRAY_COMPRESS_UPX
	bool "Compress executable files with UPX"
	default y

config PACKAGE_XRAY_ENABLE_GOPROXY_IO
	bool "Use goproxy.io to speed up module fetching (recommended for some network situations)"
	default n

endmenu
endef

USE_GOPROXY:=
ifdef CONFIG_PACKAGE_XRAY_ENABLE_GOPROXY_IO
	USE_GOPROXY:=GOPROXY=https://goproxy.io,direct
endif

MAKE_PATH:=$(GO_PKG_WORK_DIR_NAME)/build/src/$(GO_PKG)
MAKE_VARS += $(GO_PKG_VARS)

define Build/Patch
	$(CP) $(PKG_BUILD_DIR)/../Xray-core-$(PKG_VERSION)/* $(PKG_BUILD_DIR)
	$(Build/Patch/Default)
endef

define Build/Compile
	cd $(PKG_BUILD_DIR); $(GO_PKG_VARS) $(USE_GOPROXY) go build -o $(PKG_INSTALL_DIR)/bin/xray -trimpath -ldflags "-s -w -buildid=" ./main; 
ifeq ($(CONFIG_PACKAGE_XRAY_COMPRESS_UPX),y)
	rm -rf $(DL_DIR)/upx-4.0.2.tar.xz
	wget -q https://github.com/upx/upx/releases/download/v4.0.2/upx-4.0.2-amd64_linux.tar.xz -O $(DL_DIR)/upx-4.0.2.tar.xz
	rm -rf $(BUILD_DIR)/upx
	mkdir -p $(BUILD_DIR)/upx
	xz -d -c $(DL_DIR)/upx-4.0.2.tar.xz | tar -x -C $(BUILD_DIR)/upx
	chmod +x $(BUILD_DIR)/upx/upx-4.0.2-amd64_linux/upx
	$(BUILD_DIR)/upx/upx-4.0.2-amd64_linux/upx --lzma --best $(PKG_INSTALL_DIR)/bin/xray
endif
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/bin/xray $(1)/usr/bin/xray
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
