//
//  TimelinesSettingsViewController.m
//  NeoFreeBird
//
//  Created by nyaathea
//

#import "Settings/Pages/TimelinesSettingsViewController.h"
#import "Headers/TWHeaders.h"

extern void applyHideCustomTimelinesSetting(void);
extern void applyHideForYouSetting(void);
extern void applyRestoreHomeTabSelectionSetting(void);

// These render helpers live on the base page implementation but are intentionally
// kept out of its public header. Declare them locally so this page can provide
// localized text for the NFB_Local-only setting without modifying upstream's
// shared localization registry.
@interface ModernSettingsPageViewController (NFBLocalTimelineLocalization)
- (NSString*)localizedTitleForEntry:(NSDictionary*)entry;
- (NSString*)localizedDetailForKey:(NSString*)key;
@end

@implementation TimelinesSettingsViewController

- (NSString*)pageKey {
    return @"timelines";
}

- (void)buildSettingsList {
    [super buildSettingsList];

    NSMutableArray<NSDictionary*>* entries = [self.toggles mutableCopy];
    if (!entries) {
        entries = [NSMutableArray array];
    }

    NSDictionary* restoreEntry = @{
        @"key": @"restore_home_tab_selection",
        @"parentKey": @"hide_for_you_tab",
        @"default": @NO,
        @"type": @"toggle"
    };

    NSUInteger hideForYouIndex = [entries indexOfObjectPassingTest:^BOOL(
        NSDictionary* entry, NSUInteger idx, BOOL* stop) {
        return [entry[@"key"] isEqualToString:@"hide_for_you_tab"];
    }];

    if (hideForYouIndex == NSNotFound) {
        [entries addObject:restoreEntry];
    } else {
        [entries insertObject:restoreEntry atIndex:hideForYouIndex + 1];
    }

    self.toggles = [entries copy];
}

- (BOOL)nfbLocalUsesJapanese {
    NSString* language = NSLocale.preferredLanguages.firstObject ?: @"";
    return [language hasPrefix:@"ja"];
}

- (NSString*)localizedTitleForEntry:(NSDictionary*)entry {
    if ([entry[@"key"] isEqualToString:@"restore_home_tab_selection"]) {
        return [self nfbLocalUsesJapanese]
            ? @"選択したホームタブを復元"
            : @"Restore selected Home tab";
    }
    return [super localizedTitleForEntry:entry];
}

- (NSString*)localizedDetailForKey:(NSString*)key {
    if ([key isEqualToString:@"restore_home_tab_selection"]) {
        return [self nfbLocalUsesJapanese]
            ? @"別のアプリから戻ったとき、同じ起動中に最後に選択していた固定リストを復元します。アプリを完全に終了して起動した場合は、常に「フォロー中」から開始します。"
            : @"When returning from another app, restore the pinned timeline selected during the current session. A cold launch always starts on Following.";
    }
    return [super localizedDetailForKey:key];
}

- (void)switchChanged:(UISwitch*)sender {
    [super switchChanged:sender];
    NSString* key = objc_getAssociatedObject(sender, @"prefKey");
    if ([key isEqualToString:@"hide_custom_timelines"]) {
        applyHideCustomTimelinesSetting();
    }
    if ([key isEqualToString:@"hide_for_you_tab"]) {
        applyHideForYouSetting();
    }
    if ([key isEqualToString:@"restore_home_tab_selection"]) {
        applyRestoreHomeTabSelectionSetting();
    }
}

@end
