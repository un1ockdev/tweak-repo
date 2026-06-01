// ══════════════════════════════════════════════════════════════════════════════
//  Folder.xm — ProudLockX
//  iOS 15-16 Rootless uyumlu
//
//  Doğrulanmış kaynaklar:
//    • iOS 15.7 Runtime Headers
//    • iOS 16.5 Header Index Browser
//
//  ✅ DOĞRULANAN CLASS'LAR:
//    SBFloatyFolderView           → SpringBoardHome.framework
//      @property backgroundEffect (unsigned long long) — 0=blur yok
//    SBFloatyFolderBackgroundClipView → SpringBoardHome.framework
//    SBFolderTitleTextField       → SpringBoardHome.framework
//      @property fontSize (double)
//    SBHDefaultIconListLayoutProvider → SpringBoardHome.framework
//    APUIAppPredictionViewController  → AppPredictionUIWidget.framework
//    SBFluidSwitcherItemContainer → SpringBoard.framework
//    SBFluidSwitcherItemContainerHeaderView → SpringBoard.framework
//    SBFluidSwitcherItemContainerFooterView → SpringBoard.framework
//    SBMediaController            → SpringBoard.framework
//    FBProcessManager             → FrontBoardServices.framework
//
//  ❌ KALDIRILAN YANLIŞ CLASS'LAR:
//    SBHFolderView      → gerçek adı SBFloatyFolderView
//    _UIBackdropView global hook → çok geniş kapsam, sadece folder context'i
//
//  Inject: com.apple.springboard
// ══════════════════════════════════════════════════════════════════════════════

#import <UIKit/UIKit.h>
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

static NSString *_fdPlistPath(void) {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *p1 = @"/var/jb/var/mobile/Library/Preferences/com.un1ockdev.proudlockx.plist";
    if ([fm fileExistsAtPath:p1]) return p1;
    return @"/var/mobile/Library/Preferences/com.un1ockdev.proudlockx.plist";
}

static BOOL      _fdLoaded               = NO;
static BOOL      _fdTweakEnabled         = YES;
static BOOL      _fdHideTitles           = NO;
static BOOL      _fdHideBlur             = NO;
static BOOL      _fdIPadGrid             = NO;
static BOOL      _fdHideHandoff          = NO;
static BOOL      _fdHideCardIcons        = NO;
static BOOL      _fdHideCardLabels       = NO;
static BOOL      _fdPreventSwitcherClose = NO;
static BOOL      _fdCustomCardScale      = NO;
static CGFloat   _fdCardScale            = 1.0;

static void _fdLoad(void) {
    if (_fdLoaded) return;
    NSDictionary *p = [NSDictionary dictionaryWithContentsOfFile:_fdPlistPath()] ?: @{};
    id tv = p[@"tweakEnabled"];
    _fdTweakEnabled          = tv ? [tv boolValue] : YES;
#define FDBOOL(k) (_fdTweakEnabled && [p[k] boolValue])
    _fdHideTitles            = FDBOOL(@"hideFolderTitles");
    _fdHideBlur              = FDBOOL(@"hideFolderBlur");
    _fdIPadGrid              = FDBOOL(@"useIpadFolderGrid");
    _fdHideHandoff           = FDBOOL(@"hideHandoffSuggestions");
    _fdHideCardIcons         = FDBOOL(@"hideCardIcons");
    _fdHideCardLabels        = FDBOOL(@"hideCardAppLabels");
    _fdPreventSwitcherClose  = FDBOOL(@"preventSwitcherClose");
    _fdCustomCardScale       = FDBOOL(@"customCardScale");
#undef FDBOOL
    id cs = p[@"cardScaleValue"];
    _fdCardScale = (_fdCustomCardScale && cs) ? [cs floatValue] : 1.0;
    _fdLoaded = YES;
}

static void _fdPrefsChanged(CFNotificationCenterRef c __unused, void *o __unused,
                             CFStringRef n __unused, const void *ob __unused,
                             CFDictionaryRef i __unused) { _fdLoaded = NO; }

// ── Forward Declarations ─────────────────────────────────────────────────────

// ✅ DOĞRULANDI: SBFloatyFolderView — SpringBoardHome.framework
// iOS 14+ klasör view'u. backgroundEffect = 0 ile blur kalkar.
@interface SBFloatyFolderView : UIView
@property (nonatomic) unsigned long long backgroundEffect;
@end

// ✅ DOĞRULANDI: SBFloatyFolderBackgroundClipView — SpringBoardHome
@interface SBFloatyFolderBackgroundClipView : UIView
@end

// ✅ DOĞRULANDI: SBFolderTitleTextField — SpringBoardHome
// @property (nonatomic) double fontSize;
@interface SBFolderTitleTextField : UITextField
@property (nonatomic) double fontSize;
@end

// SBFolderView — iOS 16'da SBRootFolderView'un üst sınıfı
// titleView metodu iOS 16'da mevcut değil — hook kaldırıldı
@interface SBFolderView : UIView
@end

// ✅ DOĞRULANDI: APUIAppPredictionViewController — AppPredictionUIWidget
@interface APUIAppPredictionViewController : UIViewController
@end

// ✅ DOĞRULANDI: SBFluidSwitcherItemContainer — SpringBoard.framework
@interface SBFluidSwitcherItemContainer : UIView
@end

// ✅ DOĞRULANDI: Header + Footer view'ları — SpringBoard.framework
@interface SBFluidSwitcherItemContainerHeaderView : UIView
@end

@interface SBFluidSwitcherItemContainerFooterView : UIView
@end

// ✅ DOĞRULANDI: SBMediaController — SpringBoard.framework
@interface SBMediaController : NSObject
+ (instancetype)sharedInstance;
- (BOOL)isPlaying;
@end

// ✅ DOĞRULANDI: SBFluidSwitcherViewController — SpringBoard.framework
@interface SBFluidSwitcherViewController : UIViewController
- (BOOL)_shouldAllowDismissForItem:(id)item;
@end

// ✅ DOĞRULANDI: FBProcessManager — FrontBoardServices.framework
@interface FBProcessManager : NSObject
+ (instancetype)sharedInstance;
- (void)terminateApplicationWithBundleID:(NSString *)bid;
@end

// ✅ DOĞRULANDI: SBApplicationController — SpringBoard.framework
@interface SBApplication : NSObject
- (NSString *)bundleIdentifier;
@end

@interface SBApplicationController : NSObject
+ (instancetype)sharedInstance;
- (NSArray *)allApplications;
@end

// ══════════════════════════════════════════════════════════════════════════════
//  1. KLASÖR BAŞLIKLARINI GİZLE
//
//  ✅ DOĞRULANDI: SBFolderTitleTextField.fontSize — iOS 15.7 header
//  0 fontSize veya hidden = YES ile başlığı gizle
// ══════════════════════════════════════════════════════════════════════════════

%group FolderTitles

%hook SBFolderTitleTextField

- (void)layoutSubviews {
    %orig;
    _fdLoad();
    if (_fdHideTitles) {
        self.hidden = YES;
        self.alpha  = 0.0;
    }
}

- (void)setHidden:(BOOL)hidden {
    _fdLoad();
    %orig(_fdHideTitles ? YES : hidden);
}

- (void)setText:(NSString *)text {
    _fdLoad();
    if (_fdHideTitles) { %orig(@""); return; }
    %orig(text);
}

%end

// SBFolderView hook KALDIRILDI:
// iOS 16'da SBRootFolderView, SBFolderView'dan türüyor ve titleView metodu yok.
// Klasör başlığı iOS 16'da SBFolderTitleTextField üzerinden gizleniyor (üstte).

%end // FolderTitles

// ══════════════════════════════════════════════════════════════════════════════
//  2. KLASÖR ARKA PLAN BULANIKLĞINI GİZLE
//
//  ✅ DOĞRULANDI: SBFloatyFolderView.backgroundEffect — iOS 15.7 header
//  unsigned long long backgroundEffect; — 0 = bulanıklık yok
//
//  ❌ KALDIRILDI: global _UIBackdropView hook (çok geniş kapsam)
// ══════════════════════════════════════════════════════════════════════════════

%group FolderBlur

%hook SBFloatyFolderView

// backgroundEffect property hook — 0 döndür = blur yok
- (unsigned long long)backgroundEffect {
    _fdLoad();
    if (_fdHideBlur) return 0;
    return %orig;
}

- (void)setBackgroundEffect:(unsigned long long)effect {
    _fdLoad();
    if (_fdHideBlur) {
        %orig(0);
        return;
    }
    %orig(effect);
}

- (void)layoutSubviews {
    %orig;
    _fdLoad();
    if (!_fdHideBlur) return;
    // Ek güvenlik: blur view'larını subview taramasıyla da gizle
    for (UIView *sub in self.subviews) {
        NSString *cls = NSStringFromClass([sub class]);
        if ([cls containsString:@"Background"] ||
            [cls containsString:@"Blur"] ||
            [cls containsString:@"Backdrop"] ||
            [cls containsString:@"ClipView"]) {
            sub.hidden = YES;
            sub.alpha  = 0.0;
        }
    }
}

%end

// Folder arka plan clip view'u — sadece folder context'inde gizle
%hook SBFloatyFolderBackgroundClipView

- (void)setHidden:(BOOL)hidden {
    _fdLoad();
    %orig(_fdHideBlur ? YES : hidden);
}

- (void)didMoveToWindow {
    %orig;
    _fdLoad();
    if (_fdHideBlur) self.hidden = YES;
}

%end

%end // FolderBlur

// ══════════════════════════════════════════════════════════════════════════════
//  3. iPAD KLASÖR IZGARA STİLİ (4×4 = 16 ikon/sayfa)
//
//  ✅ DOĞRULANDI: SBHDefaultIconListLayoutProvider — SpringBoardHome iOS 15.7
//  Bu hook TweakSpring.xm'dekiyle çakışmaması için sadece klasör layout için
//  SBFolderGridLayoutConfiguration üzerinden çalışıyoruz.
// ══════════════════════════════════════════════════════════════════════════════

%group FolderGrid

@interface SBFolderGridLayoutConfiguration : NSObject
- (unsigned short)numberOfColumns;
- (unsigned short)numberOfRows;
- (void)setNumberOfColumns:(unsigned short)cols;
- (void)setNumberOfRows:(unsigned short)rows;
@end

%hook SBFolderGridLayoutConfiguration

- (unsigned short)numberOfColumns {
    _fdLoad();
    if (_fdIPadGrid) return 4;
    return %orig;
}

- (unsigned short)numberOfRows {
    _fdLoad();
    if (_fdIPadGrid) return 4;
    return %orig;
}

%end

%end // FolderGrid

// ══════════════════════════════════════════════════════════════════════════════
//  4. HANDOFF ÖNERİLERİNİ GİZLE
//
//  ✅ DOĞRULANDI: APUIAppPredictionViewController — AppPredictionUIWidget iOS 16.5
// ══════════════════════════════════════════════════════════════════════════════

%group HandoffSuggestions

%hook APUIAppPredictionViewController

- (void)viewDidLoad {
    %orig;
    _fdLoad();
    if (_fdHideHandoff) self.view.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    _fdLoad();
    if (_fdHideHandoff) self.view.hidden = YES;
}

- (void)viewDidLayoutSubviews {
    %orig;
    _fdLoad();
    if (_fdHideHandoff) self.view.hidden = YES;
}

%end

%end // HandoffSuggestions

// ══════════════════════════════════════════════════════════════════════════════
//  5. APP SWITCHER — KART İKON + ETİKET GİZLE / ÖZEL ÖLÇEK
//
//  ✅ DOĞRULANDI:
//    SBFluidSwitcherItemContainer           — SpringBoard iOS 16.5
//    SBFluidSwitcherItemContainerHeaderView — SpringBoard iOS 16.5 (ikon + isim)
//    SBFluidSwitcherItemContainerFooterView — SpringBoard iOS 16.5
// ══════════════════════════════════════════════════════════════════════════════

%group SwitcherCards

// Header view = uygulama ikonu + uygulama adı
%hook SBFluidSwitcherItemContainerHeaderView

- (void)layoutSubviews {
    %orig;
    _fdLoad();
    if (_fdHideCardIcons || _fdHideCardLabels) {
        for (UIView *sub in self.subviews) {
            NSString *cls = NSStringFromClass([sub class]);
            // Ikon view'unu gizle
            if (_fdHideCardIcons &&
                ([cls containsString:@"Icon"] ||
                 [cls containsString:@"Image"])) {
                sub.hidden = YES;
            }
            // Label / uygulama adını gizle
            if (_fdHideCardLabels &&
                ([sub isKindOfClass:[UILabel class]] ||
                 [cls containsString:@"Label"])) {
                sub.hidden = YES;
            }
        }
    }
    if (_fdHideCardIcons && _fdHideCardLabels) {
        self.hidden = YES; // İkisi de gizliyse header'ın kendisini kaldır
    }
}

%end

// Ana kart container — ölçek uygula
%hook SBFluidSwitcherItemContainer

- (void)layoutSubviews {
    %orig;
    _fdLoad();
    if (_fdCustomCardScale) {
        self.transform = CGAffineTransformMakeScale(_fdCardScale, _fdCardScale);
    }
}

%end

%end // SwitcherCards

// ══════════════════════════════════════════════════════════════════════════════
//  6. SES ÇALARKEN APP SWITCHER KAPATMAYI ENGELLE
//
//  ✅ DOĞRULANDI: SBFluidSwitcherViewController — SpringBoard iOS 16.5
//  ✅ DOĞRULANDI: SBMediaController.isPlaying   — SpringBoard iOS 16.5
// ══════════════════════════════════════════════════════════════════════════════

%group PreventSwitcherClose

%hook SBFluidSwitcherViewController

- (BOOL)_shouldAllowDismissForItem:(id)item {
    _fdLoad();
    if (!_fdPreventSwitcherClose) return %orig;
    SBMediaController *mc = [%c(SBMediaController) sharedInstance];
    if (mc && [mc isPlaying]) return NO; // Ses çalıyorsa kapatmayı engelle
    return %orig;
}

%end

%end // PreventSwitcherClose

// ══════════════════════════════════════════════════════════════════════════════
//  7. TÜM UYGULAMALARI KAPAT
//  Darwin notification: "com.un1ockdev.proudlockx/closeAllApps"
//  Settings UI'daki buton bu notification'ı gönderir.
// ══════════════════════════════════════════════════════════════════════════════

static void _fdCloseAllAppsHandler(CFNotificationCenterRef c __unused,
                                    void *o __unused,
                                    CFStringRef n __unused,
                                    const void *ob __unused,
                                    CFDictionaryRef i __unused) {
    @autoreleasepool {
        SBApplicationController *ac = [%c(SBApplicationController) sharedInstance];
        if (!ac) return;
        FBProcessManager *pm = [%c(FBProcessManager) sharedInstance];
        if (!pm) return;
        NSArray *apps = [ac allApplications];
        for (id app in apps) {
            if (![app isKindOfClass:%c(SBApplication)]) continue;
            NSString *bid = [(SBApplication *)app bundleIdentifier];
            if (!bid) continue;
            if ([bid isEqualToString:@"com.apple.springboard"]) continue;
            [pm terminateApplicationWithBundleID:bid];
        }
    }
}

// ══════════════════════════════════════════════════════════════════════════════
//  CONSTRUCTOR
// ══════════════════════════════════════════════════════════════════════════════

%ctor {
    NSLog(@"[PLX-FLD] ctor started");
    @autoreleasepool {
        NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
        if (![bid isEqualToString:@"com.apple.springboard"]) return;

        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(), NULL, _fdPrefsChanged,
            CFSTR("com.un1ockdev.proudlockx/prefsupdated"),
            NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(), NULL,
            _fdCloseAllAppsHandler,
            CFSTR("com.un1ockdev.proudlockx/closeAllApps"),
            NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

        if (objc_getClass("SBFolderTitleTextField"))
            %init(FolderTitles);

        if (objc_getClass("SBFloatyFolderView"))
            %init(FolderBlur);

        if (objc_getClass("SBFolderGridLayoutConfiguration"))
            %init(FolderGrid);

        if (objc_getClass("APUIAppPredictionViewController"))
            %init(HandoffSuggestions);

        if (objc_getClass("SBFluidSwitcherItemContainer"))
            %init(SwitcherCards);

        if (objc_getClass("SBFluidSwitcherViewController"))
            %init(PreventSwitcherClose);
    }
}
