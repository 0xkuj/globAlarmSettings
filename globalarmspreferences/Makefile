ARCHS = arm64 arm64e
include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = GlobalarmsPreferences
GlobalarmsPreferences_FILES = GAPRootListController.m
GlobalarmsPreferences_INSTALL_PATH = /Library/PreferenceBundles
GlobalarmsPreferences_FRAMEWORKS = UIKit
GlobalarmsPreferences_PRIVATE_FRAMEWORKS = Preferences
GlobalarmsPreferences_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/GlobalarmsPreferences.plist$(ECHO_END)
