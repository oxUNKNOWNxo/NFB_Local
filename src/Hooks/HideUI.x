//
//  HideUI.x
//  NeoFreeBird
//

#import "HookHelpers.h"

@interface T1ConversationFooterItem : NSObject
@property (nonatomic, retain) NSNumber* viewCount;
@end

// MARK: - Hide Blue verified checkmark

// The author-row badge (SimpleBadgeable.init(statusViewModel:)) builds from the
// merged verified flag plus identityType and ignores isBlueVerified, so both
// getters must be silenced; brand/government badges survive via identityType.
// TFNTwitterUser and TFNTwitterCanonicalUser forward here and need no hooks.

%hook TFSTwitterUser

- (id)isBlueVerified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? nil : %orig;
}

- (BOOL)verified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? NO : %orig;
}

%end

// Reaches into the wrapped user's storage directly instead of through its
// getter.
%hook TFSTwitterUserSource

- (id)isBlueVerified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? nil : %orig;
}

- (BOOL)verified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? NO : %orig;
}

%end

%hook TFSTwitterTypeaheadUser

- (id)isBlueVerified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? nil : %orig;
}

- (BOOL)verified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? NO : %orig;
}

%end

%hook TFSDirectMessageUser

- (id)isBlueVerified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? nil : %orig;
}

- (BOOL)verified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? NO : %orig;
}

%end

// Status view models cache these flags at init, beyond the user model hooks;
// the author row badge reads isFromUserVerified, and other view models forward
// here.
%hook T1TwitterCoreStatusViewModelAdapter

- (BOOL)isFromUserBlueVerified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? NO : %orig;
}

- (BOOL)isFromUserVerified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? NO : %orig;
}

%end

// MARK: - No search history

// Every recent-search write funnels through _tse_setRecentSearch: and every
// read through recentSearches; the separate saved-searches feature stays
// untouched.

%hook TTSRecentSearchesDatastore

- (void)_tse_setRecentSearch:(__unsafe_unretained id)item {
    if (![BHTSettings boolForKey:@"no_history"]) {
        %orig;
    }
}

- (NSArray*)recentSearches {
    return [BHTSettings boolForKey:@"no_history"] ? @[] : %orig;
}

%end

// MARK: - Keep only Trending in the native Explore category strip
//
// X 12.38.1 creates its URT Chrome segmented pages through
// T1URTGenericViewControllerCollection initWithAccount:entries:...  Filtering
// the original entries at construction time lets X own the page selection,
// swipe behavior, navigation and timeline lifecycle as usual. Do not hide the
// whole GuideContainer or rewrite unrelated tab collections.
//
// The constructor's ABI was checked against the 12.38.1 T1Twitter binary:
// @48@0:8@16@24B32q36B44. Never guess a tab index: server-supplied page
// ordering and available tabs can change.
static BOOL NFBExploreTrendingOnlyEnabled(void) {
    return [BHTSettings boolForKey:@"explore_trending_only"];
}

static BOOL NFBIsTrendingTabLabel(NSString* value) {
    if (![value isKindOfClass:NSString.class]) {
        return NO;
    }

    NSString* label = [[value stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
    return [@[@"trending", @"trends", @"trend", @"トレンド"]
        containsObject:label];
}

static NSString* NFBSafeExploreEntryString(id entry, NSString* key) {
    id value = nil;
    if ([entry isKindOfClass:NSDictionary.class]) {
        value = ((NSDictionary*)entry)[key];
    } else if (entry) {
        SEL getter = NSSelectorFromString(key);
        if ([entry respondsToSelector:getter]) {
            // Only call zero-argument object-returning accessors.
            Method method = class_getInstanceMethod([entry class], getter);
            char type[8] = {0};
            if (method) {
                method_getReturnType(method, type, sizeof(type));
                if (type[0] == '@') {
                    value = ((id (*)(id, SEL))objc_msgSend)(entry, getter);
                }
            }
        }
        if (!value) {
            @try {
                value = [entry valueForKey:key];
            } @catch (__unused NSException* exception) {
                value = nil;
            }
        }
    }

    if ([value isKindOfClass:NSString.class]) {
        return value;
    }
    if ([value isKindOfClass:NSAttributedString.class]) {
        return [(NSAttributedString*)value string];
    }
    return nil;
}

static BOOL NFBExploreEntryIsTrending(id entry) {
    if ([entry isKindOfClass:NSString.class]) {
        return NFBIsTrendingTabLabel(entry);
    }
    for (NSString* key in @[@"id", @"tabID", @"tabId", @"tabIdentifier",
                             @"identifier", @"timelineKey", @"title",
                             @"label", @"labelText", @"displayName", @"name",
                             @"text", @"titleText", @"tabTitle", @"attributedTitle",
                             @"accessibilityLabel", @"headerTitle", @"displayText"]) {
        if (NFBIsTrendingTabLabel(NFBSafeExploreEntryString(entry, key))) {
            return YES;
        }
    }

    // The native LegacyTabDescriptor may store a label as an object ivar,
    // rather than exporting an Objective-C property. Inspect only declared
    // object ivars; never interpret raw Swift.String/struct memory as an object.
    unsigned int ivarCount = 0;
    Ivar* ivars = class_copyIvarList([entry class], &ivarCount);
    for (unsigned int index = 0; ivars && index < ivarCount && index < 40; ++index) {
        const char* name = ivar_getName(ivars[index]);
        const char* type = ivar_getTypeEncoding(ivars[index]);
        if (!name || !type || type[0] != '@') {
            continue;
        }
        NSString* field = [NSString stringWithUTF8String:name];
        if (![field.lowercaseString containsString:@"title"] &&
            ![field.lowercaseString containsString:@"label"] &&
            ![field.lowercaseString containsString:@"text"] &&
            ![field.lowercaseString containsString:@"name"] &&
            ![field.lowercaseString containsString:@"identifier"]) {
            continue;
        }
        id value = object_getIvar(entry, ivars[index]);
        NSString* label = [value isKindOfClass:NSString.class] ? value :
            ([value isKindOfClass:NSAttributedString.class] ?
             [(NSAttributedString*)value string] : nil);
        if (NFBIsTrendingTabLabel(label)) {
            free(ivars);
            return YES;
        }
    }
    if (ivars) {
        free(ivars);
    }

    // Some Swift tab wrapper types expose no Objective-C properties but do
    // provide a structured debug description. Match only a *field value* to
    // avoid selecting an unrelated page merely mentioning trending topics.
    NSString* description = [[entry description] lowercaseString];
    if (![description isKindOfClass:NSString.class] || description.length > 1000) {
        return NO;
    }
    return [description containsString:@"id: \"trending\""] ||
           [description containsString:@"id = trending"] ||
           [description containsString:@"id: \"trends\""] ||
           [description containsString:@"labeltext: \"trending\""] ||
           [description containsString:@"labeltext: \"トレンド\""];
}

static NSArray* NFBExploreTrendingEntries(NSArray* entries, NSInteger displayLocation) {
    if (!NFBExploreTrendingOnlyEnabled() ||
        ![entries isKindOfClass:NSArray.class] || entries.count <= 1) {
        return entries;
    }

    id matched = nil;
    NSUInteger matchedCount = 0;
    for (id entry in entries) {
        if (NFBExploreEntryIsTrending(entry)) {
            matched = entry;
            ++matchedCount;
        }
    }

    // Fail open if the host changed its model or IDs; do not use an index
    // guessed from the Japanese or English order.
    if (matchedCount != 1) {
        static BOOL loggedUnknownExploreEntries = NO;
        if (!loggedUnknownExploreEntries) {
            loggedUnknownExploreEntries = YES;
            NSLog(@"[NFB_Local] Trending-only skipped ambiguous native tab entries "
                  @"(count=%lu, matched=%lu, location=%ld, entryClass=%@)",
                  (unsigned long)entries.count, (unsigned long)matchedCount,
                  (long)displayLocation,
                  entries.count ? NSStringFromClass([entries.firstObject class]) : @"none");
        }
        return entries;
    }

    NSLog(@"[NFB_Local] Trending-only retained 1/%lu native Explore tab "
          @"(location=%ld)", (unsigned long)entries.count, (long)displayLocation);
    return @[matched];
}

// The constructor-time filter in 7.3.7 can fail when the Swift entry type
// does not expose its title via Objective-C. The native collection's *actual*
// segmented data source provides a second, direct route to the tab descriptors.
// Always map all related callbacks to the same original category index, so a
// single visible category cannot accidentally display the For You page.
static __thread BOOL NFBReadingNativeExploreTabs = NO;

static NSInteger NFBNativeTrendingIndex(id collection, id segmented) {
    if (!NFBExploreTrendingOnlyEnabled() || !collection || !segmented) {
        return NSNotFound;
    }

    SEL countSelector = @selector(numberOfTabsIn:);
    SEL descriptorSelector = @selector(segmentedViewController:descriptorAtIndex:);
    if (![collection respondsToSelector:countSelector] ||
        ![collection respondsToSelector:descriptorSelector]) {
        return NSNotFound;
    }

    BOOL oldFlag = NFBReadingNativeExploreTabs;
    NFBReadingNativeExploreTabs = YES;
    NSInteger foundIndex = NSNotFound;
    NSInteger matches = 0;
    NSInteger nativeCount = 0;
    @try {
        nativeCount = ((NSInteger (*)(id, SEL, id))objc_msgSend)(
            collection, countSelector, segmented);
        if (nativeCount > 1 && nativeCount <= 16) {
            for (NSInteger index = 0; index < nativeCount; ++index) {
                id descriptor = ((id (*)(id, SEL, id, NSInteger))objc_msgSend)(
                    collection, descriptorSelector, segmented, index);
                if (NFBExploreEntryIsTrending(descriptor)) {
                    foundIndex = index;
                    ++matches;
                }
            }
        }
    } @catch (__unused NSException* error) {
        foundIndex = NSNotFound;
        matches = 0;
    } @finally {
        NFBReadingNativeExploreTabs = oldFlag;
    }

    if (matches != 1) {
        return NSNotFound;
    }

    static BOOL loggedDetection = NO;
    if (!loggedDetection) {
        loggedDetection = YES;
        NSLog(@"[NFB_Local] Explore: native descriptor Trending index=%ld count=%ld",
              (long)foundIndex, (long)nativeCount);
    }
    return foundIndex;
}

%hook T1URTGenericViewControllerCollection

- (instancetype)initWithAccount:(id)account
                        entries:(NSArray*)entries
           priorityQueueActions:(BOOL)priorityQueueActions
                displayLocation:(NSInteger)displayLocation
 isViewControllerCachingEnabled:(BOOL)cachingEnabled {
    NSArray* nativeEntries = NFBExploreTrendingEntries(entries, displayLocation);
    return %orig(account, nativeEntries, priorityQueueActions,
                 displayLocation, cachingEnabled);
}

- (NSInteger)numberOfTabsIn:(id)segmented {
    NSInteger nativeCount = %orig;
    if (NFBReadingNativeExploreTabs || !NFBExploreTrendingOnlyEnabled() ||
        nativeCount <= 1) {
        return nativeCount;
    }
    return NFBNativeTrendingIndex(self, segmented) == NSNotFound ?
           nativeCount : 1;
}

- (id)segmentedViewController:(id)segmented descriptorAtIndex:(NSInteger)index {
    if (NFBReadingNativeExploreTabs || !NFBExploreTrendingOnlyEnabled() ||
        index != 0) {
        return %orig;
    }
    NSInteger trendIndex = NFBNativeTrendingIndex(self, segmented);
    return trendIndex == NSNotFound ? %orig :
           %orig(segmented, trendIndex);
}

- (id)segmentedViewController:(id)segmented pageViewControllerAtIndex:(NSInteger)index {
    if (NFBReadingNativeExploreTabs || !NFBExploreTrendingOnlyEnabled() ||
        index != 0) {
        return %orig;
    }
    NSInteger trendIndex = NFBNativeTrendingIndex(self, segmented);
    return trendIndex == NSNotFound ? %orig :
           %orig(segmented, trendIndex);
}

- (void)segmentedViewController:(id)segmented
       didSelectViewController:(id)viewController
                       atIndex:(NSInteger)index
                 previousIndex:(NSInteger)previousIndex
                       trigger:(NSInteger)trigger {
    if (NFBReadingNativeExploreTabs || !NFBExploreTrendingOnlyEnabled() ||
        index != 0) {
        %orig;
        return;
    }

    NSInteger trendIndex = NFBNativeTrendingIndex(self, segmented);
    if (trendIndex == NSNotFound) {
        %orig;
        return;
    }
    NSInteger originalPrevious = previousIndex == 0 ? trendIndex : previousIndex;
    %orig(segmented, viewController, trendIndex, originalPrevious, trigger);
}

%end

// MARK: - Hide trending content on the Explore tab

// Trending content lives in the child URT chrome view controller, whose
// property has no ObjC getter in 12.3, so find it among the children. The page
// tab strip arrives separately through tfn_navigationBarAccessoryView.

%hook _TtC14T1TwitterSwift28GuideContainerViewController

- (void)viewDidLoad {
    %orig;

    if ([BHTSettings boolForKey:@"hide_trends"] && !NFBExploreTrendingOnlyEnabled()) {
        UIView* viewIfLoaded = [(UIViewController*)self viewIfLoaded];
        if (viewIfLoaded) {
            viewIfLoaded.hidden = YES;
            viewIfLoaded.userInteractionEnabled = NO;
        }
        for (UIViewController* child in
             [(UIViewController*)self childViewControllers]) {
            if ([child isKindOfClass:
                           %c(_TtC14T1TwitterSwift23URTChromeViewController)]) {
                child.view.hidden = YES;
            }
        }
    }
}

- (UIView*)tfn_navigationBarAccessoryView {
    return ([BHTSettings boolForKey:@"hide_trends"] && !NFBExploreTrendingOnlyEnabled()) ? nil : %orig;
}

%end

%hook UIView
- (void)didMoveToWindow {
    %orig;
    if ([BHTSettings boolForKey:@"hide_trends"] && !NFBExploreTrendingOnlyEnabled() && [self.accessibilityIdentifier isEqualToString:@"T1TwitterSwift.TrendsSidebarViewController"] && is_iPad()) {
        self.hidden = YES;
        self.userInteractionEnabled = NO;
        for (UIView* subview in self.subviews) {
            subview.hidden = YES;
        }
    }
    if ([BHTSettings boolForKey:@"hide_who_to_follow"] && [self.accessibilityIdentifier isEqualToString:@"T1UserRecommendationsViewController"] && is_iPad()) {
        self.hidden = YES;
        self.userInteractionEnabled = NO;
        for (UIView* subview in self.subviews) {
            subview.hidden = YES;
        }
    }
}

%end

// MARK: - No Subscribe button

// Every Subscribe surface — the profile button provider (and its answers that
// demote or hide the Follow button) and the tweet author row — shows only when
// the relationship's eligible state is 1, so reporting "not eligible" (2) is
// enough to keep the plain Follow button everywhere. Relationships that are
// actively super-following stay genuine, so a real subscription keeps its
// Subscribed button and subscriber timeline.

%hook TFSTwitterRelationship

- (NSInteger)superFollowEligibleState {
    if ([BHTSettings boolForKey:@"restore_follow_button"] &&
        self.superFollowingState != 1) {
        return 2;
    }
    return %orig;
}

%end

// MARK: - Hide Follow and Message buttons on Tweets

// The conversation focal tweet and the immersive player both render their
// author row through TTAStatusAuthorView, so applying the settings here covers
// both surfaces.

%hook TTAStatusAuthorView

- (void)setFollowControlHidden:(BOOL)hidden {
    %orig([BHTSettings boolForKey:@"hide_follow_button"] ? YES : hidden);
}

// Both content updates and layout use this setter, so later frame-based
// visibility updates cannot undo the preference. Native visibility is retained
// when the preference is off, including for cached and reused author rows.
- (void)_t1_screenshots_modified_setHidden:(BOOL)hidden view:(UIView*)view {
    if (view && view == self.messageButton &&
        [BHTSettings boolForKey:@"hide_message_button"]) {
        hidden = YES;
        view.userInteractionEnabled = NO;
    }
    %orig(hidden, view);
}

%end

// Hiding views also requires hooking the footer, and X is being weird and making it
// more complicated than it should be.
%hook T1ConversationFooterTextView

- (void)updateFooterTextView {
    if (![BHTSettings boolForKey:@"hide_view_count"]) {
        %orig;
        return;
    }

    T1ConversationFooterItem* footerItem = self.footerItem;
    NSNumber* viewCount = footerItem.viewCount;
    footerItem.viewCount = nil;
    @try {
        %orig;
    } @finally {
        footerItem.viewCount = viewCount;
    }
}

+ (CGSize)sizeForViewModel:(id)model
                          footerItem:(T1ConversationFooterItem*)footerItem
                        maximumWidth:(CGFloat)width
    grokEditImageButtonConfiguration:(id)configuration {
    if (![BHTSettings boolForKey:@"hide_view_count"] || !footerItem) {
        return %orig;
    }

    NSNumber* viewCount = footerItem.viewCount;
    footerItem.viewCount = nil;
    CGSize size;
    @try {
        size = %orig;
    } @finally {
        footerItem.viewCount = viewCount;
    }
    return size;
}

%end

// MARK: - Hide inline action buttons

%hook TTAStatusInlineActionsView

+ (NSArray*)_t1_inlineActionViewClassesForViewModel:(id)arg1
                                            options:(NSUInteger)arg2
                                        displayType:(NSUInteger)arg3
                                            account:(id)arg4 {
    NSArray* origClasses = %orig;
    if (![origClasses isKindOfClass:NSArray.class]) {
        return origClasses;
    }

    NSMutableArray* newClasses = [origClasses mutableCopy];

    Class analyticsButtonClass = %c(TTAStatusInlineAnalyticsButton);
    if (analyticsButtonClass && [BHTSettings boolForKey:@"hide_view_count"]) {
        [newClasses removeObject:analyticsButtonClass];
    }

    Class bookmarkButtonClass = %c(TTAStatusInlineBookmarkButton);
    if (bookmarkButtonClass && [BHTSettings boolForKey:@"hide_bookmark_button"]) {
        [newClasses removeObject:bookmarkButtonClass];
    }

    Class downvoteButtonClass = %c(TTAStatusInlineDownvoteButton);
    if (downvoteButtonClass && [BHTSettings boolForKey:@"hide_downvote_button"]) {
        [newClasses removeObject:downvoteButtonClass];
    }

    return [newClasses copy];
}

%end

%hook T1StandardStatusAskGrokButtonView

- (void)didMoveToWindow {
    %orig;
    if ([BHTSettings boolForKey:@"hide_grok_create"]) {
        self.hidden = YES;
        self.userInteractionEnabled = NO;
        for (UIView* subview in self.subviews) {
            subview.hidden = YES;
        }
        [self.superview setNeedsLayout];
        [self.superview layoutSubviews];
    }
}
%end

%hook XDSButton

- (void)didMoveToWindow {
    %orig;
    if ([self respondsToSelector:@selector(allTargets)]) {
        NSSet* allTargets = [self performSelector:@selector(allTargets)];
        for (id target in allTargets) {
            if ([target isKindOfClass:%c(PaymentsButtonViewModel)]) {
                self.hidden = YES;
                self.userInteractionEnabled = NO;
            }
        }
    }
}

%end

%hook _TtC13QuickComposer21QuickComposerSlotView
- (void)didMoveToWindow {
    %orig;
    if ([BHTSettings boolForKey:@"hide_quick_compose"]) {
        self.hidden = YES;
        self.userInteractionEnabled = NO;
        for (UIView* subview in self.subviews) {
            subview.hidden = YES;
        }
    }
}

%end

%hook T1StatusEditedOnXLabelAdapter

- (BOOL)shouldBeVisibleForViewModel:(id)viewModel {
    return [BHTSettings boolForKey:@"hide_made_on_x"] ? NO : %orig;
}

%end