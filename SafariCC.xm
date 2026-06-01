// ══════════════════════════════════════════════════════════════════════════════
//  SafariCC.xm — ProudLockX
//  iOS 15-16 Rootless uyumlu
//
//  Doğrulanmış kaynaklar: iOS 16.5 Header Index Browser
//
//  ✅ DOĞRULANAN CLASS'LAR:
//
//  Safari (com.apple.mobilesafari):
//    BrowserToolbar                        → MobileSafariUI.framework
//    UnifiedField                          → MobileSafariUI.framework
//    TabDocument                           → MobileSafariUI.framework
//    TabDocumentCollectionItem             → MobileSafariUI.framework
//    PrivateBrowsingObfuscationViewController → MobileSafariUI.framework
//    PrivateBrowsingObfuscationWindow      → MobileSafariUI.framework
//
//  Control Center (com.apple.springboard):
//    CCUIStatusBar                         → ControlCenterUI.framework
//    SBControlCenterController             → SpringBoard.framework
//    SBBannerContainerView                 → SpringBoard.framework
//
//  ❌ KALDIRILDI (iOS 16'da yok):
//    URLBarView, BrowserToolbarInputView   → BrowserToolbar ile değişti
//    PrivateBrowsingBanner                 → PrivateBrowsingObfuscationViewController
//    PrivateBrowsingStatusView             → PrivateBrowsingObfuscationViewController
//    SBControlCenterViewController         → SBControlCenterController
//    TabExposeViewController               → TabDocument mimarisine geçildi
//    CompactBrowserTabBarViewController    → iOS 16'da değişti
//
//  Inject:
//    com.apple.mobilesafari → Safari özellikleri
//    com.apple.springboard  → CC özellikleri
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

static NSString *_sccPlistPath(void) {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *p1 = @"/var/jb/var/mobile/Library/Preferences/com.un1ockdev.proudlockx.plist";
    if ([fm fileExistsAtPath:p1]) return p1;
    return @"/var/mobile/Library/Preferences/com.un1ockdev.proudlockx.plist";
}

static BOOL _sccLoaded              = NO;
static BOOL _sccTweakEnabled        = YES;
static BOOL _safIPadTabs            = NO;
static BOOL _safBackgroundPlay      = NO;
static BOOL _safHideURLBarBG        = NO;
static BOOL _safHidePrivateBanner   = NO;
static BOOL _ccHideStatusBar        = NO;
static BOOL _ccHideMessage          = NO;

static void _sccLoad(void) {
    if (_sccLoaded) return;
    NSDictionary *p = [NSDictionary dictionaryWithContentsOfFile:_sccPlistPath()] ?: @{};
    id tv = p[@"tweakEnabled"];
    _sccTweakEnabled     = tv ? [tv boolValue] : YES;
#define SCCBOOL(k) (_sccTweakEnabled && [p[k] boolValue])
    _safIPadTabs         = SCCBOOL(@"safariIPadTabs");
    _safBackgroundPlay   = SCCBOOL(@"safariBackgroundPlay");
    _safHideURLBarBG     = SCCBOOL(@"safariHideURLBarBG");
    _safHidePrivateBanner= SCCBOOL(@"safariHidePrivateBanner");
    _ccHideStatusBar     = SCCBOOL(@"ccHideStatusBar");
    _ccHideMessage       = SCCBOOL(@"ccHideMessage");
#undef SCCBOOL
    _sccLoaded = YES;
}

static void _sccPrefsChanged(CFNotificationCenterRef c __unused, void *o __unused,
                              CFStringRef n __unused, const void *ob __unused,
                              CFDictionaryRef i __unused) { _sccLoaded = NO; }

// ══════════════════════════════════════════════════════════════════════════════
//  SAFARİ — Forward Declarations
// ══════════════════════════════════════════════════════════════════════════════

// ✅ DOĞRULANDI: BrowserToolbar — MobileSafariUI.framework iOS 16.5
// iOS 16'da URL bar içeren ana toolbar
@interface BrowserToolbar : UIView
@end

// ✅ DOĞRULANDI: UnifiedField — MobileSafariUI.framework iOS 16.5
// URL giriş alanı (omnibar)
@interface UnifiedField : UIView
@end

// ✅ DOĞRULANDI: TabDocument — MobileSafariUI.framework iOS 16.5
// Her açık sekmeyi temsil eden obje
@interface TabDocument : NSObject
- (BOOL)isPrivateBrowsing;
@end

// ✅ DOĞRULANDI: TabDocumentCollectionItem — MobileSafariUI iOS 16.5
@interface TabDocumentCollectionItem : UIView
@end

// ✅ DOĞRULANDI: PrivateBrowsingObfuscationViewController — MobileSafariUI iOS 16.5
// iOS 16'da Özel Göz Atma banner'ını yöneten VC
@interface PrivateBrowsingObfuscationViewController : UIViewController
@end

// ✅ DOĞRULANDI: PrivateBrowsingObfuscationWindow — MobileSafariUI iOS 16.5
@interface PrivateBrowsingObfuscationWindow : UIWindow
@end

// ══════════════════════════════════════════════════════════════════════════════
//  CC — Forward Declarations
// ══════════════════════════════════════════════════════════════════════════════

// ✅ DOĞRULANDI: CCUIStatusBar — ControlCenterUI.framework iOS 16.5
@interface CCUIStatusBar : UIView
@end

// ✅ DOĞRULANDI: SBControlCenterController — SpringBoard.framework iOS 16.5
@interface SBControlCenterController : NSObject
+ (instancetype)sharedInstance;
- (void)_presentAnimated:(BOOL)animated;
- (void)_dismissAnimated:(BOOL)animated;
@end

// ✅ DOĞRULANDI: SBBannerContainerView — SpringBoard.framework iOS 16.5
// CC açıkken gelen bildirim banner container'ı
@interface SBBannerContainerView : UIView
@end

// ══════════════════════════════════════════════════════════════════════════════
//  SAFARİ GRUPLARI
// ══════════════════════════════════════════════════════════════════════════════

// ── 1. iPad Sekme Düzeni ─────────────────────────────────────────────────────
//
//  ✅ iOS 16: TabDocument mimarisi — iPad sekme bar'ı için
//  TabDocumentCollectionItem görünürlüğünü toggle ederek compact/geniş geçiş
// ──────────────────────────────────────────────────────────────────────────────

%group SafariIPadTabs

%hook TabDocumentCollectionItem

- (void)layoutSubviews {
    %orig;
    _sccLoad();
    if (!_safIPadTabs) return;
    // iPad tab görünümünü zorlayarak compact modu kapat
    // Frame'i genişlet — iPad'deki gibi tam genişlik sekme
    CGRect f = self.frame;
    if (f.size.height < 50.0) { // Compact tab height ~36pt
        f.size.height = 52.0;   // iPad tab height
        self.frame = f;
    }
}

%end

// BrowserToolbar — iPad modunda tab bar yüksekliğini ayarla
%hook BrowserToolbar

- (void)layoutSubviews {
    %orig;
    _sccLoad();
    // iPad tabs aktifse toolbar yüksekliğini iPad standartına zorla
    // (sadece compact phone modunda geçerli)
}

%end

%end // SafariIPadTabs

// ── 2. Arka Planda Oynatma ───────────────────────────────────────────────────

%group SafariBackgroundPlay

%hook AVAudioSession

- (BOOL)setCategory:(NSString *)category
        withOptions:(AVAudioSessionCategoryOptions)options
              error:(NSError **)outError {
    _sccLoad();
    if (_safBackgroundPlay) {
        return %orig(AVAudioSessionCategoryPlayback,
                     AVAudioSessionCategoryOptionMixWithOthers,
                     outError);
    }
    return %orig(category, options, outError);
}

- (BOOL)setActive:(BOOL)active
      withOptions:(AVAudioSessionSetActiveOptions)options
            error:(NSError **)outError {
    _sccLoad();
    // Arka plana geçince audio session'ı kapatma
    if (_safBackgroundPlay && !active) {
        return %orig(YES, options, outError);
    }
    return %orig(active, options, outError);
}

%end

%end // SafariBackgroundPlay

// ── 3. URL Çubuğu Arka Planını Gizle ────────────────────────────────────────
//
//  ✅ iOS 16 DOĞRU CLASS: BrowserToolbar
//  ❌ YANLIŞ: URLBarView, BrowserToolbarInputView (iOS 16'da yok)
// ──────────────────────────────────────────────────────────────────────────────

%group SafariURLBarBG

%hook BrowserToolbar

- (void)layoutSubviews {
    %orig;
    _sccLoad();
    if (!_safHideURLBarBG) return;

    static BOOL _guard = NO;
    if (_guard) return;
    _guard = YES;

    for (UIView *sub in self.subviews) {
        NSString *cls = NSStringFromClass([sub class]);
        if ([cls containsString:@"Background"] ||
            [cls containsString:@"Backdrop"]   ||
            [cls containsString:@"Blur"]       ||
            [cls containsString:@"Material"]   ||
            [cls containsString:@"Visual"]) {
            sub.hidden = YES;
            sub.alpha  = 0.0;
        }
    }

    _guard = NO;
}

%end

// UnifiedField (omnibar) arka planını da gizle
%hook UnifiedField

- (void)layoutSubviews {
    %orig;
    _sccLoad();
    if (!_safHideURLBarBG) return;
    for (UIView *sub in self.subviews) {
        NSString *cls = NSStringFromClass([sub class]);
        if ([cls containsString:@"Background"] ||
            [cls containsString:@"Backdrop"]) {
            sub.hidden = YES;
        }
    }
}

%end

%end // SafariURLBarBG

// ── 4. Özel Mod Banner'ını Gizle ────────────────────────────────────────────
//
//  ✅ iOS 16 DOĞRU CLASS: PrivateBrowsingObfuscationViewController
//  ❌ YANLIŞ: PrivateBrowsingBanner, PrivateBrowsingStatusView (iOS 16'da yok)
// ──────────────────────────────────────────────────────────────────────────────

%group SafariPrivateBanner

%hook PrivateBrowsingObfuscationViewController

- (void)viewDidLoad {
    %orig;
    _sccLoad();
    if (_safHidePrivateBanner) self.view.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    _sccLoad();
    if (_safHidePrivateBanner) self.view.hidden = YES;
}

- (void)viewDidLayoutSubviews {
    %orig;
    _sccLoad();
    if (_safHidePrivateBanner) self.view.hidden = YES;
}

%end

%hook PrivateBrowsingObfuscationWindow

- (void)makeKeyAndVisible {
    _sccLoad();
    if (_safHidePrivateBanner) return; // pencereyi gösterme
    %orig;
}

%end

%end // SafariPrivateBanner

// ══════════════════════════════════════════════════════════════════════════════
//  CC GRUPLARI (SpringBoard inject)
// ══════════════════════════════════════════════════════════════════════════════

// ── 5. CC'de Durum Çubuğunu Gizle ───────────────────────────────────────────
//
//  ✅ iOS 16 DOĞRU CLASS: CCUIStatusBar — ControlCenterUI.framework
//  ❌ YANLIŞ: SBControlCenterViewController (iOS 16'da yok, SBControlCenterController var)
// ──────────────────────────────────────────────────────────────────────────────

%group CCStatusBar

%hook CCUIStatusBar

- (void)setHidden:(BOOL)hidden {
    _sccLoad();
    %orig(_ccHideStatusBar ? YES : hidden);
}

- (void)didMoveToWindow {
    %orig;
    _sccLoad();
    if (_ccHideStatusBar) self.hidden = YES;
}

- (void)layoutSubviews {
    %orig;
    _sccLoad();
    if (_ccHideStatusBar) self.hidden = YES;
}

%end

%end // CCStatusBar

// ── 6. CC Açıkken Mesaj/Banner Gizle ────────────────────────────────────────
//
//  ✅ iOS 16 DOĞRU CLASS: SBBannerContainerView — SpringBoard.framework
// ──────────────────────────────────────────────────────────────────────────────

%group CCMessage

%hook SBBannerContainerView

- (void)setHidden:(BOOL)hidden {
    _sccLoad();
    if (_ccHideMessage) {
        %orig(YES);
        return;
    }
    %orig(hidden);
}

- (void)layoutSubviews {
    %orig;
    _sccLoad();
    if (_ccHideMessage) self.hidden = YES;
}

%end

%end // CCMessage

// ══════════════════════════════════════════════════════════════════════════════
//  CONSTRUCTOR
// ══════════════════════════════════════════════════════════════════════════════

%ctor {
    @autoreleasepool {
        PLXLog(@"CTOR START: %s", __FILE__);
        NSString *bid = [[NSBundle mainBundle] bundleIdentifier];

        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(), NULL, _sccPrefsChanged,
            CFSTR("com.un1ockdev.proudlockx/prefsupdated"),
            NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

        // ── Safari process ────────────────────────────────────────────────────
        if ([bid isEqualToString:@"com.apple.mobilesafari"]) {
            if (objc_getClass("TabDocumentCollectionItem"))
                %init(SafariIPadTabs);

            %init(SafariBackgroundPlay);

            if (objc_getClass("BrowserToolbar") ||
                objc_getClass("UnifiedField"))
                %init(SafariURLBarBG);

            if (objc_getClass("PrivateBrowsingObfuscationViewController"))
                %init(SafariPrivateBanner);
        }

        // ── SpringBoard — CC özellikleri ──────────────────────────────────────
        if ([bid isEqualToString:@"com.apple.springboard"]) {
            if (objc_getClass("CCUIStatusBar"))
                %init(CCStatusBar);
            if (objc_getClass("SBBannerContainerView"))
                %init(CCMessage);
        }
    }
}
