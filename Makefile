ARCHS = arm64 arm64e
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GlobAlarmSettings
GlobAlarmSettings_FILES = Tweak.xm
GlobAlarmSettings_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += globalarmspreferences
include $(THEOS_MAKE_PATH)/aggregate.mk
