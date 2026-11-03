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

@implementation TimelinesSettingsViewController

- (NSString*)pageKey {
    return @"timelines";
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
}

@end
