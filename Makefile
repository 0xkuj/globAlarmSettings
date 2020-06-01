include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GlobAlarmSettings
GlobAlarmSettings_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += globalarmspreferences
include $(THEOS_MAKE_PATH)/aggregate.mk
