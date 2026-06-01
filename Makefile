export FINALPACKAGE = 1

SCHEME ?= rootless
ifeq ($(SCHEME), rootful)
  export THEOS_PACKAGE_SCHEME =
else
  export THEOS_PACKAGE_SCHEME = rootless
endif

TARGET = iphone:clang:16.5:15.0
ARCHS  = arm64 arm64e

include $(THEOS)/makefiles/common.mk

# ─────────────────────────────────────────────────────────────────────────────
#  1. ANA TWEAK — SpringBoard
#     SpringBoard.xm + LockScreen.xm + Folder.xm + mevcut TweakSpring/UI
# ─────────────────────────────────────────────────────────────────────────────
TWEAK_NAME = ProudLockX
ProudLockX_FILES    = TweakSpring.xm TweakUI.xm SpringBoard.xm LockScreen.xm Folder.xm
ProudLockX_CFLAGS   = -fobjc-arc -DTHEOS_LEAN_AND_MEAN
ProudLockX_FRAMEWORKS = UIKit CoreGraphics QuartzCore AudioToolbox

# ─────────────────────────────────────────────────────────────────────────────
#  2. SETTINGS TWEAK — Preferences + MobileAssetd
# ─────────────────────────────────────────────────────────────────────────────
TWEAK_NAME += ProudLockXSettings
ProudLockXSettings_FILES  = TweakSettings.xm
ProudLockXSettings_CFLAGS = -fobjc-arc -DTHEOS_LEAN_AND_MEAN
ProudLockXSettings_FRAMEWORKS = UIKit

# ─────────────────────────────────────────────────────────────────────────────
#  3. KAMERA TWEAK — com.apple.camera
# ─────────────────────────────────────────────────────────────────────────────
TWEAK_NAME += ProudLockXCamera
ProudLockXCamera_FILES  = Camera.xm
ProudLockXCamera_CFLAGS = -fobjc-arc -DTHEOS_LEAN_AND_MEAN
ProudLockXCamera_FRAMEWORKS = UIKit AVFoundation

# ─────────────────────────────────────────────────────────────────────────────
#  4. SAFARİ + CC TWEAK
# ─────────────────────────────────────────────────────────────────────────────
TWEAK_NAME += ProudLockXSafariCC
ProudLockXSafariCC_FILES  = SafariCC.xm
ProudLockXSafariCC_CFLAGS = -fobjc-arc -DTHEOS_LEAN_AND_MEAN
ProudLockXSafariCC_FRAMEWORKS = UIKit AVFoundation

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += ProudLockXPrefs
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "sbreload"
