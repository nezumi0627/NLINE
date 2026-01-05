TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = LINE

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NLINE

NLINE_FILES = Tweak.x
NLINE_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
