// ══════════════════════════════════════════════════════════════════════════════
//  LockScreen.xm — ProudLockX
//  iOS 15-16 Rootless uyumlu
//
//  Doğrulanmış kaynaklar:
//    • iOS 16.5 Header Index Browser
//    • iOS 15.7 Runtime Headers
//
//  ✅ DOĞRULANAN CLASS'LAR:
//    CSProminentTimeView          → CoverSheetKit.framework
//    CSProminentSubtitleDateView  → CoverSheetKit.framework
//    CSProminentLabeledElementView→ CoverSheetKit.framework
//    SBFLockScreenDateView        → SpringBoardFoundation.framework
//    SBFLockScreenDateSubtitleView→ SpringBoardFoundation.framework
//    SBLockScreenBatteryChargingViewController → SpringBoard.framework
//    SBLockScreenEmergencyCallViewController   → SpringBoard.framework
//    SBHomeGrabberView            → SpringBoard.framework
//    SBPasscodeNumberPadButton    → SpringBoardUIServices.framework
//    SBUIPasscodeLockViewWithKeyboard → SpringBoardUIServices.framework
//    NCNotificationShortLookView  → UserNotificationsUIKit.framework
//    NCNotificationListCell       → UserNotificationsUIKit.framework
//    NCNotificationListHeaderTitleView → UserNotificationsUIKit.framework
//    NCNotificationLongLookView   → UserNotificationsUIKit.framework
//    NCNotificationContentView    → UserNotificationsUIKit.framework
//    SBNotificationBannerDestination  → SpringBoard.framework
//    CSCoverSheetFlyInSettings    → CoverSheet.framework
//    CSCoverSheetViewController   → CoverSheet.framework
//
//  ❌ KALDIRILAN YANLIŞ CLASS'LAR:
//    SBChargingView, SBBatteryChargingView  → YOK iOS 16'da
//    SBEmergencyCallButtonView, CSEmergencyView → YOK iOS 16'da
//    SBGrabberView, SBUIGrabberView         → YOK iOS 16'da
//    SBUIPasscodeEntryFieldView             → YOK iOS 16'da
//    NCNotificationCell, NCNotificationTimeLabel → YOK iOS 16'da
//    NCNotificationListHeaderView           → YOK iOS 16'da
//    NCNotificationClearAllButton           → YOK iOS 16'da
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

static NSString *_lsPlistPath(void) {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *p1 = @"/var/jb/var/mobile/Library/Preferences/com.un1ockdev.proudlockx.plist";
    if ([fm fileExistsAtPath:p1]) return p1;
    return @"/var/mobile/Library/Preferences/com.un1ockdev.proudlockx.plist";
}

static BOOL       _lsLoaded                = NO;
static BOOL       _lsTweakEnabled          = YES;
static BOOL       _lsHideClock             = NO;
static BOOL       _lsHideDate              = NO;
static BOOL       _lsCustomClockSize       = NO;
static CGFloat    _lsClockFontSize         = 70.0;
static BOOL       _lsCustomClockFont       = NO;
static NSString  *_lsClockFontName         = nil;
static BOOL       _lsCustomSubtitleFormat  = NO;
static NSString  *_lsSubtitleFormat        = nil;
static BOOL       _lsHideChargingNotif     = NO;
static BOOL       _lsHideEmergency         = NO;
static BOOL       _lsHideSwipeText         = NO;
static BOOL       _lsCustomSwipeText       = NO;
static NSString  *_lsSwipeText             = nil;
static BOOL       _lsHideCCHandle          = NO;
static BOOL       _lsHideOldNotifText      = NO;
static BOOL       _lsDisableFlyIn          = NO;
static BOOL       _lsHidePasscodeTitle     = NO;
static BOOL       _lsCustomPasscodeTitle   = NO;
static NSString  *_lsPasscodeTitle         = nil;
static BOOL       _lsPasscodeHaptic        = NO;
static BOOL       _lsCustomNotifHeight     = NO;
static CGFloat    _lsNotifHeight           = 110.0;
static BOOL       _lsHideNotifButtons      = NO;
static BOOL       _lsHideNotifAppNames     = NO;
static BOOL       _lsHideNotifTime         = NO;
static BOOL       _lsHideNCTitle           = NO;
static BOOL       _lsCustomNCTitle         = NO;
static NSString  *_lsNCTitleText           = nil;
static BOOL       _lsHideQuickActionBG     = NO;

static void _lsLoad(void) {
    if (_lsLoaded) return;
    NSDictionary *p = [NSDictionary dictionaryWithContentsOfFile:_lsPlistPath()] ?: @{};
    id tv = p[@"tweakEnabled"];
    _lsTweakEnabled = tv ? [tv boolValue] : YES;
#define LSBOOL(k) (_lsTweakEnabled && [p[k] boolValue])
    _lsHideClock            = LSBOOL(@"hideLockClock");
    _lsHideDate             = LSBOOL(@"hideLockDate");
    _lsCustomClockSize      = LSBOOL(@"customClockFontSize");
    id csz = p[@"clockFontSize"];
    _lsClockFontSize        = csz ? [csz floatValue] : 70.0;
    _lsCustomClockFont      = LSBOOL(@"customClockFont");
    NSString *cfn = p[@"clockFontName"];
    _lsClockFontName        = cfn.length ? [cfn copy] : nil;
    _lsCustomSubtitleFormat = LSBOOL(@"customSubtitleFormat");
    NSString *sf = p[@"clockSubtitleFormat"];
    _lsSubtitleFormat       = sf.length ? [sf copy] : nil;
    _lsHideChargingNotif    = LSBOOL(@"hideChargingNotification");
    _lsHideEmergency        = LSBOOL(@"hideEmergencyButton");
    _lsHideSwipeText        = LSBOOL(@"hideSwipeUpText");
    _lsCustomSwipeText      = LSBOOL(@"customSwipeUpText");
    NSString *sut = p[@"swipeUpText"];
    _lsSwipeText            = sut.length ? [sut copy] : nil;
    _lsHideCCHandle         = LSBOOL(@"hideCCHandle");
    _lsHideOldNotifText     = LSBOOL(@"hideOldNotifText");
    _lsDisableFlyIn         = LSBOOL(@"disableFlyInAnimation");
    _lsHidePasscodeTitle    = LSBOOL(@"hidePasscodeTitle");
    _lsCustomPasscodeTitle  = LSBOOL(@"customPasscodeTitle");
    NSString *pct = p[@"customPasscodeTitleText"];
    _lsPasscodeTitle        = pct.length ? [pct copy] : nil;
    _lsPasscodeHaptic       = LSBOOL(@"passcodeHaptic");
    _lsCustomNotifHeight    = LSBOOL(@"customNotifHeight");
    id nh = p[@"notifHeightValue"];
    _lsNotifHeight          = nh ? [nh floatValue] : 110.0;
    _lsHideNotifButtons     = LSBOOL(@"hideNotifButtons");
    _lsHideNotifAppNames    = LSBOOL(@"hideNotifAppNames");
    _lsHideNotifTime        = LSBOOL(@"hideNotifTimeLabels");
    _lsHideNCTitle          = LSBOOL(@"hideNCTitle");
    _lsCustomNCTitle        = LSBOOL(@"customNCTitle");
    NSString *nct = p[@"ncTitleText"];
    _lsNCTitleText          = nct.length ? [nct copy] : nil;
    _lsHideQuickActionBG    = LSBOOL(@"hideQuickActionBG");
#undef LSBOOL
    _lsLoaded = YES;
}

static void _lsPrefsChanged(CFNotificationCenterRef c __unused, void *o __unused,
                             CFStringRef n __unused, const void *ob __unused,
                             CFDictionaryRef i __unused) { _lsLoaded = NO; }

// ── Forward Declarations ─────────────────────────────────────────────────────

// ✅ iOS 16 saat (CoverSheetKit → CSProminentTextElementView)
// textLabel: CSProminentTextElementView'dan geliyor (iOS 16.5 header doğrulandı)
// overrideString: tarih/saat metnini override etmek için
@interface CSProminentTimeView : UIView
@property (readonly, nonatomic) UILabel *textLabel;
@property (retain, nonatomic) NSString *overrideString;
@property (retain, nonatomic) UIFont *primaryFont;
@end

// ✅ iOS 16 tarih subtitle (CoverSheetKit → CSProminentTextElementView)
@interface CSProminentSubtitleDateView : UIView
@property (readonly, nonatomic) UILabel *textLabel;
@property (retain, nonatomic) NSString *overrideString;
@property (retain, nonatomic) UIFont *primaryFont;
@end

// ✅ iOS 16 swipe/kaydır metni (CoverSheetKit)
@interface CSProminentLabeledElementView : UIView
- (UILabel *)label;
@end

// ✅ iOS 15 saat/tarih (SpringBoardFoundation)
@interface SBFLockScreenDateView : UIView
@property (nonatomic, retain) UILabel *timeLabel;
@property (nonatomic, retain) UILabel *dateLabel;
@end

// ✅ iOS 15 tarih subtitle (SpringBoardFoundation)
@interface SBFLockScreenDateSubtitleView : UIView
- (UILabel *)subtitleLabel;
@end

// ✅ Şarj bildirimi — iOS 16 doğru class (SpringBoard)
@interface SBLockScreenBatteryChargingViewController : UIViewController
@end

// ✅ Acil buton — iOS 16 doğru class (SpringBoard)
@interface SBLockScreenEmergencyCallViewController : UIViewController
@end
@interface SBLockScreenEmergencyDialerController : NSObject
@end

// ✅ CC tutamacı — iOS 16 doğru class (SpringBoard)
@interface SBHomeGrabberView : UIView
@end

// ✅ Bildirim hücresi — iOS 16 (UserNotificationsUIKit)
@interface NCNotificationShortLookView : UIView
- (UILabel *)applicationNameLabel;
- (UILabel *)relativeTimeLabel;
@end

// Forward declaration — NCNotificationViewController (UserNotificationsUIKit)
@class NCNotificationViewController;

// ✅ Bildirim liste hücresi — iOS 16 (UserNotificationsUIKit)
@interface NCNotificationListCell : UIView
// manageButton/viewButton iOS 16.5 header'da YOK — subview taramasıyla bulunuyor
@property (readonly, nonatomic) NCNotificationViewController *notificationViewController;
@end

// ✅ Bildirim içerik view'u — iOS 16.5 header doğrulandı
// primaryLabel/secondaryLabel/summaryLabel VAR
@interface NCNotificationContentView : UIView
@property (retain, nonatomic) UILabel *primaryLabel;
@property (retain, nonatomic) UILabel *primarySubtitleLabel;
@property (readonly, nonatomic) UILabel *secondaryLabel;
@end

// ✅ NC başlığı — iOS 16 doğru class (UserNotificationsUIKit)
@interface NCNotificationListHeaderTitleView : UIView
- (UILabel *)titleLabel;
@end

// ✅ Bildirim uzun bak (UserNotificationsUIKit)
@interface NCNotificationLongLookView : UIView
@end

// ✅ Fly-in animasyonu (SpringBoard)
@interface SBNotificationBannerDestination : NSObject
- (double)_bannerRevealAnimationDuration;
- (double)_bannerHideAnimationDuration;
@end

// ✅ Fly-in settings (CoverSheet)
@interface CSCoverSheetFlyInSettings : NSObject
@property (nonatomic) double duration;
@end

@interface CSCoverSheetViewController : UIViewController
@end

// ✅ Parola lock view — iOS 16 doğru class (SpringBoardUIServices)
// ✅ iOS 16.5 header doğrulandı: Keyboard→Keypad
// statusText/statusSubtitleText: SBUIPasscodeLockViewBase'den miras
@interface SBUIPasscodeLockViewWithKeypad : UIView
@property (copy, nonatomic) NSString *statusText;
@property (copy, nonatomic) NSString *statusSubtitleText;
- (void)updateStatusText:(id)text subtitle:(id)subtitle animated:(BOOL)animated;
@end

// SBUIPasscodeLockViewBase — iOS 16.5 header doğrulandı
// titleLabel YOK — statusText property kullan
@interface SBUIPasscodeLockViewBase : UIView
@property (copy, nonatomic) NSString *statusText;
@property (copy, nonatomic) NSString *statusSubtitleText;
- (void)updateStatusText:(id)text subtitle:(id)subtitle animated:(BOOL)animated;
@end

// ✅ Parola numpad butonu (SpringBoardUIServices)
@interface SBPasscodeNumberPadButton : UIControl
@end

// Hızlı işlem arka planı
@interface CSQuickActionsView : UIView
@end

@interface SBDashBoardQuickActionsBackgroundView : UIView
@end

// ══════════════════════════════════════════════════════════════════════════════
//  1. SAAT YAZI TİPİ / BOYUTU / GİZLE
// ══════════════════════════════════════════════════════════════════════════════

%group LockClock

// ── iOS 16 — CSProminentTimeView ─────────────────────────────────────────────
%hook CSProminentTimeView

- (void)layoutSubviews {
    %orig;
    _lsLoad();
    if (_lsHideClock) {
        self.hidden = YES;
        return;
    }
    // textLabel: CSProminentTextElementView'dan geliyor (iOS 16.5 header doğrulandı)
    UILabel *lbl = self.textLabel;
    if (!lbl) return;
    if (_lsCustomClockSize || _lsCustomClockFont) {
        CGFloat sz = _lsCustomClockSize ? _lsClockFontSize : lbl.font.pointSize;
        UIFont *f = (_lsCustomClockFont && _lsClockFontName)
            ? [UIFont fontWithName:_lsClockFontName size:sz]
            : [UIFont systemFontOfSize:sz weight:UIFontWeightThin];
        if (f) lbl.font = f;
    }
}

%end

// ── iOS 16 — CSProminentSubtitleDateView ─────────────────────────────────────
%hook CSProminentSubtitleDateView

- (void)layoutSubviews {
    %orig;
    _lsLoad();
    if (_lsHideDate) {
        self.hidden = YES;
        return;
    }
    if (_lsCustomSubtitleFormat && _lsSubtitleFormat) {
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        fmt.dateFormat = _lsSubtitleFormat;
        // overrideString: CSProminentTextElementView'dan geliyor, tarihi override eder
        self.overrideString = [fmt stringFromDate:[NSDate date]];
    }
}

%end

// SBFLockScreenDateView — TweakSpring.xm içinde yönetiliyor
// LockScreen.xm'de duplicate hook yok — CRASH önleme

// ── iOS 15 tarih subtitle ────────────────────────────────────────────────────
%hook SBFLockScreenDateSubtitleView

- (void)layoutSubviews {
    %orig;
    _lsLoad();
    if (!_lsCustomSubtitleFormat || !_lsSubtitleFormat) return;
    UILabel *lbl = [self subtitleLabel];
    if (!lbl) return;
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = _lsSubtitleFormat;
    lbl.text = [fmt stringFromDate:[NSDate date]];
}

%end

%end // LockClock

// ══════════════════════════════════════════════════════════════════════════════
//  2. ŞARJ BİLDİRİMİNİ GİZLE
//
//  ✅ iOS 16 DOĞRU CLASS: SBLockScreenBatteryChargingViewController
//  ❌ YANLIŞ: SBChargingView, SBBatteryChargingView (iOS 16'da yok)
// ══════════════════════════════════════════════════════════════════════════════

%group ChargingNotif

%hook SBLockScreenBatteryChargingViewController

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    _lsLoad();
    if (_lsHideChargingNotif) self.view.hidden = YES;
}

- (void)viewDidLayoutSubviews {
    %orig;
    _lsLoad();
    if (_lsHideChargingNotif) self.view.hidden = YES;
}

%end

%end // ChargingNotif

// ══════════════════════════════════════════════════════════════════════════════
//  3. BİLDİRİM APP ADI + ZAMAN GİZLE
//
//  ✅ iOS 16 DOĞRU CLASS'LAR:
//    NCNotificationShortLookView — applicationNameLabel, relativeTimeLabel
//    NCNotificationListCell      — liste hücresi
//
//  ❌ YANLIŞ: NCNotificationCell, NCNotificationTimeLabel (iOS 16'da yok)
// ══════════════════════════════════════════════════════════════════════════════

%group NotifLabels

%hook NCNotificationShortLookView

- (void)layoutSubviews {
    %orig;
    _lsLoad();

    // ✅ FIX: iOS 16.7.11'de applicationNameLabel / relativeTimeLabel
    // selector'ları mevcut olmayabiliyor → doesNotRecognizeSelector crash'i.
    // respondsToSelector: guard ile kontrol et; yoksa subview taramasına düş.

    if (_lsHideNotifAppNames) {
        if ([self respondsToSelector:@selector(applicationNameLabel)]) {
            UILabel *nameLbl = [self applicationNameLabel];
            if (nameLbl) nameLbl.hidden = YES;
        } else {
            // Fallback: app adı genellikle en soldaki/üstteki küçük label'dır
            for (UIView *sub in self.subviews) {
                if ([sub isKindOfClass:[UILabel class]]) {
                    UILabel *lbl = (UILabel *)sub;
                    // Küçük font → muhtemelen app adı (saat/büyük başlık değil)
                    if (lbl.font.pointSize < 18.0) {
                        lbl.hidden = YES;
                        break;
                    }
                }
            }
        }
    }

    if (_lsHideNotifTime) {
        if ([self respondsToSelector:@selector(relativeTimeLabel)]) {
            UILabel *timeLbl = [self relativeTimeLabel];
            if (timeLbl) timeLbl.hidden = YES;
        } else {
            // Fallback: zaman label'ı genellikle sağ üst köşede, kısa metin
            for (UIView *sub in self.subviews) {
                if (![sub isKindOfClass:[UILabel class]]) continue;
                UILabel *lbl = (UILabel *)sub;
                NSString *txt = lbl.text;
                // Kısa metin (≤6 karakter) ve CGRect yatayda sağda → zaman label'ı
                if (txt.length > 0 && txt.length <= 6 && lbl.frame.origin.x > self.bounds.size.width * 0.5) {
                    lbl.hidden = YES;
                }
            }
        }
    }
}

%end

// NCNotificationContentView — genel içerik; subview tarama ile label'ları gizle
%hook NCNotificationContentView

- (void)layoutSubviews {
    %orig;
    _lsLoad();
    if (!_lsHideNotifTime && !_lsHideNotifAppNames) return;

    static BOOL _guard = NO;
    if (_guard) return;
    _guard = YES;

    for (UIView *sub in self.subviews) {
        if (![sub isKindOfClass:[UILabel class]]) continue;
        UILabel *lbl = (UILabel *)sub;
        NSString *txt = lbl.text;
        if (!txt.length) continue;

        // Zaman label'ı: kısa ve rakam/harf içeriyor (örn "2s", "5m", "1h")
        if (_lsHideNotifTime && txt.length <= 6) {
            // Basit heuristic: sadece zaman gibi görünen kısa label'ları gizle
            lbl.hidden = YES;
        }
    }

    _guard = NO;
}

%end

%end // NotifLabels

// ══════════════════════════════════════════════════════════════════════════════
//  4. NC BAŞLIĞI GİZLE/DEĞİŞTİR
//
//  ✅ iOS 16 DOĞRU CLASS: NCNotificationListHeaderTitleView
//  ❌ YANLIŞ: NCNotificationListHeaderView (iOS 16'da yok)
// ══════════════════════════════════════════════════════════════════════════════

%group NCTitle

%hook NCNotificationListHeaderTitleView

- (void)layoutSubviews {
    %orig;
    _lsLoad();
    UILabel *lbl = [self titleLabel];
    if (!lbl) {
        // titleLabel property yoksa subview tara
        for (UIView *sub in self.subviews) {
            if ([sub isKindOfClass:[UILabel class]]) {
                lbl = (UILabel *)sub;
                break;
            }
        }
    }
    if (!lbl) return;
    if (_lsHideNCTitle) { lbl.hidden = YES; return; }
    if (_lsCustomNCTitle && _lsNCTitleText) lbl.text = _lsNCTitleText;
}

%end

%end // NCTitle

// ══════════════════════════════════════════════════════════════════════════════
//  5. ACİL DURUM DÜĞMESİNİ GİZLE
//
//  ✅ iOS 16 DOĞRU CLASS: SBLockScreenEmergencyCallViewController
//  ❌ YANLIŞ: SBEmergencyCallButtonView, CSEmergencyView (iOS 16'da yok)
// ══════════════════════════════════════════════════════════════════════════════

%group EmergencyButton

%hook SBLockScreenEmergencyCallViewController

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    _lsLoad();
    if (_lsHideEmergency) self.view.hidden = YES;
}

- (void)viewDidLayoutSubviews {
    %orig;
    _lsLoad();
    if (_lsHideEmergency) self.view.hidden = YES;
}

%end

%end // EmergencyButton

// ══════════════════════════════════════════════════════════════════════════════
//  6. "KİLİDİ AÇMAK İÇİN KAYDIR/BASIN" METNİ
//
//  ✅ iOS 16: CSProminentLabeledElementView.label
//     DOĞRULANDI: CoverSheetKit.framework iOS 16.5
// ══════════════════════════════════════════════════════════════════════════════

%group SwipeText

%hook CSProminentLabeledElementView

- (void)layoutSubviews {
    %orig;
    _lsLoad();
    UILabel *lbl = [self label];
    if (!lbl) return;
    // Hint label'ı küçük font ile gelir (saat/tarih'ten ayırt et)
    if (lbl.font.pointSize > 22.0) return;
    if (_lsHideSwipeText) { lbl.text = @""; return; }
    if (_lsCustomSwipeText && _lsSwipeText) lbl.text = _lsSwipeText;
}

%end

%end // SwipeText

// ══════════════════════════════════════════════════════════════════════════════
//  7. KONTROL MERKEZİ TUTAMACINI GİZLE
//
//  ✅ iOS 16 DOĞRU CLASS: SBHomeGrabberView — SpringBoard.framework
//  ❌ YANLIŞ: SBGrabberView, SBUIGrabberView (iOS 16'da yok)
// ══════════════════════════════════════════════════════════════════════════════

%group CCHandle

%hook SBHomeGrabberView

- (void)didMoveToWindow {
    %orig;
    _lsLoad();
    if (!_lsHideCCHandle) return;
    // ✅ FIX: Sync alpha set, didMoveToWindow içinde layout pass cascade'i
    // tetikliyor → app switcher gesture sırasında SBHomeGrabberView üzerinde
    // setHidden: çağrısı yapılıyor ve view'in state'i inconsistent olduğundan
    // NSInternalInconsistencyException → SpringBoard crash.
    // dispatch_async ile bir run loop tick erteleyerek cascade'i kırıyoruz.
    dispatch_async(dispatch_get_main_queue(), ^{
        self.alpha = 0;
    });
}

- (void)layoutSubviews {
    %orig;
    _lsLoad();
    if (_lsHideCCHandle) self.alpha = 0;
}

%end

%end // CCHandle

// ══════════════════════════════════════════════════════════════════════════════
//  8. UÇARAK GİRİŞ ANİMASYONUNU DEVRE DIŞI BIRAK
//
//  ✅ iOS 16:
//    SBNotificationBannerDestination — _bannerRevealAnimationDuration (SpringBoard)
//    CSCoverSheetFlyInSettings       — duration property (CoverSheet)
// ══════════════════════════════════════════════════════════════════════════════

%group FlyInAnimation

%hook SBNotificationBannerDestination

- (double)_bannerRevealAnimationDuration {
    _lsLoad();
    if (_lsDisableFlyIn) return 0.0;
    return %orig;
}

- (double)_bannerHideAnimationDuration {
    _lsLoad();
    if (_lsDisableFlyIn) return 0.0;
    return %orig;
}

%end

%hook CSCoverSheetFlyInSettings

- (double)duration {
    _lsLoad();
    if (_lsDisableFlyIn) return 0.0;
    return %orig;
}

%end

%end // FlyInAnimation

// ══════════════════════════════════════════════════════════════════════════════
//  9. PAROLA EKRANI — Başlık + Haptic
//
//  ✅ iOS 16 DOĞRU CLASS: SBUIPasscodeLockViewWithKeypad (SpringBoardUIServices)
//  ❌ YANLIŞ: SBUIPasscodeLockViewWithKeyboard (iOS 16'da Keypad oldu), SBUIPasscodeEntryFieldView
// ══════════════════════════════════════════════════════════════════════════════

%group PasscodeScreen

// ✅ iOS 16: SBUIPasscodeLockViewWithKeypad
// statusText/statusSubtitleText: SBUIPasscodeLockViewBase'den miras — iOS 16.5 header doğrulandı
%hook SBUIPasscodeLockViewWithKeypad

- (void)layoutSubviews {
    %orig;
    _lsLoad();
    if (!_lsHidePasscodeTitle && !_lsCustomPasscodeTitle) return;
    if (_lsHidePasscodeTitle) {
        // statusText boş string yaparak gizle (hidden yerine — sistem resetleyebilir)
        [self updateStatusText:@"" subtitle:@"" animated:NO];
        return;
    }
    if (_lsCustomPasscodeTitle && _lsPasscodeTitle) {
        [self updateStatusText:_lsPasscodeTitle subtitle:@"" animated:NO];
    }
}

%end

// SBUIPasscodeLockViewBase — aynı API, iOS 16.5 header doğrulandı
%hook SBUIPasscodeLockViewBase

- (void)layoutSubviews {
    %orig;
    _lsLoad();
    if (!_lsHidePasscodeTitle && !_lsCustomPasscodeTitle) return;
    if (_lsHidePasscodeTitle) {
        [self updateStatusText:@"" subtitle:@"" animated:NO];
        return;
    }
    if (_lsCustomPasscodeTitle && _lsPasscodeTitle) {
        [self updateStatusText:_lsPasscodeTitle subtitle:@"" animated:NO];
    }
}

%end

// ✅ DOĞRULANDI: SBPasscodeNumberPadButton — SpringBoardUIServices iOS 16.5
%hook SBPasscodeNumberPadButton

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    %orig;
    _lsLoad();
    if (_lsPasscodeHaptic) {
        UIImpactFeedbackGenerator *g = [[UIImpactFeedbackGenerator alloc]
            initWithStyle:UIImpactFeedbackStyleLight];
        [g prepare];
        [g impactOccurred];
    }
}

%end

%end // PasscodeScreen

// ══════════════════════════════════════════════════════════════════════════════
//  10. BİLDİRİM YÜKSEKLİĞİ + YÖNET/GÖRÜNTÜLE DÜĞMELERİ
//
//  ✅ iOS 16 DOĞRU CLASS: NCNotificationListCell (UserNotificationsUIKit)
// ══════════════════════════════════════════════════════════════════════════════

%group NotifCells

%hook NCNotificationListCell

- (void)layoutSubviews {
    %orig;
    _lsLoad();
    // manageButton/viewButton iOS 16'da bu class'ta yok
    // Buton gizleme: subview taraması ile UIButton'ları bul
    if (_lsHideNotifButtons) {
        for (UIView *sub in self.subviews) {
            if ([sub isKindOfClass:[UIButton class]]) {
                sub.hidden = YES;
            }
        }
        // contentView içindeki butonları da tara
        for (UIView *sub in self.subviews) {
            for (UIView *sub2 in sub.subviews) {
                if ([sub2 isKindOfClass:[UIButton class]]) sub2.hidden = YES;
            }
        }
    }
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize orig = %orig(size);
    _lsLoad();
    if (_lsCustomNotifHeight) return CGSizeMake(orig.width, _lsNotifHeight);
    return orig;
}

%end

%end // NotifCells

// ══════════════════════════════════════════════════════════════════════════════
//  11. HIZLI İŞLEM ARKA PLANINI GİZLE
// ══════════════════════════════════════════════════════════════════════════════

%group QuickActionBG

%hook CSQuickActionsView

- (void)layoutSubviews {
    %orig;
    _lsLoad();
    if (!_lsHideQuickActionBG) return;
    for (UIView *sub in self.subviews) {
        NSString *cls = NSStringFromClass([sub class]);
        if ([cls containsString:@"Background"] ||
            [cls containsString:@"Blur"] ||
            [cls containsString:@"Visual"]) {
            sub.hidden = YES;
        }
    }
}

%end

%hook SBDashBoardQuickActionsBackgroundView

- (void)setHidden:(BOOL)hidden {
    _lsLoad();
    %orig(_lsHideQuickActionBG ? YES : hidden);
}

%end

%end // QuickActionBG

// ══════════════════════════════════════════════════════════════════════════════
//  CONSTRUCTOR
// ══════════════════════════════════════════════════════════════════════════════

%ctor {
    NSLog(@"[PLX-LS] ctor started");
    @autoreleasepool {
        NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
        if (![bid isEqualToString:@"com.apple.springboard"]) return;

        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(), NULL, _lsPrefsChanged,
            CFSTR("com.un1ockdev.proudlockx/prefsupdated"),
            NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

        // iOS 16 saat (CoverSheetKit)
        if (objc_getClass("CSProminentTimeView"))
            %init(LockClock);

        // iOS 16 şarj
        if (objc_getClass("SBLockScreenBatteryChargingViewController"))
            %init(ChargingNotif);

        // iOS 16 bildirim label'ları
        if (objc_getClass("NCNotificationShortLookView") ||
            objc_getClass("NCNotificationContentView"))
            %init(NotifLabels);

        // iOS 16 NC başlık
        if (objc_getClass("NCNotificationListHeaderTitleView"))
            %init(NCTitle);

        // iOS 16 acil buton
        if (objc_getClass("SBLockScreenEmergencyCallViewController"))
            %init(EmergencyButton);

        // iOS 16 swipe text
        if (objc_getClass("CSProminentLabeledElementView"))
            %init(SwipeText);

        // iOS 16 CC handle
        if (objc_getClass("SBHomeGrabberView"))
            %init(CCHandle);

        // Fly-in animasyon
        if (objc_getClass("SBNotificationBannerDestination"))
            %init(FlyInAnimation);

        // Parola
        if (objc_getClass("SBUIPasscodeLockViewWithKeypad") ||
            objc_getClass("SBUIPasscodeLockViewBase"))
            %init(PasscodeScreen);

        // Bildirim hücreleri
        if (objc_getClass("NCNotificationListCell"))
            %init(NotifCells);

        // QA arka plan
        %init(QuickActionBG);
    }
}
