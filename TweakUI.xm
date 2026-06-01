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


static inline int _plxUIStatusBarGeneration(void) {
    if (objc_getClass("_UIStatusBarVisualProvider_Split828") != nil) return 1;
    if (objc_getClass("_UIStatusBarVisualProvider_Split54")  != nil) return 2;
    return 0;
}

static NSDictionary *_loadPrefsDict(void) {
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:
        @"/var/jb/var/mobile/Library/Preferences/com.un1ockdev.proudlockx.plist"];
    if (d) return d;
    d = [NSDictionary dictionaryWithContentsOfFile:
        @"/var/mobile/Library/Preferences/com.un1ockdev.proudlockx.plist"];
    return d ?: @{};
}

static BOOL    _uiCachedEnabled           = NO;
static BOOL    _uiCustomPositionEnabled   = NO;
static BOOL    _uiPrefsLoaded             = NO;
static CGFloat _cachedOffsetX             = 182.0;
static CGFloat _cachedOffsetY             = 15.0;
static CGFloat _cachedIconSize            = 28.0;

#ifndef CLAMP
#define CLAMP(val, lo, hi) MAX((lo), MIN((hi), (val)))
#endif

static void _uiLoadAllPrefs(void) {
    if (_uiPrefsLoaded) return;
    NSDictionary *p = _loadPrefsDict();
    id tweakVal = p[@"tweakEnabled"];
    BOOL tweakOn = tweakVal ? [tweakVal boolValue] : YES;
    _uiCachedEnabled           = tweakOn && [p[@"statusBarStyle"] boolValue];
    _uiCustomPositionEnabled   = tweakOn && [p[@"customPositionEnabled"] boolValue];
    NSNumber *ox = p[@"lockIconOffsetX"];
    NSNumber *oy = p[@"lockIconOffsetY"];
    NSNumber *sz = p[@"lockIconSize"];
    _cachedOffsetX  = ox ? [ox floatValue] : 182.0;
    _cachedOffsetY  = oy ? [oy floatValue] : 15.0;
    _cachedIconSize = sz ? CLAMP([sz floatValue], 10.0, 70.0) : 28.0;
    _uiPrefsLoaded = YES;
}

static BOOL isEnabled(void) {
    _uiLoadAllPrefs();
    return _uiCachedEnabled;
}

static void uiPrefsChanged(CFNotificationCenterRef c __unused,
                            void *o __unused,
                            CFStringRef n __unused,
                            const void *obj __unused,
                            CFDictionaryRef i __unused) {
    _uiPrefsLoaded = NO;
}

@interface SBUIProudLockIconView : UIView
- (void)setOverrideSize:(CGSize)size offset:(CGPoint)offset extent:(CGFloat)extent;
- (CGFloat)_scaleAmountForZoom;
@end

%group StatusBar_iOS16
%hook _UIStatusBarVisualProvider_iOS
+ (Class)class {
    if (isEnabled()) return %c(_UIStatusBarVisualProvider_Split828);
    return %orig;
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
%end

%group ProudLockXCore
%hook BSPlatform
- (NSInteger)homeButtonType {
    return isEnabled() ? 2 : %orig;
}
%end

%hook SBUIProudLockIconView
- (void)setFrame:(CGRect)frame {
    _uiLoadAllPrefs();
    if (!_uiCustomPositionEnabled) { %orig; return; }
    CGFloat iconSz  = _cachedIconSize;
    CGRect newFrame = CGRectMake(_cachedOffsetX, _cachedOffsetY,
                                 iconSz + 22.0, iconSz + 22.0);
    %orig(newFrame);
    if ([self respondsToSelector:@selector(setOverrideSize:offset:extent:)]) {
        [self setOverrideSize:CGSizeMake(iconSz, iconSz)
                       offset:CGPointZero
                       extent:0.0];
    }
}
- (CGFloat)_scaleAmountForZoom {
    return isEnabled() ? 1.3 : %orig;
}
%end
%end

%ctor {
    NSLog(@"[PLX-TUI] ctor started");
    @autoreleasepool {
        NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
        BOOL isSpringBoard = [bid isEqualToString:@"com.apple.springboard"];
        BOOL isApp = [[[[NSProcessInfo processInfo] arguments] firstObject]
                       containsString:@"/Applications/"];

        if (!isSpringBoard && !isApp) return;

        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(), NULL,
            uiPrefsChanged,
            CFSTR("com.un1ockdev.proudlockx/prefsupdated"),
            NULL, CFNotificationSuspensionBehaviorDeliverImmediately
        );

        _uiLoadAllPrefs();

        int gen = _plxUIStatusBarGeneration();
        if      (gen == 1) %init(StatusBar_iOS16);
        else if (gen == 2) %init(StatusBar_iOS12_15);

        %init(ProudLockXCore);
    }
}
