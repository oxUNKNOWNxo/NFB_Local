//
//  BHTHookHelpers.h
//  NeoFreeBird
//
//  Shared imports and helpers for the hook files in src/Hooks.
//

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <dlfcn.h>
#import <math.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import "Core/BHTBundle.h"
#import "Core/BHTManager.h"
#import "Core/BHTSettings.h"
#import "CustomTabBar/CustomTabBarUtility.h"
#import "Download/DownloadInlineButton.h"
#import "Headers/TWHeaders.h"
#import "Headers/XHeaders.h"
#import "Padlock/AuthViewController.h"
#import "Settings/ModernSettingsViewController.h"
#import "ThemeColor/BHTDimPalette.h"
#import "ThemeColor/Palette.h"
#import "WebLogin/WebLoginViewController.h"

void EnumerateSubviewsRecursively(UIView* view,
                                  void (^block)(UIView* currentView));
id unwrapDataViewItem(id item);
BOOL IsModuleHeaderItem(id item);
BOOL IsModuleFooterItem(id item);
void MarkEmptiedModuleChrome(NSArray* items, NSMutableIndexSet* removed);
void applySquareAvatarsSetting(void);
NSString* formatNumberWithSuffix(long long number);

bool NFBLiquidGlassEnabled(void);

// Custom theme color re-apply (Theme.x)
void applySelectedThemeColor(void);
void BHTApplyDimToVideoControls(UIView* controlsView);

// Long press on the home navigation bar opens NeoFreeBird settings (Settings.x)
void attachNeoFreeBirdSettingsGesture(UIViewController* home);

// Live pinned-tabs refresh when the hide setting is toggled (Timeline.x)
void applyHideCustomTimelinesSetting(void);
void applyRestoreHomeTabSelectionSetting(void);
void saveHomeTimelineSelectionBeforeResignActive(void);
void restoreHomeTimelineSelectionAfterBecomeActive(void);
BOOL panelIsGenuinelyAvailable(long long panelID);
void prewarmWebCookiesIfNeeded(void);
void maybeHandleHarvestWebView(__unsafe_unretained id webViewController);
id accountForAuthenticatedWebView(void);
void webLoginDidCaptureCookies(NSString* userID, NSString* username,
                               NSDictionary<NSString*, NSString*>* cookiePairs);
BOOL isCookieLoginUserID(NSString* userID);
NSDictionary* currentWebCredentials(void);

BOOL nfb_boolIvar(id object, const char* name, BOOL fallback);

void nfb_setBoolIvar(id object, const char* name, BOOL value);

id nfb_objectIvar(id object, const char* name);
