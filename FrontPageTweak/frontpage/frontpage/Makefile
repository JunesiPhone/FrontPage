include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = frontpage
frontpage_FILES = FPRootListController.m
frontpage_INSTALL_PATH = /Library/PreferenceBundles
frontpage_FRAMEWORKS = UIKit
frontpage_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/frontpage.plist$(ECHO_END)
