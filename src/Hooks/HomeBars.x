//
//  HomeBars.x
//  NeoFreeBird
//

#import <string.h>
#import "HookHelpers.h"


// MARK: - Home timeline tabs

static __weak id ActiveHomeTimelineContainer;
static char HomeInitialSelectionFixedKey;
static NSString* const HomeTimelineTabSelectionKey =
    @"THFHomeTimelineContainerViewController.lastSelectedTimelineTabIdentifier";

// Session-only by design. A cold launch must always start on Following; only a
// background/foreground transition inside the same process may restore a pinned
// list, and only when the user enables restore_home_tab_selection.
static NSInteger HomeSessionVisibleIndex = 0;
static BOOL HomeColdLaunchSelectionApplied = NO;

static BOOL HideForYouEnabled(void) {
    return [BHTSettings boolForKey:@"hide_for_you_tab"];
}

static BOOL RestoreHomeTabSelectionEnabled(void) {
    return [BHTSettings boolForKey:@"restore_home_tab_selection"];
}

static NSInteger HomeSourceTabIndex(NSInteger visibleIndex) {
    if (!HideForYouEnabled() || visibleIndex < 0) {
        return visibleIndex;
    }
    return visibleIndex + 1;
}

// With For You removed, visible index 0 maps to source index 1 (Following).
// Keep the old persisted identifier cleared so Twitter cannot restore a source
// index as though it were a visible index after the tab strip is shortened.
static void ClearHiddenHomeSelection(void) {
    if (!HideForYouEnabled()) {
        return;
    }

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:HomeTimelineTabSelectionKey];
}

static id HomeSegmentedController(id container) {
    if (!container || ![container respondsToSelector:@selector(segmentedViewController)]) {
        return nil;
    }

    return ((id (*)(id, SEL))objc_msgSend)(container, @selector(segmentedViewController));
}

static NSInteger ValidHomeVisibleIndex(id container,
                                       id segmentedController,
                                       NSInteger requestedIndex) {
    NSInteger index = requestedIndex >= 0 ? requestedIndex : 0;

    if (container && segmentedController &&
        [container respondsToSelector:@selector(numberOfTabsIn:)]) {
        NSInteger count = ((NSInteger (*)(id, SEL, id))objc_msgSend)(
            container, @selector(numberOfTabsIn:), segmentedController);
        if (count > 0 && index >= count) {
            index = 0;
        }
    }

    return index;
}

static NSInteger CurrentHomeVisibleIndex(id container) {
    id segmentedController = HomeSegmentedController(container);
    if (!segmentedController ||
        ![segmentedController respondsToSelector:@selector(currentIndex)]) {
        return 0;
    }

    NSInteger currentIndex = ((NSInteger (*)(id, SEL))objc_msgSend)(
        segmentedController, @selector(currentIndex));
    return ValidHomeVisibleIndex(container, segmentedController, currentIndex);
}

static void ReloadHomeTimelineTabsAtIndex(id container, NSInteger requestedIndex) {
    id segmentedController = HomeSegmentedController(container);
    if (!segmentedController) {
        return;
    }

    NSInteger visibleIndex =
        ValidHomeVisibleIndex(container, segmentedController, requestedIndex);

    // X 12.31.1 exposes reloadDataWithSelectingIndex: on the legacy segmented
    // controller. Keep selection in VISIBLE-index space; the data-source remap
    // below converts visible index N to source index N+1 while For You is hidden.
    if (HideForYouEnabled() &&
        [segmentedController respondsToSelector:@selector(reloadDataWithSelectingIndex:)]) {
        ((void (*)(id, SEL, NSInteger))objc_msgSend)(
            segmentedController, @selector(reloadDataWithSelectingIndex:), visibleIndex);
    } else if ([segmentedController respondsToSelector:@selector(reloadData)]) {
        ((void (*)(id, SEL))objc_msgSend)(segmentedController, @selector(reloadData));
    }

    if ([segmentedController respondsToSelector:@selector(view)]) {
        UIView* view = ((id (*)(id, SEL))objc_msgSend)(segmentedController, @selector(view));
        [view setNeedsLayout];
    }
}

// Called BEFORE Twitter's own applicationWillResignActive:. If optional restore
// is enabled, capture the tab that is actually visible before Twitter mutates or
// persists any internal selection state. Otherwise explicitly forget it.
void saveHomeTimelineSelectionBeforeResignActive(void) {
    if (!HideForYouEnabled()) {
        HomeSessionVisibleIndex = 0;
        return;
    }

    HomeSessionVisibleIndex = RestoreHomeTabSelectionEnabled()
        ? CurrentHomeVisibleIndex(ActiveHomeTimelineContainer)
        : 0;
}

// Called AFTER Twitter's applicationDidBecomeActive:. Restore only within the
// current process. A cold launch never reaches here with an existing Home
// container; the first viewDidAppear: below always forces Following instead.
void restoreHomeTimelineSelectionAfterBecomeActive(void) {
    if (!HideForYouEnabled()) {
        return;
    }

    id container = ActiveHomeTimelineContainer;
    if (!container) {
        return;
    }

    ClearHiddenHomeSelection();
    NSInteger targetIndex =
        RestoreHomeTabSelectionEnabled() ? HomeSessionVisibleIndex : 0;

    __weak id weakContainer = container;
    dispatch_async(dispatch_get_main_queue(), ^{
        id strongContainer = weakContainer;
        if (strongContainer && HideForYouEnabled()) {
            ReloadHomeTimelineTabsAtIndex(strongContainer, targetIndex);
        }
    });
}

void applyHideForYouSetting(void) {
    id container = ActiveHomeTimelineContainer;
    if (HideForYouEnabled()) {
        ClearHiddenHomeSelection();
        HomeSessionVisibleIndex = 0;
        // Enabling mid-session is itself an initialization point: start from
        // Following and do not let a later viewDidAppear treat this as cold boot.
        HomeColdLaunchSelectionApplied = YES;
        if (container) {
            objc_setAssociatedObject(
                container, &HomeInitialSelectionFixedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    ReloadHomeTimelineTabsAtIndex(container, 0);
}

void applyRestoreHomeTabSelectionSetting(void) {
    if (!HideForYouEnabled()) {
        HomeSessionVisibleIndex = 0;
        return;
    }

    if (RestoreHomeTabSelectionEnabled()) {
        HomeSessionVisibleIndex = CurrentHomeVisibleIndex(ActiveHomeTimelineContainer);
    } else {
        HomeSessionVisibleIndex = 0;
        ReloadHomeTimelineTabsAtIndex(ActiveHomeTimelineContainer, 0);
    }
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

- (void)viewDidLoad {
    if (HideForYouEnabled()) {
        ClearHiddenHomeSelection();
    }
    %orig;
}

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
// remain available. Do not proactively force variant 1 during lifecycle events:
// on the shortened visible tab strip that can be interpreted as visible index 1.
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
    %orig;
    if (HideForYouEnabled()) {
        ClearHiddenHomeSelection();
    }
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

    if (HideForYouEnabled() &&
        ![objc_getAssociatedObject(self, &HomeInitialSelectionFixedKey) boolValue]) {
        objc_setAssociatedObject(
            self, &HomeInitialSelectionFixedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        ClearHiddenHomeSelection();

        // The first Home appearance in every process is a true cold-launch
        // initialization point and MUST start on Following regardless of the
        // optional restore setting. Later container recreation in the same
        // process may reuse the session tab only when restore is enabled.
        NSInteger targetIndex = 0;
        if (HomeColdLaunchSelectionApplied && RestoreHomeTabSelectionEnabled()) {
            targetIndex = HomeSessionVisibleIndex;
        } else {
            HomeSessionVisibleIndex = 0;
        }
        HomeColdLaunchSelectionApplied = YES;

        __weak id weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            id strongSelf = weakSelf;
            if (strongSelf && HideForYouEnabled()) {
                ReloadHomeTimelineTabsAtIndex(strongSelf, targetIndex);
            }
        });
    }

    SyncHomeAddTabButton(self, [BHTSettings boolForKey:@"hide_custom_timelines"]);
    attachNeoFreeBirdSettingsGesture((UIViewController*)self);
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

%hook _TtC14T1TwitterSwift28FleetLineAccessoryController

- (BOOL)isHidden {
    return [BHTSettings boolForKey:@"hide_spaces"] ? YES : %orig;
}

- (UIView*)accessoryView {
    return [BHTSettings boolForKey:@"hide_spaces"] ? nil : %orig;
}

%end
