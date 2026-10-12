#!/usr/bin/env python3
from pathlib import Path


def replace_once(path: str, old: str, new: str, marker: str) -> None:
    p = Path(path)
    text = p.read_text(encoding="utf-8")
    if marker in text:
        print(f"{path}: already patched")
        return
    if old not in text:
        raise SystemExit(f"{path}: patch anchor not found: {marker}")
    p.write_text(text.replace(old, new, 1), encoding="utf-8")
    print(f"{path}: patched")


replace_once(
    "src/Core/BHTSettings.m",
    '''                    @{@"key": @"hide_custom_timelines",
                      @"default": @NO},
                    @{@"key": @"show_quote_numbers",
''',
    '''                    @{@"key": @"hide_custom_timelines",
                      @"default": @NO},
                    @{@"key": @"hide_for_you_tab",
                      @"default": @NO},
                    @{@"key": @"show_quote_numbers",
''',
    'hide_for_you_tab'
)

replace_once(
    "src/Hooks/HomeBars.x",
    '''%hook _TtC32TwitterHomeFeatureImplementation35HomeTimelineContainerViewController

- (void)pinnedTimelinesRepository:(id)repository
''',
    '''%hook _TtC32TwitterHomeFeatureImplementation35HomeTimelineContainerViewController

// X 12.3 exposes the standard Home timelines through the unified segmented
// controller. Index 0 is For You and index 1 is Following. When requested,
// expose every tab except index 0 by shifting visible indices by one. This keeps
// Following and any pinned/custom timelines intact instead of hiding the whole
// selector bar.
- (NSInteger)numberOfTabsV1In:(id)controller {
    NSInteger count = %orig;
    if (![BHTSettings boolForKey:@"hide_for_you_tab"]) {
        return count;
    }
    return count > 0 ? count - 1 : 0;
}

- (NSInteger)numberOfTabsV2In:(id)controller {
    NSInteger count = %orig;
    if (![BHTSettings boolForKey:@"hide_for_you_tab"]) {
        return count;
    }
    return count > 0 ? count - 1 : 0;
}

- (UIViewController*)unifiedSegmentedController:(id)controller
                       v1ViewControllerAtIndex:(NSInteger)index {
    NSInteger sourceIndex = [BHTSettings boolForKey:@"hide_for_you_tab"] ? index + 1 : index;
    return %orig(controller, sourceIndex);
}

- (NSString*)unifiedSegmentedController:(id)controller
                         v1TitleAtIndex:(NSInteger)index {
    NSInteger sourceIndex = [BHTSettings boolForKey:@"hide_for_you_tab"] ? index + 1 : index;
    return %orig(controller, sourceIndex);
}

- (NSString*)unifiedSegmentedController:(id)controller
            v1AccessibilityLabelAtIndex:(NSInteger)index {
    NSInteger sourceIndex = [BHTSettings boolForKey:@"hide_for_you_tab"] ? index + 1 : index;
    return %orig(controller, sourceIndex);
}

- (UIViewController*)unifiedSegmentedController:(id)controller
                       v2ViewControllerAtIndex:(NSInteger)index {
    NSInteger sourceIndex = [BHTSettings boolForKey:@"hide_for_you_tab"] ? index + 1 : index;
    return %orig(controller, sourceIndex);
}

- (id)unifiedSegmentedController:(id)controller
             v2DescriptorAtIndex:(NSInteger)index {
    NSInteger sourceIndex = [BHTSettings boolForKey:@"hide_for_you_tab"] ? index + 1 : index;
    return %orig(controller, sourceIndex);
}

// Some navigation paths request the algorithmic variant directly. Redirect only
// that variant to Following; other variants (including custom timelines) remain
// untouched.
- (void)selectTimelineVariant:(NSInteger)variant shouldRefresh:(BOOL)shouldRefresh {
    if ([BHTSettings boolForKey:@"hide_for_you_tab"] && variant == 0) {
        variant = 1;
    }
    %orig(variant, shouldRefresh);
}

- (void)selectFilteredTimelineVariant:(NSInteger)variant shouldRefresh:(BOOL)shouldRefresh {
    if ([BHTSettings boolForKey:@"hide_for_you_tab"] && variant == 0) {
        variant = 1;
    }
    %orig(variant, shouldRefresh);
}

- (void)pinnedTimelinesRepository:(id)repository
''',
    'numberOfTabsV1In:'
)

replace_once(
    "src/Settings/Pages/TimelinesSettingsViewController.m",
    '''    if ([key isEqualToString:@"hide_custom_timelines"]) {
        applyHideCustomTimelinesSetting();
    }
''',
    '''    if ([key isEqualToString:@"hide_custom_timelines"]) {
        applyHideCustomTimelinesSetting();
    }
    if ([key isEqualToString:@"hide_for_you_tab"] && sender.isOn) {
        [[NSUserDefaults standardUserDefaults]
            setObject:@"latest"
               forKey:@"THFHomeTimelineContainerViewController.lastSelectedTimelineTabIdentifier"];
    }
''',
    'THFHomeTimelineContainerViewController.lastSelectedTimelineTabIdentifier'
)

replace_once(
    "layout/Library/Application Support/BHT/BHTwitter.bundle/en.lproj/Localizable.strings",
    '''"HIDE_CUSTOM_TIMELINES_TITLE" = "Hide custom timelines";
"HIDE_CUSTOM_TIMELINES_DETAIL" = "Remove the Add button from the home timeline tabs.";
''',
    '''"HIDE_CUSTOM_TIMELINES_TITLE" = "Hide custom timelines";
"HIDE_CUSTOM_TIMELINES_DETAIL" = "Remove the Add button from the home timeline tabs.";

"HIDE_FOR_YOU_TAB_TITLE" = "Hide the For You tab";
"HIDE_FOR_YOU_TAB_DETAIL" = "Remove only the For You tab from Home while keeping Following and pinned timelines. Restart X after changing this setting.";
''',
    'HIDE_FOR_YOU_TAB_TITLE'
)

replace_once(
    "layout/Library/Application Support/BHT/BHTwitter.bundle/ja.lproj/Localizable.strings",
    '''"HIDE_CUSTOM_TIMELINES_TITLE" = "カスタムタイムラインを非表示";
"HIDE_CUSTOM_TIMELINES_DETAIL" = "ホームタイムラインのタブから「追加」ボタンを削除します。";
''',
    '''"HIDE_CUSTOM_TIMELINES_TITLE" = "カスタムタイムラインを非表示";
"HIDE_CUSTOM_TIMELINES_DETAIL" = "ホームタイムラインのタブから「追加」ボタンを削除します。";

"HIDE_FOR_YOU_TAB_TITLE" = "「おすすめ」タブを非表示";
"HIDE_FOR_YOU_TAB_DETAIL" = "ホームから「おすすめ」タブだけを削除し、「フォロー中」と固定したタイムラインは残します。設定変更後はXを再起動してください。";
''',
    'HIDE_FOR_YOU_TAB_TITLE'
)

ja_path = Path("layout/Library/Application Support/BHT/BHTwitter.bundle/ja.lproj/Localizable.strings")
ja_text = ja_path.read_text(encoding="utf-8")
if '"COOL_KIDS_SECTION_HEADER_TITLE" = "Cool kids";' in ja_text:
    ja_text = ja_text.replace(
        '"COOL_KIDS_SECTION_HEADER_TITLE" = "Cool kids";',
        '"COOL_KIDS_SECTION_HEADER_TITLE" = "クールな仲間たち";',
        1,
    )
    print("ja Localizable.strings: translated Cool kids")

if '"APP_ICON_SETTINGS_MAC_ALERT_TITLE"' not in ja_text:
    ja_text += '''\n\n/* macOS app icon alert */\n"APP_ICON_SETTINGS_MAC_ALERT_TITLE" = "アイコンの変更に失敗";\n"APP_ICON_SETTINGS_MAC_ALERT_MESSAGE" = "macOSではアイコンを変更できません。これはApple側の制限です。";\n'''
    print("ja Localizable.strings: added macOS app icon alert translations")

ja_path.write_text(ja_text, encoding="utf-8")
