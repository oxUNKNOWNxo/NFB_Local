//  Shared imports and helpers for the hook files in src/Hooks.

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreText/CoreText.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <dlfcn.h>
#import <math.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <string.h>
#import "Core/BHTBundle.h"
#import "Core/BHTManager.h"
#import "Core/BHTSettings.h"
#import "Core/BHTTerminology.h"
#import "CustomTabBar/CustomTabBarUtility.h"
#import "Headers/BHHeaders.h"
#import "Headers/TFNHeaders.h"
#import "Headers/TWHeaders.h"
#import "Headers/UIHeaders.h"
#import "Headers/XHeaders.h"
#import "Padlock/AuthViewController.h"
#import "Settings/ModernSettingsViewController.h"
#import "Theme/Theme.h"
#import "ThemeColor/Palette.h"
#import "WebLogin/WebLoginViewController.h"

<<<<<<< /tmp/tmp.bzMySVcoxO
=======
static NSString* const WebClientBearer = @"Bearer "
                                         @"AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puT"
                                         @"s%3D1Zv7ttfk8LF81IUq16cHjhLTvJu4FA33AGWWjCpTnA";

static NSString* const NativeClientBearer =
    @"Bearer "
    @"AAAAAAAAAAAAAAAAAAAAAAj4AQAAAAAAPraK64zCZ9CSzdLesbE7LB%2Bw4uE%"
    @"3DVJQREvQNCZJNiz3rHO7lOXlkVOQkzzdsgu6wWgcazdMUaGoUGm";

// Recursive view traversal (BHTHookHelpers.m)
>>>>>>> /tmp/tmp.YgCkfDcqyU
void EnumerateSubviewsRecursively(UIView* view,
                                  void (^block)(UIView* currentView));
id unwrapDataViewItem(id item);
BOOL IsModuleHeaderItem(id item);
BOOL IsModuleFooterItem(id item);
void MarkEmptiedModuleChrome(NSArray* items, NSMutableIndexSet* removed);
void applySquareAvatarsSetting(void);
NSString* formatNumberWithSuffix(long long number);

bool NFBLiquidGlassEnabled(void);

<<<<<<< /tmp/tmp.bzMySVcoxO
// Custom theme color re-apply (Theme.x)
void applySelectedThemeColor(void);
void BHTApplyDimToVideoControls(UIView* controlsView);

=======
>>>>>>> /tmp/tmp.YgCkfDcqyU
// Long press on the home navigation bar opens NeoFreeBird settings (Settings.x)
void attachNeoFreeBirdSettingsGesture(UIViewController* home);

// Live pinned-tabs refresh when the hide setting is toggled (Timeline.x)
void applyHideCustomTimelinesSetting(void);
void prepareHomeTimelineFollowingForColdLaunch(void);
BOOL panelIsGenuinelyAvailable(long long panelID);
<<<<<<< /tmp/tmp.bzMySVcoxO
void prewarmWebCookiesIfNeeded(void);
void maybeHandleHarvestWebView(__unsafe_unretained id webViewController);
id accountForAuthenticatedWebView(void);
void webLoginDidCaptureCookies(NSString* userID, NSString* username,
                               NSDictionary<NSString*, NSString*>* cookiePairs);
BOOL isCookieLoginUserID(NSString* userID);
NSDictionary* currentWebCredentials(void);
=======

// Web session and posting helpers.
#import "WebCreateTweet/WebCreateTweet.h"

BOOL boolIvar(id object, const char* name, BOOL fallback);
>>>>>>> /tmp/tmp.YgCkfDcqyU

void setBoolIvar(id object, const char* name, BOOL value);

id objectIvar(id object, const char* name);

id ObjectForSelector(id object, SEL selector);
