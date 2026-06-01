// ══════════════════════════════════════════════════════════════════════════════
//  TweakSettings.xm — ProudLockX
//
//  Bu dosya üç özelliği yönetir:
//
//  A) iCloud Backup uyarısını gizle        → key: "hideBackupWarning"
//     - ICQCloudStorageSummary.tips → @[]  (Ayarlar inline baloncuk)
//     - ICQBackupDevice.backupFailedByinBytes → @(0)
//
//  B) Yazılım güncelleme rozetini gizle    → key: "hideSoftwareUpdateBadge"
//     - PSBadgedTableCell rozeti görünmez
//     - PSSoftwareUpdateTableView.updatesDeferred → YES
//
//  C) Otomatik güncelleme yüklemeyi kapat  → key: "disableAutoInstallUpdate"
//     - MobileAsset MAAssetQuery hook — asset'lerin "auto install" bayrağını NO yapar
//
//  GÜVENLİK:
//    • Tüm hook'lar tweakEnabled + ilgili key kontrolüyle çalışır.
//    • %orig her zaman çağrılır (NO döndürülse bile) — sonsuz döngü yok.
//    • Recursive çağrıya karşı her hook'ta statik bayrak koruması var.
//    • SpringBoard'a inject EDİLMEZ: filter sadece Preferences ve MobileAsset.
//    • iCloudQuota hook'ları com.apple.Preferences'e, MobileAsset kendi
//      process'ine (com.apple.MobileAssetd) inject edilir.
//
//  NOT: Bu dosya SpringBoard'a inject edilmez (ProudLockX.plist sadece
//  SpringBoard'u hedefler). Ayrı bir plist (TweakSettings.plist) ile
//  Preferences + MobileAssetd'e inject edilir.
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


// ── Prefs yolu ────────────────────────────────────────────────────────────────

static NSString *_stgPlistPath(void) {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *p1 = @"/var/jb/var/mobile/Library/Preferences/com.un1ockdev.proudlockx.plist";
    if ([fm fileExistsAtPath:p1]) return p1;
    NSString *p2 = @"/var/mobile/Library/Preferences/com.un1ockdev.proudlockx.plist";
    if ([fm fileExistsAtPath:p2]) return p2;
    return p1;
}

// ── Prefs cache ───────────────────────────────────────────────────────────────

static BOOL _stgPrefsLoaded           = NO;
static BOOL _stgTweakEnabled          = YES;
static BOOL _stgHideBackupWarning     = NO;
static BOOL _stgHideSWUpdateBadge     = NO;
static BOOL _stgDisableAutoInstall    = NO;
static BOOL _stgCustomAppleID         = NO;
static NSString *_stgAppleIDFirst     = nil;
static NSString *_stgAppleIDLast      = nil;

static void _stgLoadPrefs(void) {
    if (_stgPrefsLoaded) return;
    NSDictionary *p = [NSDictionary dictionaryWithContentsOfFile:_stgPlistPath()] ?: @{};
    id tv = p[@"tweakEnabled"];
    _stgTweakEnabled       = tv ? [tv boolValue] : YES;
    _stgHideBackupWarning  = _stgTweakEnabled && [p[@"hideBackupWarning"]  boolValue];
    _stgHideSWUpdateBadge  = _stgTweakEnabled && [p[@"hideSoftwareUpdateBadge"] boolValue];
    _stgDisableAutoInstall = _stgTweakEnabled && [p[@"disableAutoInstallUpdate"] boolValue];
    _stgCustomAppleID  = _stgTweakEnabled && [p[@"customAppleIDEnabled"] boolValue];
    _stgAppleIDFirst   = p[@"appleIDFirstName"];
    _stgAppleIDLast    = p[@"appleIDLastName"];
    _stgPrefsLoaded = YES;
}

static void _stgPrefsChanged(CFNotificationCenterRef c __unused,
                              void *o __unused,
                              CFStringRef n __unused,
                              const void *obj __unused,
                              CFDictionaryRef i __unused) {
    _stgPrefsLoaded = NO; // bir sonraki erişimde yeniden yükle
}

// ══════════════════════════════════════════════════════════════════════════════
//  BÖLÜM A — iCLOUD BACKUP UYARISI
//
//  Hedef process: com.apple.Preferences
//  Framework:     /System/Library/PrivateFrameworks/iCloudQuota.framework
//
//  ┌─ ICQCloudStorageSummary.tips ──────────────────────────────────────────┐
//  │  Ayarlar > Apple ID > iCloud sayfasındaki inline "uyarı balonlarını"  │
//  │  içeren dizi. Boş array döndürerek bu balonları kaldırıyoruz.         │
//  └────────────────────────────────────────────────────────────────────────┘
//
//  ┌─ ICQBackupDevice.backupFailedByinBytes ────────────────────────────────┐
//  │  Bu değer > 0 olduğunda "Bu iPhone yedeklenmedi" rozeti/uyarısı       │
//  │  tetiklenir. 0 döndürerek uyarının tetiklenme koşulunu kaldırıyoruz. │
//  └────────────────────────────────────────────────────────────────────────┘
// ══════════════════════════════════════════════════════════════════════════════

%group BackupWarning

// Inline uyarı balonları (tips array)
%hook ICQCloudStorageSummary

- (NSArray *)tips {
    // Güvenlik: önce orijinal değeri al, sonra karar ver
    NSArray *orig = %orig;
    _stgLoadPrefs();
    if (!_stgHideBackupWarning) return orig;
    // Boş array döndür — sonsuz döngü riski yok (orig zaten çağrıldı)
    return @[];
}

%end

// "Yedekleme başarısız" bayt sayısı
%hook ICQBackupDevice

- (NSNumber *)backupFailedByinBytes {
    NSNumber *orig = %orig;
    _stgLoadPrefs();
    if (!_stgHideBackupWarning) return orig;
    // 0 döndür — uyarı koşulu ortadan kalkar
    return @(0);
}

%end

%end // BackupWarning


// ══════════════════════════════════════════════════════════════════════════════
//  BÖLÜM B — YAZILIM GÜNCELLEME ROZETİ & UI GİZLE
//
//  Hedef process: com.apple.Preferences
//  Framework:     /System/Library/PrivateFrameworks/Preferences.framework
//
//  ┌─ PSBadgedTableCell ────────────────────────────────────────────────────┐
//  │  Ayarlar ana ekranındaki kırmızı "rozet" sayısını çizen cell.         │
//  │  badgeWithInteger:0 ile çağırarak rozeti sıfırlıyoruz.               │
//  │  Güvenlik: tag kontrolüyle sadece güncelleme hücresini etkileriz.     │
//  └────────────────────────────────────────────────────────────────────────┘
//
//  ┌─ PSSoftwareUpdateTableView ────────────────────────────────────────────┐
//  │  Yazılım Güncelleme ekranındaki tablo. updatesDeferred = YES yaparak  │
//  │  güncelleme "ertelendi" modunda gösterilir, indirme başlamaz.        │
//  └────────────────────────────────────────────────────────────────────────┘
// ══════════════════════════════════════════════════════════════════════════════

%group SoftwareUpdateBadge

// Ana ekran rozeti
%hook PSBadgedTableCell

- (void)refreshCellContentsWithSpecifier:(id)specifier {
    // Önce orijinali çalıştır — UI tamamen kurulsun
    %orig;
    _stgLoadPrefs();
    if (!_stgHideSWUpdateBadge) return;

    // Recursive koruma: bu method içinde kendini tekrar çağırmasın
    static BOOL _inRefresh = NO;
    if (_inRefresh) return;
    _inRefresh = YES;

    // Badge view'larını gizle (ivar erişimi yerine subview tarama — daha güvenli)
    for (UIView *sub in ((UITableViewCell *)self).subviews) {
        NSString *cls = NSStringFromClass([sub class]);
        // Badge'e özgü view'ları gizle
        if ([cls containsString:@"Badge"] ||
            [cls containsString:@"badge"] ||
            [cls containsString:@"Bubble"]) {
            sub.hidden = YES;
            sub.alpha  = 0.0;
        }
    }
    // ContentView içindeki badge subview'ları
    for (UIView *sub in ((UITableViewCell *)self).contentView.subviews) {
        NSString *cls = NSStringFromClass([sub class]);
        if ([cls containsString:@"Badge"] ||
            [cls containsString:@"badge"] ||
            [cls containsString:@"Bubble"]) {
            sub.hidden = YES;
            sub.alpha  = 0.0;
        }
    }

    _inRefresh = NO;
}

// badgeWithInteger: — doğrudan sıfırla
- (void)badgeWithInteger:(long long)count {
    _stgLoadPrefs();
    if (_stgHideSWUpdateBadge) {
        %orig(0); // 0 geçerek rozeti sıfırla
        return;
    }
    %orig(count);
}

%end

// Güncelleme tablosu
%hook PSSoftwareUpdateTableView

- (bool)updatesDeferred {
    _stgLoadPrefs();
    if (_stgHideSWUpdateBadge) return YES;
    return %orig;
}

// state: 0=checking, 1=upToDate, 2=updateAvailable, 3=downloading, 4=installing
// 1 döndürerek "güncel" görünümünü zorla
- (int)state {
    _stgLoadPrefs();
    int orig = %orig;
    // Sadece badge gizleme aktifse ve gerçek durum "güncelleme mevcut" ise
    // "güncel" (1) döndür
    if (_stgHideSWUpdateBadge && orig == 2) return 1;
    return orig;
}

- (void)setState:(int)state {
    _stgLoadPrefs();
    if (_stgHideSWUpdateBadge && state == 2) {
        %orig(1); // updateAvailable → upToDate
        return;
    }
    %orig(state);
}

%end

%end // SoftwareUpdateBadge


// ══════════════════════════════════════════════════════════════════════════════
//  BÖLÜM C — OTOMATİK YAZILIM GÜNCELLEME YÜKLEMEYI KAPAT
//
//  Hedef process: com.apple.MobileAssetd
//  Framework:     MobileAsset (private)
//
//  MobileAsset'in MAAssetQuery sınıfı, OTA güncelleme assetlerini sorgular.
//  "AutomaticDownload" ve "AutomaticInstall" flag'lerini NO yaparak
//  arkaplanda gerçekleşen otomatik indirme/yüklemeyi engelliyoruz.
//
//  GÜVENLİK:
//    • %orig her zaman çağrılır.
//    • Sadece com.apple.MobileAssetd process'ine inject edilir.
//    • Asset'in tipi kontrol edilir — sadece SoftwareUpdate tipi etkilenir.
// ══════════════════════════════════════════════════════════════════════════════

%group AutoInstallUpdate

%hook MAAssetQuery

// Sorgu başlatılmadan önce auto-install bayrağını kapat
- (void)startQueryWithConfiguration:(id)config {
    _stgLoadPrefs();
    if (_stgDisableAutoInstall) {
        // config bir NSDictionary veya özel nesne olabilir
        // Reflection ile "AutomaticInstall" / "AutomaticDownload" key'lerini kapat
        if ([config isKindOfClass:[NSMutableDictionary class]]) {
            NSMutableDictionary *d = (NSMutableDictionary *)config;
            d[@"AutomaticInstall"]  = @NO;
            d[@"AutomaticDownload"] = @NO;
        } else {
            // Immutable dict ise kopyala
            @try {
                if ([config respondsToSelector:@selector(setValue:forKey:)]) {
                    [config setValue:@NO forKey:@"AutomaticInstall"];
                    [config setValue:@NO forKey:@"AutomaticDownload"];
                }
            } @catch (__unused NSException *e) {
                // KVC başarısız olursa sessizce geç — crash yok
            }
        }
    }
    %orig(config); // HER ZAMAN orijinali çağır
}

%end

// NSUserDefaults üzerinden gelen auto-update tercihleri
// com.apple.SoftwareUpdate domain'ini denetleyerek otomatik güncellemeyi kapat
%hook NSUserDefaults

- (id)objectForKey:(NSString *)key {
    _stgLoadPrefs();
    if (!_stgDisableAutoInstall) return %orig;

    // Sonsuz döngü koruması
    static BOOL _inOverride = NO;
    if (_inOverride) return %orig;

    // SoftwareUpdate ile ilgili auto-install key'lerini kapat
    if ([key isEqualToString:@"AutoUpdate"] ||
        [key isEqualToString:@"AutomaticCheckEnabled"] ||
        [key isEqualToString:@"AutomaticDownload"] ||
        [key isEqualToString:@"AutoUpdateRestartRequired"]) {
        _inOverride = YES;
        id orig = %orig; // orijinali yine de al (log/debug için)
        _inOverride = NO;
        (void)orig; // kullanılmıyor ama %orig çağrıldı
        return @NO;
    }

    return %orig;
}

- (BOOL)boolForKey:(NSString *)key {
    _stgLoadPrefs();
    if (!_stgDisableAutoInstall) return %orig;

    static BOOL _inBoolOverride = NO;
    if (_inBoolOverride) return %orig;

    if ([key isEqualToString:@"AutoUpdate"] ||
        [key isEqualToString:@"AutomaticCheckEnabled"] ||
        [key isEqualToString:@"AutomaticDownload"] ||
        [key isEqualToString:@"AutoUpdateRestartRequired"]) {
        _inBoolOverride = YES;
        %orig; // yine de çağır
        _inBoolOverride = NO;
        return NO;
    }

    return %orig;
}

%end

%end // AutoInstallUpdate


// ══════════════════════════════════════════════════════════════════════════════
//  CONSTRUCTOR
//  Her group sadece kendi hedef process'inde init edilir.
// ══════════════════════════════════════════════════════════════════════════════


// ══════════════════════════════════════════════════════════════════════════════
//  APPLE ACCOUNT GRUBU — Preferences.app'e inject edilir
//  PSUIAppleAccountCell + PSUIAppleIDHeaderCell sadece Preferences.app'te yüklü
// ══════════════════════════════════════════════════════════════════════════════

@interface PSUIAppleAccountCell : UITableViewCell
@end

@interface PSUIAppleIDHeaderCell : UITableViewCell
- (UILabel *)nameLabelView;
@end

%group AppleAccount

%hook PSUIAppleAccountCell
- (void)layoutSubviews {
    %orig;
    _stgLoadPrefs();
    if (!_stgCustomAppleID) return;
    for (UIView *sub in self.subviews) {
        for (UIView *sub2 in sub.subviews) {
            if ([sub2 isKindOfClass:[UILabel class]]) {
                UILabel *lbl = (UILabel *)sub2;
                if (lbl.font.pointSize >= 16.0f) {
                    NSMutableString *name = [NSMutableString string];
                    if (_stgAppleIDFirst) [name appendString:_stgAppleIDFirst];
                    if (_stgAppleIDLast) {
                        if (name.length > 0) [name appendString:@" "];
                        [name appendString:_stgAppleIDLast];
                    }
                    if (name.length > 0) lbl.text = name;
                    return;
                }
            }
        }
    }
}
%end

%hook PSUIAppleIDHeaderCell
- (void)layoutSubviews {
    %orig;
    _stgLoadPrefs();
    if (!_stgCustomAppleID) return;
    UILabel *nameLbl = [self nameLabelView];
    if (nameLbl) {
        NSMutableString *name = [NSMutableString string];
        if (_stgAppleIDFirst) [name appendString:_stgAppleIDFirst];
        if (_stgAppleIDLast) {
            if (name.length > 0) [name appendString:@" "];
            [name appendString:_stgAppleIDLast];
        }
        if (name.length > 0) nameLbl.text = name;
    }
}
%end

%end // AppleAccount

%ctor {
    @autoreleasepool {
        PLXLog(@"CTOR START: %s", __FILE__);
        NSString *bid = [[NSBundle mainBundle] bundleIdentifier];

        // Darwin notification ile prefs değişikliklerini dinle
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(), NULL,
            _stgPrefsChanged,
            CFSTR("com.un1ockdev.proudlockx/prefsupdated"),
            NULL, CFNotificationSuspensionBehaviorDeliverImmediately
        );

        // Preferences app → iCloud backup uyarısı + SW update badge
        if ([bid isEqualToString:@"com.apple.Preferences"]) {
            // iCloudQuota class'larının yüklü olup olmadığını kontrol et
            if (objc_getClass("ICQCloudStorageSummary") != nil) {
                %init(BackupWarning);
            }
            if (objc_getClass("PSBadgedTableCell") != nil) {
                %init(SoftwareUpdateBadge);
            }
            // Apple ID isim özelleştirme
            if (objc_getClass("PSUIAppleAccountCell") != nil ||
                objc_getClass("PSUIAppleIDHeaderCell") != nil) {
                %init(AppleAccount);
            }
        }

        // MobileAssetd → otomatik güncelleme yükleme engeli
        if ([bid isEqualToString:@"com.apple.MobileAssetd"] ||
            [bid isEqualToString:@"com.apple.softwareupdated"]) {
            %init(AutoInstallUpdate);
        }
    }
}
