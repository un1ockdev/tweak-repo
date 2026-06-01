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


#ifdef THEOS_PACKAGE_SCHEME_ROOTLESS
  #define PLX_JB_PATH(p)  @"/var/jb" p
#else
  #define PLX_JB_PATH(p)  @p
#endif

static inline int _plxStatusBarGeneration(void) {
    if (objc_getClass("_UIStatusBarVisualProvider_Split828") != nil) return 1;
    if (objc_getClass("_UIStatusBarVisualProvider_Split54")  != nil) return 2;
    if (objc_getClass("_UIStatusBarVisualProvider_Split58")  != nil) return 3;
    return 0;
}

static NSString *_plxPlistPath(void) {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *p1 = @"/var/jb/var/mobile/Library/Preferences/com.un1ockdev.proudlockx.plist";
    if ([fm fileExistsAtPath:p1]) return p1;
    NSString *p2 = @"/var/mobile/Library/Preferences/com.un1ockdev.proudlockx.plist";
    if ([fm fileExistsAtPath:p2]) return p2;
    return p1;
}

static NSDictionary *_plxLoadPrefs(void) {
    return [NSDictionary dictionaryWithContentsOfFile:_plxPlistPath()] ?: @{};
}

// ── Cache ────────────────────────────────────
static BOOL      _cachedTweakEnabled        = YES;
static BOOL      _cachedStatusBar           = NO;
static BOOL      _cachedQuickActions        = YES;
static BOOL      _prefsLoaded               = NO;
static BOOL      _cachedCarrierEnabled      = NO;
static BOOL      _cachedHideHomeIndicator   = NO;
static NSString *_cachedCarrierText         = nil;
static BOOL      _cachedBatteryPercent      = NO;
static BOOL      _cachedHidePageDots        = NO;

// ── YENİ: 9 Özellik Cache ───────────────────
// 1. App Switcher grid modu
static BOOL      _cachedSwitcherGrid        = NO;
// 2. Dock tamamen kapat
static BOOL      _cachedHideDockCompletely  = NO;
// 3. Dock blur stili (0=default,1=transparent,2=dark,3=light)
static NSInteger _cachedDockBlurStyle       = 0;
// 4. Floating Dock
static BOOL      _cachedFloatingDock        = NO;
// 5. App Library ikonunu gizle
static BOOL      _cachedHideALIcon          = NO;
// 6. Recent apps sayısı (1-10)
static NSInteger _cachedRecentAppsCount     = 3;
// 7. Sayfa noktaları → zaten mevcut (_cachedHidePageDots)
// 8. Apple Account (Apple ID adı özelleştirme)
static BOOL      _cachedCustomAppleID       = NO;
static NSString *_cachedAppleIDFirstName    = nil;
static NSString *_cachedAppleIDLastName     = nil;
// 9. iPad stili (notch/layout simülasyonu)
static BOOL      _cachedIPadLayout          = NO;

static void _plxLoadAllPrefs(void) {
    if (_prefsLoaded) return;
    NSDictionary *p = _plxLoadPrefs();
    id tweakVal = p[@"tweakEnabled"];
    _cachedTweakEnabled      = tweakVal ? [tweakVal boolValue] : YES;
    _cachedStatusBar         = [p[@"statusBarStyle"]      boolValue];
    id qaVal = p[@"quickActionsEnabled"];
    _cachedQuickActions      = qaVal ? [qaVal boolValue] : YES;
    _cachedCarrierEnabled    = [p[@"customCarrierEnabled"] boolValue];
    _cachedHideHomeIndicator = [p[@"hideHomeIndicator"]    boolValue];
    NSString *ct = p[@"customCarrierText"];
    _cachedCarrierText = (ct.length > 0) ? [ct copy] : nil;
    id bpVal = p[@"batteryPercentInside"];
    _cachedBatteryPercent    = _cachedTweakEnabled ? [bpVal boolValue] : NO;
    _cachedHidePageDots      = _cachedTweakEnabled ? [p[@"hidePageDots"] boolValue] : NO;

    // ── YENİ cache yükleme ──────────────────
    _cachedSwitcherGrid       = _cachedTweakEnabled ? [p[@"switcherGridMode"]    boolValue] : NO;
    _cachedHideDockCompletely = _cachedTweakEnabled ? [p[@"hideDockCompletely"]  boolValue] : NO;
    id dbs = p[@"dockBlurStyle"];
    _cachedDockBlurStyle      = (_cachedTweakEnabled && dbs) ? [dbs integerValue] : 0;
    _cachedFloatingDock       = _cachedTweakEnabled ? [p[@"floatingDockEnabled"] boolValue] : NO;
    _cachedHideALIcon         = _cachedTweakEnabled ? [p[@"hideAppLibraryIcon"]  boolValue] : NO;
    id rac = p[@"recentAppsCount"];
    _cachedRecentAppsCount    = (_cachedTweakEnabled && rac) ? [rac integerValue] : 3;
    _cachedCustomAppleID      = _cachedTweakEnabled ? [p[@"customAppleIDEnabled"] boolValue] : NO;
    NSString *fn = p[@"appleIDFirstName"];
    NSString *ln = p[@"appleIDLastName"];
    _cachedAppleIDFirstName   = (fn.length > 0) ? [fn copy] : nil;
    _cachedAppleIDLastName    = (ln.length > 0) ? [ln copy] : nil;
    _cachedIPadLayout         = _cachedTweakEnabled ? [p[@"iPadLayoutEnabled"] boolValue] : NO;

    _prefsLoaded = YES;
}

static BOOL plxTweakEnabled(void)       { _plxLoadAllPrefs(); return _cachedTweakEnabled; }
static BOOL isEnabled(void)             { _plxLoadAllPrefs(); return _cachedTweakEnabled && _cachedStatusBar; }
static BOOL plxQuickActionsEnabled(void){ _plxLoadAllPrefs(); return _cachedTweakEnabled && _cachedQuickActions; }
static BOOL plxHideHomeIndicator(void)  { _plxLoadAllPrefs(); return _cachedTweakEnabled && _cachedHideHomeIndicator; }

static void prefsChanged(CFNotificationCenterRef c __unused,
                         void *o __unused,
                         CFStringRef n __unused,
                         const void *obj __unused,
                         CFDictionaryRef i __unused) {
    _prefsLoaded = NO;
}

// ── Forward Declarations ─────────────────────
@interface CSCoverSheetViewController : UIViewController
- (id)quickActionsView;
- (BOOL)_shouldShowQuickActions;
@end

@interface SBDashBoardViewController : UIViewController
- (id)quickActionsView;
- (BOOL)_shouldShowQuickActions;
@end

@interface SBDashBoardQuickActionsViewController : UIViewController
- (BOOL)isActive;
- (BOOL)_shouldBeActive;
@end

@interface SBFLockScreenDateView : UIView
@property (nonatomic, retain) UILabel *timeLabel;
@property (nonatomic, retain) UILabel *dateLabel;
@end

@interface _UIBatteryView : UIView
@property (nonatomic) CGFloat chargePercent;
@property (nonatomic) NSInteger chargingState;
@property (nonatomic) BOOL saverModeActive;
- (void)_updatePercentage;
- (BOOL)_currentlyShowsPercentage;
- (void)setShowsPercentage:(BOOL)arg0;
@end

@interface _UIStaticBatteryView : _UIBatteryView
- (void)_createFillLayer;
@end

@interface CSQuickActionsView : UIView
- (BOOL)_prototypingAllowsButtons;
- (BOOL)_hasButtons;
- (BOOL)canShowButtons;
- (void)_layoutQuickActionButtons;
@end

// Dock
@interface SBDockView : UIView
- (void)setHidden:(BOOL)hidden;
@end

@interface SBFloatingDockViewController : UIViewController
@end
@interface SBFloatingDockPlatterView : UIView
@end
@interface SBFloatingDockView : UIView
@end

// App Library Icon
@interface SBHLibraryIconView : UIView
@end
@interface SBHLibraryBarButton : UIControl
@end

// iPad Layout / Recent apps
@interface SBIconListGridLayoutConfiguration : NSObject
- (UIEdgeInsets)portraitLayoutInsets;
@end

// Apple Account (Settings)
@interface PSUIAppleAccountCell : UITableViewCell
@end
@interface PSAccountHeaderCell : UITableViewCell
@end

// ══════════════════════════════════════════════
// 1. STATUS BAR GRUPLARI
// ══════════════════════════════════════════════
%group StatusBar_iOS16
%hook _UIStatusBarVisualProvider_iOS
+ (Class)class {
    if (isEnabled()) return %c(_UIStatusBarVisualProvider_Split828);
    return %orig;
}
%end
%hook SBHDefaultIconListLayoutProvider
- (UIEdgeInsets)portraitLayoutInsets {
    UIEdgeInsets orig = %orig;
    if (isEnabled()) return UIEdgeInsetsMake(orig.top + 10, orig.left, orig.bottom, orig.right);
    return orig;
}
%end
%end

%group StatusBar_iOS12_15
%hook _UIStatusBarVisualProvider_iOS
+ (Class)class {
    if (isEnabled()) return %c(_UIStatusBarVisualProvider_Split54);
    return %orig;
}
%end
%hook _UIStatusBarVisualProvider_Split54
+ (CGSize)notchSize { CGSize orig = %orig; return CGSizeMake(orig.width, 18); }
+ (double)height { return 20; }
%end
%hook SBIconListGridLayoutConfiguration
- (UIEdgeInsets)portraitLayoutInsets {
    UIEdgeInsets x = %orig;
    NSUInteger rows = MSHookIvar<NSUInteger>(self, "_numberOfPortraitRows");
    if (rows < 4 || rows == 3 || !isEnabled()) return x;
    UIWindowScene *_plxScene1 = (UIWindowScene *)[[[UIApplication sharedApplication] connectedScenes] anyObject];
    CGFloat sbHeight = _plxScene1.statusBarManager.statusBarFrame.size.height;
    if (sbHeight <= 20.0) return x;
    return UIEdgeInsetsMake(x.top + 10, x.left, x.bottom, x.right);
}
%end
%end


// ══════════════════════════════════════════════
// 2. OPERATÖR ADI GRUBU
// ══════════════════════════════════════════════
%group CarrierText
static BOOL _plxIsReplacing = NO;
static inline BOOL _plxIsCarrier(id text) {
    if (!text || [text length] == 0) return NO;
    if ([text containsString:@":"]) return NO;
    NSArray *skip = @[@"LTE", @"5G", @"4G", @"3G", @"2G", @"EDGE", @"GPRS",
                      @"HSPA", @"HSPA+", @"WCDMA", @"CDMA", @"1x", @"NR"];
    for (NSString *s in skip) { if ([text isEqualToString:s]) return NO; }
    if ([text rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]].location == NSNotFound) return NO;
    return YES;
}
%hook _UIStatusBarStringView
- (void)setOriginalText:(id)text {
    if (_plxIsReplacing) { %orig; return; }
    isEnabled();
    if (!_cachedCarrierEnabled || !_cachedCarrierText || !_plxIsCarrier(text)) { %orig; return; }
    _plxIsReplacing = YES;
    %orig(_cachedCarrierText);
    _plxIsReplacing = NO;
}
- (void)setText:(NSString *)text {
    if (_plxIsReplacing) { %orig; return; }
    isEnabled();
    if (!_cachedCarrierEnabled || !_cachedCarrierText || !_plxIsCarrier(text)) { %orig; return; }
    _plxIsReplacing = YES;
    %orig(_cachedCarrierText);
    _plxIsReplacing = NO;
}
%end
%end

// ══════════════════════════════════════════════
// 3. PROUDLOCKX ANA GRUBU
// ══════════════════════════════════════════════
%group ProudLockX

// Kilit Ekranı Offset
static CGFloat _plxLockScreenOffset = 0;
static BOOL    _plxDateViewShifted  = NO;
static CGFloat _plxOriginalStatusBarHeight = -1;
%hook SBFLockScreenDateView
- (id)initWithFrame:(CGRect)arg1 {
    _plxDateViewShifted = NO;
    if (isEnabled()) {
        UIWindowScene *_plxScene2 = (UIWindowScene *)[[[UIApplication sharedApplication] connectedScenes] anyObject];
        CGFloat currentH = _plxScene2.statusBarManager.statusBarFrame.size.height;
        if (_plxOriginalStatusBarHeight < 0) _plxOriginalStatusBarHeight = 20.0;
        CGFloat diff = currentH - _plxOriginalStatusBarHeight;
        _plxLockScreenOffset = (diff > 4.0) ? diff : 0;
    } else _plxLockScreenOffset = 0;
    return %orig;
}
- (void)layoutSubviews {
    %orig;
    // ── Frame offset (sadece statusbar stil için) ──
    // iOS 16'da SBFLockScreenDateView sadece container — timeLabel/dateLabel YOK.
    // Saat/tarih gizleme LockScreen.xm'de CSProminentTimeView üzerinden yapılıyor.
    if (isEnabled() && _plxLockScreenOffset > 0 && !_plxDateViewShifted) {
        _plxDateViewShifted = YES;
        CGRect f = self.frame;
        if (f.origin.y < _plxLockScreenOffset) {
            f.origin.y += _plxLockScreenOffset;
            self.frame = f;
        }
    }
}
- (void)setFrame:(CGRect)frame {
    %orig;
    if (frame.origin.y < _plxLockScreenOffset) _plxDateViewShifted = NO;
}
%end

// Biyometri
%hook SBUIBiometricResource
- (id)init {
    id r = %orig;
    if (r && plxTweakEnabled()) {
        Ivar mesa  = class_getInstanceVariable([r class], "_hasMesaHardware");
        Ivar pearl = class_getInstanceVariable([r class], "_hasPearlHardware");
        if (mesa && pearl) {
            MSHookIvar<BOOL>(r, "_hasMesaHardware")  = NO;
            MSHookIvar<BOOL>(r, "_hasPearlHardware") = YES;
        }
    }
    return r;
}
%end
%hook SBUIPasscodeBiometricResource
- (BOOL)hasPearlSupport { return plxTweakEnabled() ? YES : %orig; }
- (BOOL)hasMesaSupport  { return plxTweakEnabled() ? NO  : %orig; }
%end

// QuickActions
%hook CSCoverSheetViewController
- (id)quickActionsView { return %orig; }
- (BOOL)_shouldShowQuickActions {
    if (!plxQuickActionsEnabled()) return NO;
    return %orig;
}
%end
%hook SBDashBoardViewController
- (id)quickActionsView { return %orig; }
- (BOOL)_shouldShowQuickActions {
    if (!plxQuickActionsEnabled()) return NO;
    return %orig;
}
%end
%hook CSQuickActionsView
- (BOOL)_hasButtons {
    if (!plxQuickActionsEnabled()) return NO;
    return %orig;
}
- (BOOL)canShowButtons {
    if (!plxQuickActionsEnabled()) return NO;
    return %orig;
}
- (void)setHidden:(BOOL)arg1 {
    if (!plxQuickActionsEnabled()) { %orig(YES); return; }
    %orig(arg1);
}
- (void)setAlpha:(CGFloat)arg1 {
    if (!plxQuickActionsEnabled()) { %orig(0.0); return; }
    %orig(arg1);
}
- (void)_layoutQuickActionButtons {
    %orig;
    if (!plxQuickActionsEnabled()) {
        self.hidden = YES;
        self.alpha  = 0.0;
    }
}
- (void)refreshSupportedButtons {
    %orig;
    if (!plxQuickActionsEnabled()) return;
    if ([self respondsToSelector:@selector(_addOrRemoveCameraButtonIfNecessary)])
        [self performSelector:@selector(_addOrRemoveCameraButtonIfNecessary)];
    if ([self respondsToSelector:@selector(_addOrRemoveFlashlightButtonIfNecessary)])
        [self performSelector:@selector(_addOrRemoveFlashlightButtonIfNecessary)];
}
%end
%hook SBDashBoardQuickActionsViewController
- (BOOL)isActive      { return plxQuickActionsEnabled() ? YES : %orig; }
- (BOOL)_shouldBeActive { return plxQuickActionsEnabled() ? YES : %orig; }
%end

// Home Indicator
%hook SBFHomeGrabberSettings
- (BOOL)isEnabled {
    if (plxHideHomeIndicator()) return NO;
    return %orig;
}
%end

%end // ProudLockX


// ══════════════════════════════════════════════
// 4. BATARYA GRUBU
// ══════════════════════════════════════════════
static BOOL _plxIsStatusBarBatteryView(UIView *v) {
    UIView *parent = v.superview;
    while (parent) {
        NSString *cls = NSStringFromClass([parent class]);
        if ([cls hasPrefix:@"_UIStatusBar"] || [cls hasPrefix:@"UIStatusBar"])
            return YES;
        parent = parent.superview;
    }
    return NO;
}

@interface _UIStatusBarBatteryItem : NSObject
- (_UIBatteryView *)batteryView;
@end

%group BatterySB_iOS14_16
%hook _UIBatteryView
- (BOOL)_currentlyShowsPercentage {
    _plxLoadAllPrefs();
    if (!_cachedBatteryPercent) return %orig;
    if (_plxIsStatusBarBatteryView(self)) return YES;
    return %orig;
}
- (void)setShowsPercentage:(BOOL)arg0 {
    _plxLoadAllPrefs();
    if (!_cachedBatteryPercent) { %orig(arg0); return; }
    if (_plxIsStatusBarBatteryView(self)) { %orig(YES); return; }
    %orig(arg0);
}
- (void)_updatePercentage {
    %orig;
    _plxLoadAllPrefs();
    if (!_cachedBatteryPercent) return;
    if (_plxIsStatusBarBatteryView(self))
        [self setShowsPercentage:YES];
}
- (void)didMoveToWindow {
    %orig;
    _plxLoadAllPrefs();
    if (!_cachedBatteryPercent) return;
    if (_plxIsStatusBarBatteryView(self))
        [self setShowsPercentage:YES];
}
%end
%hook _UIStaticBatteryView
- (void)setShowsPercentage:(BOOL)arg0 {
    _plxLoadAllPrefs();
    if (!_cachedBatteryPercent) { %orig(arg0); return; }
    if (_plxIsStatusBarBatteryView(self)) { %orig(YES); return; }
    %orig(arg0);
}
- (void)_createFillLayer {
    %orig;
    _plxLoadAllPrefs();
    if (!_cachedBatteryPercent) return;
    if (_plxIsStatusBarBatteryView(self))
        [self setShowsPercentage:YES];
}
%end
%end


// ══════════════════════════════════════════════
// 5. HİDE UI GRUBU (Sayfa Noktaları + Arama)
// ══════════════════════════════════════════════
static BOOL plxHidePageDotsAndSearch(void) {
    _plxLoadAllPrefs();
    return _cachedTweakEnabled && _cachedHidePageDots;
}

@interface SBIconListPageControl : UIView
@end
@interface SBSearchPillView : UIView
@end
@interface SBSearchScrollView : UIView
@end

%group HideUI
%hook SBIconListPageControl
- (void)setHidden:(BOOL)arg1 {
    if (plxHidePageDotsAndSearch()) { %orig(YES); return; }
    %orig(arg1);
}
- (void)setAlpha:(CGFloat)arg1 {
    if (plxHidePageDotsAndSearch()) { %orig(0.0); return; }
    %orig(arg1);
}
- (void)layoutSubviews {
    %orig;
    if (plxHidePageDotsAndSearch()) { self.hidden = YES; self.alpha = 0.0; }
}
- (void)didMoveToWindow {
    %orig;
    if (plxHidePageDotsAndSearch()) { self.hidden = YES; self.alpha = 0.0; }
}
%end
%hook SBSearchPillView
- (void)setHidden:(BOOL)arg1 {
    if (plxHidePageDotsAndSearch()) { %orig(YES); return; }
    %orig(arg1);
}
- (void)setAlpha:(CGFloat)arg1 {
    if (plxHidePageDotsAndSearch()) { %orig(0.0); return; }
    %orig(arg1);
}
- (void)layoutSubviews {
    %orig;
    if (plxHidePageDotsAndSearch()) { self.hidden = YES; self.alpha = 0.0; }
}
- (void)didMoveToWindow {
    %orig;
    if (plxHidePageDotsAndSearch()) { self.hidden = YES; self.alpha = 0.0; }
}
- (void)setFrame:(CGRect)frame {
    %orig(frame);
    if (plxHidePageDotsAndSearch()) { self.hidden = YES; self.alpha = 0.0; }
}
%end
%hook SBSearchScrollView
- (void)setHidden:(BOOL)arg1 {
    if (plxHidePageDotsAndSearch()) { %orig(YES); return; }
    %orig(arg1);
}
- (void)setAlpha:(CGFloat)arg1 {
    if (plxHidePageDotsAndSearch()) { %orig(0.0); return; }
    %orig(arg1);
}
- (void)layoutSubviews {
    %orig;
    if (plxHidePageDotsAndSearch()) { self.hidden = YES; self.alpha = 0.0; }
}
- (void)didMoveToWindow {
    %orig;
    if (plxHidePageDotsAndSearch()) { self.hidden = YES; self.alpha = 0.0; }
}
%end
%end // HideUI


// ══════════════════════════════════════════════
// 6. YENİ: APP SWITCHER GRUBU
//
// switcherGridMode = YES → Grid layout (2 sütun)
//                   NO  → Default deck layout
// SBFluidSwitcherViewController: ana switcher controller
// SBFluidSwitcherItemContainer: her kart
// ══════════════════════════════════════════════

@interface SBFluidSwitcherViewController : UIViewController
- (NSInteger)numberOfColumns;
- (void)setNumberOfColumns:(NSInteger)n;
@end
@interface SBFluidSwitcherItemContainer : UIView
- (CGFloat)_cardCornerRadiusInSwitcher;
@end
@interface SBReusableSnapshotItemContainer : UIView
@end

%group AppSwitcher

%hook SBFluidSwitcherViewController
- (NSInteger)numberOfColumns {
    _plxLoadAllPrefs();
    if (_cachedSwitcherGrid) return 2;
    return %orig;
}
// Grid modda her kart 1/2 ekran genişliğinde
- (CGSize)_itemSizeForItemContainer:(id)container {
    _plxLoadAllPrefs();
    if (!_cachedSwitcherGrid) return %orig;
    CGSize orig = %orig;
    return CGSizeMake(orig.width * 0.5f, orig.height * 0.85f);
}
%end

%hook SBFluidSwitcherItemContainer
// Grid modda kart köşe yarıçapı biraz küçülsün
- (CGFloat)_cardCornerRadiusInSwitcher {
    _plxLoadAllPrefs();
    return _cachedSwitcherGrid ? 18.0f : %orig;
}
%end

%end // AppSwitcher


// ══════════════════════════════════════════════
// 7. YENİ: DOCK GRUBU
//
// hideDockCompletely → Dock'u tamamen gizle
// dockBlurStyle      → 0=default, 1=transparent, 2=dark, 3=light
// floatingDockEnabled→ Floating dock etkinleştir (Home button cihazlar)
// recentAppsCount    → Floating dock'taki recent app sayısı
// ══════════════════════════════════════════════

%group Dock

@interface SBDockComponent : NSObject
@end
// SBDockView hook SpringBoard.xm'e taşındı — duplicate hook crash önleme

// ── 4. Floating Dock — SBFloatingDockViewController
%hook SBFloatingDockViewController
// Floating dock devre dışıysa switcher açılmasın
- (BOOL)_shouldAddBreadcrumbToActivatingSceneEntity:(id)e
                                          sceneHandle:(id)h
                                withTransitionContext:(id)c {
    _plxLoadAllPrefs();
    if (!_cachedFloatingDock) return NO;
    return %orig;
}
%end

%hook SBFloatingDockView
- (void)setHidden:(BOOL)hidden {
    _plxLoadAllPrefs();
    if (!_cachedFloatingDock) { %orig(YES); return; }
    %orig(hidden);
}
%end

// ── 6. Recent Apps sayısı
// SBFloatingDockSuggestionsModel veya SBDockAppInfoStore üzerinden
@interface SBFloatingDockSuggestionsModel : NSObject
- (NSInteger)maximumNumberOfSuggestions;
@end

%hook SBFloatingDockSuggestionsModel
- (NSInteger)maximumNumberOfSuggestions {
    _plxLoadAllPrefs();
    if (_cachedFloatingDock && _cachedRecentAppsCount > 0)
        return _cachedRecentAppsCount;
    return %orig;
}
%end

// Sabit dock için de recent count (SBDockComponent)
@interface SBIconDockDataSource : NSObject
- (NSInteger)numberOfRecentApps;
@end

%hook SBIconDockDataSource
- (NSInteger)numberOfRecentApps {
    _plxLoadAllPrefs();
    if (_cachedRecentAppsCount > 0)
        return _cachedRecentAppsCount;
    return %orig;
}
%end

%end // Dock


// ══════════════════════════════════════════════
// 8. YENİ: APP LIBRARY İKONU GİZLE
//
// SBHLibraryBarButton → Ana sayfadaki App Library oku/butonu
// SBHLibraryIconView  → App Library ikonu (bazı iOS sürümlerinde)
// ══════════════════════════════════════════════

%group AppLibrary

%hook SBHLibraryBarButton
- (void)setHidden:(BOOL)hidden {
    _plxLoadAllPrefs();
    if (_cachedHideALIcon) { %orig(YES); return; }
    %orig(hidden);
}
- (void)setAlpha:(CGFloat)alpha {
    _plxLoadAllPrefs();
    if (_cachedHideALIcon) { %orig(0.0); return; }
    %orig(alpha);
}
- (void)layoutSubviews {
    %orig;
    _plxLoadAllPrefs();
    if (_cachedHideALIcon) { self.hidden = YES; self.alpha = 0.0; }
}
- (void)didMoveToWindow {
    %orig;
    _plxLoadAllPrefs();
    if (_cachedHideALIcon) { self.hidden = YES; self.alpha = 0.0; }
}
%end

// iOS 15- için farklı sınıf adı
@interface SBHLibraryIconButton : UIControl
@end
%hook SBHLibraryIconButton
- (void)setHidden:(BOOL)hidden {
    _plxLoadAllPrefs();
    if (_cachedHideALIcon) { %orig(YES); return; }
    %orig(hidden);
}
- (void)setAlpha:(CGFloat)alpha {
    _plxLoadAllPrefs();
    if (_cachedHideALIcon) { %orig(0.0); return; }
    %orig(alpha);
}
%end

%end // AppLibrary


// ── Apple Account ── TweakSettings.xm'e taşındı (Preferences.app inject gerekiyor)


// ══════════════════════════════════════════════
// 10. YENİ: iPAD LAYOUT GRUBU
//
// iPadLayoutEnabled → Home button olmayan cihazda
// iPad tarzı durum çubuğu yerleşimi simüle eder
// (tarih + saat yan yana, geniş status bar)
// ══════════════════════════════════════════════

@interface _UIStatusBarVisualProvider_Pad_ForcedCellular : NSObject
@end

%group iPadLayout

// iPad durum çubuğu stili — _UIStatusBarVisualProvider_Pad
%hook _UIStatusBarVisualProvider_iOS
+ (Class)class {
    _plxLoadAllPrefs();
    if (_cachedIPadLayout) {
        Class padClass = objc_getClass("_UIStatusBarVisualProvider_Pad_ForcedCellular");
        if (padClass) return padClass;
    }
    return %orig;
}
%end

// NOT: SBHDefaultIconListLayoutProvider hook'u SpringBoard.xm HomeColumns
// grubunda yönetiliyor — burada duplicate hook OLMAMALI (deadlock/freeze riski).
// iPad layout grid overrideı SpringBoard.xm configureGridSizeClassSizes: hookına
// entegre edilecek.

%end // iPadLayout


// ══════════════════════════════════════════════
// CONSTRUCTOR
// ══════════════════════════════════════════════
%ctor {
    NSLog(@"[PLX-TSp] ctor started");
    @autoreleasepool {
        NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
        if (![bid isEqualToString:@"com.apple.springboard"]) return;

        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(), NULL,
            prefsChanged,
            CFSTR("com.un1ockdev.proudlockx/prefsupdated"),
            NULL, CFNotificationSuspensionBehaviorDeliverImmediately
        );

        int gen = _plxStatusBarGeneration();
        if      (gen == 1) %init(StatusBar_iOS16);
        else if (gen == 2) %init(StatusBar_iOS12_15);

        %init(CarrierText);
        %init(ProudLockX);
        %init(HideUI);
        %init(AppSwitcher);
        %init(Dock);
        %init(AppLibrary);
        %init(iPadLayout);

        // iOS 15+ minimum — BatterySB her zaman aktif
        %init(BatterySB_iOS14_16);
    }
}
