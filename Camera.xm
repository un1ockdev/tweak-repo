// ══════════════════════════════════════════════════════════════════════════════
//  Camera.xm — ProudLockX
//  iOS 15-16 Rootless uyumlu
//
//  Doğrulanmış kaynaklar: iOS 16.5 Header Index Browser
//
//  ✅ DOĞRULANAN CLASS'LAR:
//    CAMBottomBar            → CameraUI.framework
//    CAMShutterButton        → CameraKit.framework
//    CAMShutterIndicatorView → CameraUI.framework
//    CAMCaptureController    → CameraKit.framework
//    CAMViewfinderViewController → CameraUI.framework
//
//  ❌ KALDIRILDI:
//    CAMLastPhotoButton  → iOS 16'da bu isimle YOK, CAMBottomBar subview'u
//    CAMThumbnailButton  → YOK
//    CAMCaptureSession   → iOS 16'da farklı mimari
//
//  Inject: com.apple.camera
// ══════════════════════════════════════════════════════════════════════════════

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>

// DEBUG
#ifndef PLX_DEBUG
#define PLX_DEBUG 1
#endif
#if PLX_DEBUG
#define PLXLog(fmt, ...) NSLog((@"[ProudLockX] " fmt), ##__VA_ARGS__)
#else
#define PLXLog(...)
#endif


// ── Prefs ────────────────────────────────────────────────────────────────────

static NSString *_camPlistPath(void) {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *p1 = @"/var/jb/var/mobile/Library/Preferences/com.un1ockdev.proudlockx.plist";
    if ([fm fileExistsAtPath:p1]) return p1;
    return @"/var/mobile/Library/Preferences/com.un1ockdev.proudlockx.plist";
}

static BOOL _camLoaded         = NO;
static BOOL _camTweakEnabled   = YES;
static BOOL _camHideLastPhoto  = NO;
static BOOL _camDisableShutter = NO;
static BOOL _camIPadLayout     = NO;

static void _camLoad(void) {
    if (_camLoaded) return;
    NSDictionary *p = [NSDictionary dictionaryWithContentsOfFile:_camPlistPath()] ?: @{};
    id tv = p[@"tweakEnabled"];
    _camTweakEnabled   = tv ? [tv boolValue] : YES;
    _camHideLastPhoto  = _camTweakEnabled && [p[@"hideCameraLastPhoto"]  boolValue];
    _camDisableShutter = _camTweakEnabled && [p[@"disableCameraShutter"] boolValue];
    _camIPadLayout     = _camTweakEnabled && [p[@"cameraIPadLayout"]     boolValue];
    _camLoaded = YES;
}

static void _camPrefsChanged(CFNotificationCenterRef c __unused, void *o __unused,
                              CFStringRef n __unused, const void *ob __unused,
                              CFDictionaryRef i __unused) { _camLoaded = NO; }

// ── Forward Declarations ─────────────────────────────────────────────────────

// ✅ DOĞRULANDI: CAMBottomBar — CameraUI.framework iOS 16.5
// Alt bar — içinde thumbnail / son fotoğraf butonu subview olarak bulunur
@interface CAMBottomBar : UIView
@end

// ✅ DOĞRULANDI: CAMShutterButton — CameraKit.framework iOS 16.5
@interface CAMShutterButton : UIControl
@end

// ✅ DOĞRULANDI: CAMShutterIndicatorView — CameraUI.framework iOS 16.5
@interface CAMShutterIndicatorView : UIView
@end

// ✅ DOĞRULANDI: CAMCaptureController — CameraKit.framework iOS 16.5
// Ses çalma metodları burada
@interface CAMCaptureController : NSObject
- (void)_playCaptureSound;
- (void)_playCaptureSound:(BOOL)arg1;
- (void)didCapturePhoto;
@end

// ✅ DOĞRULANDI: CAMViewfinderViewController — CameraUI.framework iOS 16.5
@interface CAMViewfinderViewController : UIViewController
- (BOOL)isPadUI;
@end

// ✅ DOĞRULANDI: CameraViewController — ana kamera VC
@interface CameraViewController : UIViewController
- (BOOL)isPadUI;
@end

// ══════════════════════════════════════════════════════════════════════════════
//  1. SON FOTOĞRAF ÖNİZLEMESİNİ GİZLE
//
//  iOS 16'da "son fotoğraf" ayrı bir button class'ı değil,
//  CAMBottomBar içindeki bir subview. Subview taramasıyla gizliyoruz.
// ══════════════════════════════════════════════════════════════════════════════

%group CameraLastPhoto

%hook CAMBottomBar

- (void)layoutSubviews {
    %orig;
    _camLoad();
    if (!_camHideLastPhoto) return;

    static BOOL _guard = NO;
    if (_guard) return;
    _guard = YES;

    for (UIView *sub in self.subviews) {
        NSString *cls = NSStringFromClass([sub class]);
        // Thumbnail / son fotoğraf butonu — CAM prefix'li view'lar
        if ([cls containsString:@"Thumbnail"] ||
            [cls containsString:@"LastPhoto"] ||
            [cls containsString:@"Library"] ||
            [cls containsString:@"Gallery"] ||
            [cls containsString:@"Photo"]) {
            sub.hidden = YES;
        }
        // UIImageView doğrudan alt view ise (thumbnail image view)
        if ([sub isKindOfClass:[UIImageView class]] ||
            [sub isKindOfClass:[UIButton class]]) {
            // Sadece sol alt köşedeki (thumbnail pozisyonu) öğeyi gizle
            CGFloat xPos = sub.frame.origin.x;
            if (xPos < 100.0) { // Sol taraftaki button/image = thumbnail
                sub.hidden = YES;
            }
        }
    }

    _guard = NO;
}

%end

%end // CameraLastPhoto

// ══════════════════════════════════════════════════════════════════════════════
//  2. DEKLANŞÖR SESİNİ DEVRE DIŞI BIRAK
//
//  ✅ DOĞRULANDI: CAMCaptureController._playCaptureSound — CameraKit iOS 16.5
//
//  NOT: Japonya/Güney Kore'de Apple bölgesel kısıtlama uygular.
//  Bu hook o bölgelerde etkisiz olabilir.
// ══════════════════════════════════════════════════════════════════════════════

%group CameraShutter

%hook CAMCaptureController

// Parametresiz versiyon
- (void)_playCaptureSound {
    _camLoad();
    if (_camDisableShutter) return;
    %orig;
}

// Parametreli versiyon (iOS 15+)
- (void)_playCaptureSound:(BOOL)arg1 {
    _camLoad();
    if (_camDisableShutter) return;
    %orig(arg1);
}

// iOS 16 — didCapturePhoto içinden ses çağrısı yapılabilir
- (void)didCapturePhoto {
    // Önce orig'i çağır (fotoğraf kaydedilsin)
    // Ses AVSystemController üzerinden ayrıca çalınır
    %orig;
}

%end

// AVSystemController üzerinden ses engelleme (iOS 16 fallback)
%hook AVSystemController

- (BOOL)setAttribute:(id)attribute toValue:(id)value error:(NSError **)error {
    _camLoad();
    if (_camDisableShutter) {
        // "CameraShutterVolume" attribute'unu sıfırla
        if ([attribute isKindOfClass:[NSString class]] &&
            [(NSString *)attribute containsString:@"Shutter"]) {
            return YES; // başarılı gibi davran ama ses çalma
        }
    }
    return %orig(attribute, value, error);
}

%end

%end // CameraShutter

// ══════════════════════════════════════════════════════════════════════════════
//  3. iPAD TARZI KAMERA DÜZENİ
//
//  ✅ DOĞRULANDI: CAMViewfinderViewController — CameraUI iOS 16.5
//  isPadUI = YES → iPad layout modunu zorla
// ══════════════════════════════════════════════════════════════════════════════

%group CameraIPadLayout

%hook CAMViewfinderViewController

- (BOOL)isPadUI {
    _camLoad();
    if (_camIPadLayout) return YES;
    return %orig;
}

%end

%hook CameraViewController

- (BOOL)isPadUI {
    _camLoad();
    if (_camIPadLayout) return YES;
    return %orig;
}

%end

%end // CameraIPadLayout

// ══════════════════════════════════════════════════════════════════════════════
//  CONSTRUCTOR
// ══════════════════════════════════════════════════════════════════════════════

%ctor {
    @autoreleasepool {
        PLXLog(@"CTOR START: %s", __FILE__);
        NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
        if (![bid isEqualToString:@"com.apple.camera"]) return;

        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(), NULL, _camPrefsChanged,
            CFSTR("com.un1ockdev.proudlockx/prefsupdated"),
            NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

        if (objc_getClass("CAMBottomBar"))
            %init(CameraLastPhoto);
        if (objc_getClass("CAMCaptureController"))
            %init(CameraShutter);
        if (objc_getClass("CAMViewfinderViewController") ||
            objc_getClass("CameraViewController"))
            %init(CameraIPadLayout);
    }
}
