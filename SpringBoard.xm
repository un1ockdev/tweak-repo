// ══════════════════════════════════════════════════════════════════════════════
//  SpringBoard.xm — ProudLockX
//  iOS 15-16 Rootless uyumlu
//
//  Doğrulanmış kaynaklar:
//    • iOS 15.7 Runtime Headers (SBDockView, SBIconListGridLayoutConfiguration)
//    • iOS 16.5 Header Index (SBIconBadgeView, SBRecordingIndicatorView,
//                             _UIStatusBarPillView, SBBacklightController,
//                             SBFluidSwitcherItemContainer, SBScreenshotManager)
//
//  Özellikler:
//    • hideDockBackground        → SBDockView.backgroundView gizle
//    • hideIconLabels            → SBIconView subview taraması (label accessory)
//    • hideIconBadges            → SBIconBadgeView (iOS15+16 aynı class)
//    • hideStatusBarColorViews   → _UIStatusBarPillView + SBRecordingIndicatorView
//    • disableAppTracking        → ATTrackingManager hook
//    • disableLowPowerAutoLock   → SBBacklightController + SBIdleTimerBase
//    • customHomeColumns         → SBHDefaultIconListLayoutProvider
//    • customCornerRadius        → UIScreen._displayCornerRadius
//    • disableScreenshotSound    → SBScreenshotManager._playShutterSound
//    • enableDragAndDrop         → UIDragInteraction.enabled
//
//  Inject: com.apple.springboard
// ══════════════════════════════════════════════════════════════════════════════

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <AudioToolbox/AudioServices.h>

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

static NSString *_sbPlistPath(void) {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *p1 = @"/var/jb/var/mobile/Library/Preferences/com.un1ockdev.proudlockx.plist";
    if ([fm fileExistsAtPath:p1]) return p1;
    return @"/var/mobile/Library/Preferences/com.un1ockdev.proudlockx.plist";
}

static BOOL      _sbLoaded                 = NO;
static BOOL      _sbTweakEnabled           = YES;
static BOOL      _sbHideDockBG             = NO;
static BOOL      _sbHideIconLabels         = NO;
static BOOL      _sbHideIconBadges         = NO;
static BOOL      _sbHideStatusColorViews   = NO;
static BOOL      _sbDisableTracking        = NO;
static BOOL      _sbDisableLowPowerLock    = NO;
static BOOL      _sbCustomColumns          = NO;
static NSInteger _sbColumnCount            = 4;
static BOOL      _sbCustomCorner           = NO;
static CGFloat   _sbCornerRadius           = 44.0;
static BOOL      _sbDisableScreenshotSound = NO;
static BOOL      _sbEnableDragDrop         = NO;
static NSInteger _sbDockBlurStyle           = 0;  // 0=default 1=clear 2=dark 3=light
static BOOL      _sbHideDockCompletely      = NO;
static BOOL      _sbIPadLayout             = NO;

static void _sbLoad(void) {
    if (_sbLoaded) return;
    _sbLoaded = YES;
    NSDictionary *p = [NSDictionary dictionaryWithContentsOfFile:_sbPlistPath()] ?: @{};
    id tv = p[@"tweakEnabled"];
    _sbTweakEnabled = tv ? [tv boolValue] : YES;
    _sbHideDockBG             = _sbTweakEnabled && [p[@"hideDockBackground"]       boolValue];
    _sbHideIconLabels         = _sbTweakEnabled && [p[@"hideIconLabels"]           boolValue];
    _sbHideIconBadges         = _sbTweakEnabled && [p[@"hideIconBadges"]           boolValue];
    _sbHideStatusColorViews   = _sbTweakEnabled && [p[@"hideStatusBarColorViews"]  boolValue];
    _sbDisableTracking        = _sbTweakEnabled && [p[@"disableAppTracking"]       boolValue];
    _sbDisableLowPowerLock    = _sbTweakEnabled && [p[@"disableLowPowerAutoLock"]  boolValue];
    _sbCustomColumns          = _sbTweakEnabled && [p[@"customHomeColumns"]        boolValue];
    id col = p[@"homeColumnCount"];
    _sbColumnCount            = (_sbCustomColumns && col) ? [col integerValue] : 4;
    _sbCustomCorner           = _sbTweakEnabled && [p[@"customCornerRadius"]       boolValue];
    id cr  = p[@"cornerRadiusValue"];
    _sbCornerRadius           = (_sbCustomCorner && cr) ? [cr floatValue] : 44.0;
    _sbDisableScreenshotSound = _sbTweakEnabled && [p[@"disableScreenshotSound"]  boolValue];
    _sbEnableDragDrop         = _sbTweakEnabled && [p[@"enableDragAndDrop"]        boolValue];
    id dbs = p[@"dockBlurStyle"];
    _sbDockBlurStyle          = (_sbTweakEnabled && dbs) ? [dbs integerValue] : 0;
    _sbHideDockCompletely     = _sbTweakEnabled && [p[@"hideDockCompletely"] boolValue];
    _sbIPadLayout             = _sbTweakEnabled && [p[@"iPadLayoutEnabled"] boolValue];
}

static void _sbPrefsChanged(CFNotificationCenterRef c __unused, void *o __unused,
                             CFStringRef n __unused, const void *ob __unused,
                             CFDictionaryRef i __unused) { _sbLoaded = NO; }

// ── Forward Declarations ─────────────────────────────────────────────────────

// ✅ DOĞRULANDI: SBDockView — backgroundView property iOS 15.7 header'da
@interface SBDockView : UIView
@property (nonatomic, retain) UIView *backgroundView;
@end

// ✅ DOĞRULANDI: SBIconView — SpringBoardHome.framework iOS 16.5
@interface SBIconView : UIView
@end

// ✅ DOĞRULANDI: SBIconBadgeView — SpringBoardHome.framework iOS 15+16 aynı
@interface SBIconBadgeView : UIView
@end

// ✅ DOĞRULANDI: SBRecordingIndicatorView — SpringBoard.framework iOS 16.5
@interface SBRecordingIndicatorView : UIView
@end

// ✅ DOĞRULANDI: _UIStatusBarPillView — UIKitCore.framework iOS 16.5
// iOS 16'da konum/hotspot/kayıt band'i bu pill view üzerinden çizilir
@interface _UIStatusBarPillView : UIView
@end

// ✅ DOĞRULANDI: SBBacklightController — SpringBoard.framework iOS 16.5
@interface SBBacklightController : NSObject
+ (instancetype)sharedInstance;
- (NSTimeInterval)autolockDelay;
- (void)_updateAutolockForLowPowerMode;
@end

// ✅ DOĞRULANDI: SBIdleTimerBase — SpringBoard.framework iOS 16.5
// Low Power Mode idle timer override için
@interface SBIdleTimerBase : NSObject
- (NSTimeInterval)idleTimerDuration;
@end

// ✅ DOĞRULANDI: SBHDefaultIconListLayoutProvider — SpringBoardHome.framework
// configureGridSizeClassSizes:forScreenType:numberOfColumns:iconLocation:layoutOptions:
@interface SBHDefaultIconListLayoutProvider : NSObject
@end

// ✅ DOĞRULANDI: SBIconListGridLayoutConfiguration — SpringBoardHome iOS 15.7
// columns/rows struct field'ları içinde — struct hook ile erişiyoruz
@interface SBIconListGridLayoutConfiguration : NSObject
@end

// ✅ DOĞRULANDI: SBScreenshotManager — SpringBoard.framework iOS 16.5
@interface SBScreenshotManager : NSObject
- (void)_playShutterSound;
- (void)saveScreenshotsWithCompletion:(id)completion;
@end

// ATTrackingManager — public framework, doğru
@interface ATTrackingManager : NSObject
+ (void)requestTrackingAuthorizationWithCompletionHandler:(void(^)(NSUInteger status))completion;
@end

// ══════════════════════════════════════════════════════════════════════════════
//  1. DOCK ARKA PLANI GİZLE
//
//  ✅ DOĞRULANDI: SBDockView.backgroundView property gerçek
//  iOS 15.7 header: @property (nonatomic, retain) UIView *backgroundView;
// ══════════════════════════════════════════════════════════════════════════════

%group DockBackground

%hook SBDockView

- (void)layoutSubviews {
    %orig;
    _sbLoad();
    // Dock blur rengi uygula
    UIView *bgView = nil;
    for (UIView *v in self.subviews) {
        if ([NSStringFromClass([v class]) containsString:@"Backdrop"] ||
            [NSStringFromClass([v class]) containsString:@"Background"]) {
            bgView = v;
            break;
        }
    }
    UIView *blurTarget = bgView ?: self;
    if (_sbDockBlurStyle == 2) {
        blurTarget.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
    } else if (_sbDockBlurStyle == 3) {
        blurTarget.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5f];
    } else if (_sbDockBlurStyle == 1) {
        blurTarget.backgroundColor = [UIColor clearColor];
    }

    if (!_sbHideDockBG) return;
    // backgroundView property'si — interface'de tanımlı
    UIView *bg = self.backgroundView;
    if (bg) {
        bg.hidden = YES;
        bg.alpha  = 0.0;
    }
    // _backgroundImageView ivar'ı da gizle (iOS 15 için)
    for (UIView *sub in self.subviews) {
        NSString *cls = NSStringFromClass([sub class]);
        if ([cls containsString:@"Background"] ||
            [cls containsString:@"background"]) {
            sub.hidden = YES;
            sub.alpha  = 0.0;
        }
    }
}

- (void)setBackgroundView:(UIView *)bg {
    %orig(bg);
    _sbLoad();
    if (_sbHideDockBG && bg) {
        bg.hidden = YES;
        bg.alpha  = 0.0;
    }
}

// Dock'u tamamen gizle (TweakSpring.xm'deki hideDockCompletely - tek yerde yönet)
- (void)setHidden:(BOOL)hidden {
    _sbLoad();
    %orig(_sbHideDockCompletely ? YES : hidden);
}

- (void)didMoveToWindow {
    %orig;
    _sbLoad();
    if (_sbHideDockCompletely) {
        self.hidden = YES;
        self.alpha  = 0.0;
    }
}

%end

%end // DockBackground

// ══════════════════════════════════════════════════════════════════════════════
//  2. SİMGE ETİKETLERİNİ GİZLE
//
//  iOS 16'da SBIconLabelView artık kullanılmıyor — label,
//  SBIconLabelAccessoryView (SBIconLabelImage üzerinden raster) olarak gelir.
//  Güvenli yol: SBIconView subview'larını tarayarak label'ı gizle.
// ══════════════════════════════════════════════════════════════════════════════

%group IconLabels

%hook SBIconView

- (void)layoutSubviews {
    %orig;
    _sbLoad();
    if (!_sbHideIconLabels) return;

    static BOOL _inLabel = NO;
    if (_inLabel) return;
    _inLabel = YES;

    for (UIView *sub in self.subviews) {
        NSString *cls = NSStringFromClass([sub class]);
        // SBIconLabelAccessoryView (iOS 16) veya SBIconLabelView (iOS 15)
        if ([cls containsString:@"Label"] ||
            [cls containsString:@"label"]) {
            sub.hidden = YES;
        }
    }

    _inLabel = NO;
}

%end

%end // IconLabels

// ══════════════════════════════════════════════════════════════════════════════
//  3. SİMGE ROZETLERİNİ GİZLE
//
//  ✅ DOĞRULANDI: SBIconBadgeView — SpringBoardHome.framework iOS 15+16 aynı
//  iOS 16.5 header index'te sadece SBIconBadgeView var, _SBIconBadgeView YOK.
// ══════════════════════════════════════════════════════════════════════════════

%group IconBadges

%hook SBIconBadgeView

- (void)layoutSubviews {
    %orig;
    _sbLoad();
    if (_sbHideIconBadges) self.hidden = YES;
}

- (void)setHidden:(BOOL)hidden {
    _sbLoad();
    %orig(_sbHideIconBadges ? YES : hidden);
}

// badge sayısı güncelleme
- (void)setBadgeValue:(id)value {
    %orig(value);
    _sbLoad();
    if (_sbHideIconBadges) self.hidden = YES;
}

%end

%end // IconBadges

// ══════════════════════════════════════════════════════════════════════════════
//  4. DURUM ÇUBUĞU RENKLİ GÖRÜNÜMLERİNİ GİZLE
//
//  ✅ DOĞRULANDI iOS 16 MİMARİSİ:
//    • SBRecordingIndicatorView  → Ekran Kaydı (kırmızı)  — SpringBoard.framework
//    • _UIStatusBarPillView      → Konum (mavi) + Hotspot (yeşil) — UIKitCore.framework
//
//  ❌ YANLIŞ olan (artık yok): _UIStatusBarColoredBandView, UIStatusBarForegroundView
// ══════════════════════════════════════════════════════════════════════════════

%group StatusBarColorViews

// iOS 16 — Ekran Kaydı indikatörü (kırmızı)
%hook SBRecordingIndicatorView

- (void)setHidden:(BOOL)hidden {
    _sbLoad();
    %orig(_sbHideStatusColorViews ? YES : hidden);
}

- (void)layoutSubviews {
    %orig;
    _sbLoad();
    if (_sbHideStatusColorViews) self.hidden = YES;
}

%end

// iOS 16 — Konum + Hotspot pill view (UIKitCore)
%hook _UIStatusBarPillView

- (void)setHidden:(BOOL)hidden {
    _sbLoad();
    %orig(_sbHideStatusColorViews ? YES : hidden);
}

- (void)layoutSubviews {
    %orig;
    _sbLoad();
    if (_sbHideStatusColorViews) self.hidden = YES;
}

%end

%end // StatusBarColorViews

// ══════════════════════════════════════════════════════════════════════════════
//  5. UYGULAMA İZLEME KAYITLARINI DEVRE DIŞI BIRAK
//
//  ATTrackingManager — AppTrackingTransparency.framework (public)
//  2 = ATTrackingManagerAuthorizationStatusDenied
// ══════════════════════════════════════════════════════════════════════════════

%group AppTracking

%hook ATTrackingManager

+ (void)requestTrackingAuthorizationWithCompletionHandler:(void(^)(NSUInteger status))completion {
    _sbLoad();
    if (_sbDisableTracking && completion) {
        completion(2); // denied
        return;
    }
    %orig(completion);
}

%end

%end // AppTracking

// ══════════════════════════════════════════════════════════════════════════════
//  6. DÜŞÜK GÜÇ MODU OTOMATİK KİLİTLEMEYİ DEVRE DIŞI BIRAK
//
//  ✅ DOĞRULANDI: SBBacklightController — SpringBoard.framework iOS 16.5
//  ✅ DOĞRULANDI: SBIdleTimerBase      — SpringBoard.framework iOS 16.5
//
//  iOS 16'da Low Power Mode idle timer SBIdleTimerBase üzerinden yönetiliyor.
// ══════════════════════════════════════════════════════════════════════════════

%group LowPowerAutoLock

%hook SBBacklightController

- (NSTimeInterval)autolockDelay {
    _sbLoad();
    if (!_sbDisableLowPowerLock) return %orig;
    static BOOL _guard = NO;
    if (_guard) return %orig;
    _guard = YES;
    NSTimeInterval orig = %orig;
    _guard = NO;
    // LP modu 30 sn'ye düşürüyorsa orijinal ayarı koru (min 60 sn)
    return (orig > 0 && orig < 60.0) ? 300.0 : orig;
}

- (void)_updateAutolockForLowPowerMode {
    _sbLoad();
    if (_sbDisableLowPowerLock) return; // LP override'ını engelle
    %orig;
}

%end

// iOS 16 idle timer — Low Power duration override
%hook SBIdleTimerBase

- (NSTimeInterval)idleTimerDuration {
    _sbLoad();
    if (!_sbDisableLowPowerLock) return %orig;
    NSTimeInterval orig = %orig;
    return (orig > 0 && orig < 60.0) ? 300.0 : orig;
}

%end

%end // LowPowerAutoLock

// ══════════════════════════════════════════════════════════════════════════════
//  7. ANA EKRAN SÜTUN SAYISINI ÖZELLEŞTİR
//
//  ✅ DOĞRULANDI: SBHDefaultIconListLayoutProvider — SpringBoardHome iOS 15.7
//  Method: configureGridSizeClassSizes:forScreenType:numberOfColumns:
//           iconLocation:layoutOptions:
//
//  SBIconListGridLayoutConfiguration — struct tabanlı, property yok.
//  Provider hook daha güvenli.
// ══════════════════════════════════════════════════════════════════════════════

// SBHIconGridSize struct (iOS 15.7 header'dan) — %group dışında olmalı
typedef struct {
    unsigned short columns;
    unsigned short rows;
} SBHIconGridSize;

typedef struct {
    SBHIconGridSize icon;
    SBHIconGridSize small;
    SBHIconGridSize medium;
    SBHIconGridSize large;
    SBHIconGridSize newsLargeTall;
} SBHIconGridSizeClassSizes;

%group HomeColumns

%hook SBHDefaultIconListLayoutProvider

- (void)configureGridSizeClassSizes:(SBHIconGridSizeClassSizes *)sizes
                      forScreenType:(unsigned long long)screenType
                    numberOfColumns:(unsigned long long)columns
                       iconLocation:(id)location
                      layoutOptions:(unsigned long long)options {
    _sbLoad();
    // iPad layout modu: 6 sütun override (TweakSpring.xm'deki duplicate kaldırıldı)
    if (_sbIPadLayout && sizes) {
        sizes->icon.columns       = 6;
        sizes->small.columns      = 6;
        sizes->medium.columns     = 6;
        sizes->large.columns      = 6;
        sizes->icon.rows          = 5;
        %orig(sizes, screenType, 6, location, options);
        return;
    }
    if (_sbCustomColumns && sizes) {
        // Tüm size class'larda sütunu override et
        sizes->icon.columns       = (unsigned short)_sbColumnCount;
        sizes->small.columns      = (unsigned short)_sbColumnCount;
        sizes->medium.columns     = (unsigned short)_sbColumnCount;
        sizes->large.columns      = (unsigned short)_sbColumnCount;
        %orig(sizes, screenType, (unsigned long long)_sbColumnCount, location, options);
        return;
    }
    %orig(sizes, screenType, columns, location, options);
}

%end

%end // HomeColumns

// ══════════════════════════════════════════════════════════════════════════════
//  8. ÖZEL EKRAN KÖŞESİ YARIÇAPI
//
//  UIScreen._displayCornerRadius — private property
// ══════════════════════════════════════════════════════════════════════════════

%group CornerRadius

%hook UIScreen

- (CGFloat)_displayCornerRadius {
    _sbLoad();
    if (_sbCustomCorner) return _sbCornerRadius;
    return %orig;
}

%end

%end // CornerRadius

// ══════════════════════════════════════════════════════════════════════════════
//  9. EKRAN GÖRÜNTÜSÜ SESİNİ DEVRE DIŞI BIRAK
//
//  ✅ DOĞRULANDI: SBScreenshotManager — SpringBoard.framework iOS 16.5
//  _playShutterSound method'u gerçek.
// ══════════════════════════════════════════════════════════════════════════════

%group ScreenshotSound

%hook SBScreenshotManager

- (void)_playShutterSound {
    _sbLoad();
    if (_sbDisableScreenshotSound) return;
    %orig;
}

// iOS 16'da bazı cihazlarda farklı method adı
- (void)_playCaptureSound {
    _sbLoad();
    if (_sbDisableScreenshotSound) return;
    %orig;
}

%end

%end // ScreenshotSound

// ══════════════════════════════════════════════════════════════════════════════
//  10. iPHONE'DA SÜRÜKLE & BIRAK
// ══════════════════════════════════════════════════════════════════════════════

%group DragAndDrop

%hook UIDragInteraction

- (BOOL)isEnabled {
    _sbLoad();
    if (_sbEnableDragDrop) return YES;
    return %orig;
}

%end

%hook UIDropInteraction

- (BOOL)isEnabled {
    _sbLoad();
    if (_sbEnableDragDrop) return YES;
    return %orig;
}

%end

%end // DragAndDrop

// ══════════════════════════════════════════════════════════════════════════════
//  CONSTRUCTOR
// ══════════════════════════════════════════════════════════════════════════════

%ctor {
    NSLog(@"[PLX-SB] ctor started");
    @autoreleasepool {
        NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
        if (![bid isEqualToString:@"com.apple.springboard"]) return;

        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(), NULL, _sbPrefsChanged,
            CFSTR("com.un1ockdev.proudlockx/prefsupdated"),
            NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

        if (objc_getClass("SBDockView"))
            %init(DockBackground);
        if (objc_getClass("SBIconView"))
            %init(IconLabels);
        if (objc_getClass("SBIconBadgeView"))
            %init(IconBadges);
        // Status bar — her ikisi de init et, cihazda hangisi varsa çalışır
        %init(StatusBarColorViews);
        if (objc_getClass("ATTrackingManager"))
            %init(AppTracking);
        if (objc_getClass("SBBacklightController"))
            %init(LowPowerAutoLock);
        if (objc_getClass("SBHDefaultIconListLayoutProvider"))
            %init(HomeColumns);
        %init(CornerRadius);
        if (objc_getClass("SBScreenshotManager"))
            %init(ScreenshotSound);
        %init(DragAndDrop);
    }
}
