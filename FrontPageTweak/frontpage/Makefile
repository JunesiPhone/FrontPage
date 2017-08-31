export THEOS_DEVICE_IP=192.168.2.16
export TARGET = iphone:9.2:9.2



include $(THEOS)/makefiles/common.mk

TWEAK_NAME = frontpage
frontpage_FILES = Tweak.xm
frontpage_PRIVATE_FRAMEWORKS = GraphicsServices Preferences
frontpage_LDFLAGS = -lAccessibility
frontpage_CFLAGS += -I.



include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += frontpage
include $(THEOS_MAKE_PATH)/aggregate.mk
