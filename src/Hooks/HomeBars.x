//
//  HomeBars.x
//  NeoFreeBird
//


#import <string.h>
#import "HookHelpers.h"


// MARK: - Home timeline tabs

static __weak id ActiveHomeTimelineContainer;
static NSString* const HomeTimelineTabSelectionKey =
    @"THFHomeTimelineContainerViewController.lastSelectedTimelineTabIdentifier";
static NSString* const FollowingTimelineTabIdentifier = @"latest";

static BOOL HideForYouEnabled(void) {
    return [BHTSettings boolForKey:@"hide_for_you_tab"];
}

static NSInteger HomeSourceTabIndex(NSInteger visibleIndex) {
    if (!HideForYouEnabled() || visibleIndex < 0) {
        return visibleIndex;
    }
    return visibleIndex + 1;
}

static void ForceFollowingSelection(id container) {
    if (!HideForYouEnabled()) {
        return;
    }

    [[NSUserDefaults standardUserDefaults] setObject:FollowingTimelineTabIdentifier
                                              forKey:HomeTimelineTabSelectionKey];

    if ([container respondsToSelector:@selector(selectTimelineVariant:shouldRefresh:)]) {
        ((void (*)(id, SEL, NSInteger, BOOL))objc_msgSend)(
            container, @selector(selectTimelineVariant:shouldRefresh:), 1, NO);
    }
}

static void ReloadHomeTimelineTabs(id container) {
    if (!container || ![container respondsToSelector:@selector(segmentedViewController)]) {
        return;
    }

    id segmentedController =
        ((id (*)(id, SEL))objc_msgSend)(container, @selector(segmentedViewController));
    if ([segmentedController respondsToSelector:@selector(reloadData)]) {
        ((void (*)(id, SEL))objc_msgSend)(segmentedController, @selector(reloadData));
    }
    if ([segmentedController respondsToSelector:@selector(view)]) {
        UIView* view = ((id (*)(id, SEL))objc_msgSend)(segmentedController, @selector(view));
        [view setNeedsLayout];
    }
}

void applyHideForYouSetting(void) {
    id container = ActiveHomeTimelineContainer;
    if (HideForYouEnabled()) {
        ForceFollowingSelection(container);
    }
    ReloadHomeTimelineTabs(container);
}


// MARK: - Hide custom timelines

static __weak NSObject* PinnedTimelinesRepository;
static NSArray* LastPinnedTimelineModels;
static BOOL PinnedTimelinesWriteBypass = NO;

// Applies a toggle without relaunching. Hiding rewrites the UNCHANGED pinned
// list purely to republish — updatePinnedTimelines: persists server-side, so
// anything else would unpin for real; the delegate hook below swaps in the
// empty list on the way through.
void applyHideCustomTimelinesSetting(void) {
    NSObject* repository = PinnedTimelinesRepository;
    if (!repository) {
        return;
    }

    if ([BHTSettings boolForKey:@"hide_custom_timelines"]) {
        NSArray* models = LastPinnedTimelineModels;
        if (models.count > 0) {
            PinnedTimelinesWriteBypass = YES;
            ((void (*)(id, SEL, id))objc_msgSend)(repository, @selector(updatePinnedTimelines:), models);
            PinnedTimelinesWriteBypass = NO;
        }
    } else if ([repository respondsToSelector:@selector(fetchPinnedTimelinesWithThrottleEnabled:)]) {
        ((void (*)(id, SEL, BOOL))objc_msgSend)(
            repository, @selector(fetchPinnedTimelinesWithThrottleEnabled:), NO);
    }
}

// The trailing accessory is only reconfigured while the strip is showing, so a
// button built before hiding mid-session survives; sync its visibility here. The
// property is a Swift lazy var whose storage ivar KVC can't see, hence the fallback.
static void SyncHomeAddTabButton(id container, BOOL hidden) {
    UIView* button = nil;

    @try {
        button = [container valueForKey:@"addTabButton"];
    } @catch (__unused NSException* exception) {
        unsigned int ivarCount = 0;
        Ivar* ivars = class_copyIvarList([container class], &ivarCount);
        for (unsigned int i = 0; i < ivarCount; i++) {
            const char* name = ivar_getName(ivars[i]);
            if (name && strstr(name, "addTabButton")) {
                button = object_getIvar(container, ivars[i]);
                break;
            }
        }
        free(ivars);
    }

    if ([button isKindOfClass:[UIView class]]) {
        button.hidden = hidden;
    }
}

// The repository publishes the pinned list through this single delegate call, so
// handing it an empty array hides the tabs without touching persisted state.
%hook _TtC32TwitterHomeFeatureImplementation35HomeTimelineContainerViewController

// X 12.31.1 uses LegacySegmentedViewControllerDataSource selectors. Index 0 is
// For You and index 1 is Following. Hide index 0 and remap every visible index
// to the next source index so Following and pinned/custom timelines remain.
- (NSInteger)numberOfTabsIn:(id)controller {
    NSInteger count = %orig;
    if (!HideForYouEnabled()) {
        return count;
    }
    return count > 1 ? count - 1 : count;
}

- (id)segmentedViewController:(id)controller descriptorAtIndex:(NSInteger)index {
    return %orig(controller, HomeSourceTabIndex(index));
}

- (UIViewController*)segmentedViewController:(id)controller
                   pageViewControllerAtIndex:(NSInteger)index {
    return %orig(controller, HomeSourceTabIndex(index));
}

- (BOOL)segmentedViewController:(id)controller
    shouldSelectViewControllerAtIndex:(NSInteger)index {
    return %orig(controller, HomeSourceTabIndex(index));
}

- (BOOL)segmentedViewController:(id)controller isPrewarmableTabAtIndex:(NSInteger)index {
    return %orig(controller, HomeSourceTabIndex(index));
}

- (BOOL)segmentedViewController:(id)controller isUnreadIndicatorTabAtIndex:(NSInteger)index {
    return %orig(controller, HomeSourceTabIndex(index));
}

- (id)segmentedViewController:(id)controller menuForTabAtIndex:(NSInteger)index {
    return %orig(controller, HomeSourceTabIndex(index));
}

- (id)segmentedViewController:(id)controller tabGroupAtIndex:(NSInteger)index {
    return %orig(controller, HomeSourceTabIndex(index));
}

- (void)segmentedViewController:(id)controller didTapTabAtIndex:(NSInteger)index {
    %orig(controller, HomeSourceTabIndex(index));
}

- (void)segmentedViewController:(id)controller didLongPressAtIndex:(NSInteger)index {
    %orig(controller, HomeSourceTabIndex(index));
}

// Keep the old X 12.3 unified-segmented selectors for compatibility with older
// host versions. They are not used by X 12.31.1.
- (NSInteger)numberOfTabsV1In:(id)controller {
    NSInteger count = %orig;
    if (!HideForYouEnabled()) {
        return count;
    }
    return count > 1 ? count - 1 : count;
}

- (NSInteger)numberOfTabsV2In:(id)controller {
    NSInteger count = %orig;
    if (!HideForYouEnabled()) {
        return count;
    }
    return count > 1 ? count - 1 : count;
}

- (UIViewController*)unifiedSegmentedController:(id)controller
                       v1ViewControllerAtIndex:(NSInteger)index {
    return %orig(controller, HomeSourceTabIndex(index));
}

- (NSString*)unifiedSegmentedController:(id)controller
                         v1TitleAtIndex:(NSInteger)index {
    return %orig(controller, HomeSourceTabIndex(index));
}

- (NSString*)unifiedSegmentedController:(id)controller
            v1AccessibilityLabelAtIndex:(NSInteger)index {
    return %orig(controller, HomeSourceTabIndex(index));
}

- (UIViewController*)unifiedSegmentedController:(id)controller
                       v2ViewControllerAtIndex:(NSInteger)index {
    return %orig(controller, HomeSourceTabIndex(index));
}

- (id)unifiedSegmentedController:(id)controller
             v2DescriptorAtIndex:(NSInteger)index {
    return %orig(controller, HomeSourceTabIndex(index));
}

// If Home explicitly requests the algorithmic variant while hiding it, redirect
// only that request to Following. Other variants, including custom timelines,
// remain available.
- (void)selectTimelineVariant:(NSInteger)variant shouldRefresh:(BOOL)shouldRefresh {
    if (HideForYouEnabled() && variant == 0) {
        variant = 1;
    }
    %orig(variant, shouldRefresh);
}

- (void)selectFilteredTimelineVariant:(NSInteger)variant shouldRefresh:(BOOL)shouldRefresh {
    if (HideForYouEnabled() && variant == 0) {
        variant = 1;
    }
    %orig(variant, shouldRefresh);
}

- (void)clearLastSelectedTabIdentifier {
    if (HideForYouEnabled()) {
        [[NSUserDefaults standardUserDefaults] setObject:FollowingTimelineTabIdentifier
                                                  forKey:HomeTimelineTabSelectionKey];
        return;
    }
    %orig;
}

- (void)pinnedTimelinesRepository:(id)repository
    didChangeWithPinnedTimelineModels:(NSArray*)models {
    PinnedTimelinesRepository = repository;
    if (models.count > 0) {
        LastPinnedTimelineModels = [models copy];
    }
    BOOL hide = [BHTSettings boolForKey:@"hide_custom_timelines"];

    %orig(repository, hide ? @[] : models);
    SyncHomeAddTabButton(self, hide);
}

- (id)tfn_navigationBarAccessoryView {
    id accessoryView = %orig;
    SyncHomeAddTabButton(self, [BHTSettings boolForKey:@"hide_custom_timelines"]);
    return accessoryView;
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    ActiveHomeTimelineContainer = self;
    if (HideForYouEnabled()) {
        ForceFollowingSelection(self);
    }
    SyncHomeAddTabButton(self, [BHTSettings boolForKey:@"hide_custom_timelines"]);
}

%end

// While hiding, the overridden pinned-tabs feature switches make the app compute
// an empty pinned list; freeze writes so it can't overwrite the real tabs.
%hook _TtC32TwitterHomeFeatureImplementation31CachedPinnedTimelinesRepository

- (void)updatePinnedTimelines:(id)timelines {
    if (!PinnedTimelinesWriteBypass && [BHTSettings boolForKey:@"hide_custom_timelines"]) {
        return;
    }

    %orig;
}

%end

// MARK: - Force tweet images to full frame

%hook T1StandardStatusAttachmentViewAdapter

// attachmentType 2 = photos, displayType 1 = full frame
- (NSUInteger)displayType {
    if (self.attachmentType == 2) {
        return [BHTSettings boolForKey:@"force_tweet_full_frame"] ? 1 : %orig;
    }

    return %orig;
}

%end

// MARK: - Hide the Spaces bar

// The bar is still the repurposed Fleets line; both home timeline implementations
// share this visibility gate, re-evaluated on every content or settings update.
%hook T1FleetLineHeaderController

- (BOOL)_t1_shouldShowFleetLine {
    if ([BHTSettings boolForKey:@"hide_spaces"]) {
        return NO;
    }

    return %orig;
}

%end
