//
//  Settings.x
//  NeoFreeBird
//

#import "Headers/XHeaders.h"
#import "HookHelpers.h"

// MARK: - NeoFreeBird settings entry

static const void* SettingsEntryKey = &SettingsEntryKey;
static const void* SettingsRootKey = &SettingsRootKey;

static BOOL isSettingsClass(UIViewController* viewController) {
    if (!viewController ||
        ![viewController isKindOfClass:objc_getClass("TFNItemsDataViewController")]) {
        return NO;
    }

    if ([viewController isKindOfClass:objc_getClass("T1GenericSettingsViewController")] ||
        [viewController isKindOfClass:objc_getClass("T1SettingsViewController")]) {
        return YES;
    }

    // X 12.38.1 also ships Swift-based settings controllers. Recognize only
    // generic settings roots, not Account/Privacy/etc. settings sub-pages.
    NSString* name = NSStringFromClass([viewController class]);
    return [name isEqualToString:@"T1TwitterSwift.GenericSettingsViewController"] ||
           [name isEqualToString:@"T1TwitterSwift.SettingsViewController"] ||
           [name isEqualToString:@"GenericSettingsViewController"] ||
           [name isEqualToString:@"SettingsViewController"];
}

// The generic controller backs the root and every sub-page alike, so the root is
// the first settings-class controller in the navigation stack.
static BOOL settingsVCIsRoot(TFNItemsDataViewController* settingsVC) {
    for (UIViewController* viewController in settingsVC.navigationController.viewControllers) {
        if (viewController == settingsVC) {
            return YES;
        }

        if (isSettingsClass(viewController)) {
            return NO;
        }
    }

    return NO;
}

static BOOL sectionsContainNeoFreeBirdEntry(NSArray* sections) {
    for (id section in sections) {
        if (![section isKindOfClass:[NSArray class]]) {
            continue;
        }

        for (id entry in (NSArray*)section) {
            if (objc_getAssociatedObject(entry, SettingsEntryKey)) {
                return YES;
            }
        }
    }

    return NO;
}

static TFNSettingsNavigationItem* makeNeoFreeBirdSettingsItem(
    TFNItemsDataViewController* settingsVC) {
    UIColor* iconColor;
    if (@available(iOS 12.0, *)) {
        if (settingsVC.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            iconColor = [UIColor systemGray2Color];
        } else {
            iconColor = [UIColor secondaryLabelColor];
        }
    } else {
        iconColor = [UIColor secondaryLabelColor];
    }

    UIImage* twitterIcon = [UIImage tfn_vectorImageNamed:@"twitter"
                                                fitsSize:CGSizeMake(20, 20)
                                               fillColor:iconColor];

    TFNTwitterAccount* account = nil;
    if ([settingsVC respondsToSelector:@selector(account)]) {
        account = ((id (*)(id, SEL))objc_msgSend)(settingsVC, @selector(account));
    }
    if (!account) {
        Class hostClass = objc_getClass("T1HostViewController");
        if ([hostClass respondsToSelector:@selector(sharedHostViewController)]) {
            id host = [hostClass sharedHostViewController];
            if ([host respondsToSelector:@selector(currentAccount)]) {
                account = [host currentAccount];
            }
        }
    }
    TFNSettingsNavigationItem* bhtwitter = [[objc_getClass("TFNSettingsNavigationItem") alloc]
            initWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"NFB_SETTINGS_TITLE"]
                   detail:[[BHTBundle sharedBundle] localizedStringForKey:@"NFB_SETTINGS_DETAIL"]
                 iconName:nil
        controllerFactory:^UIViewController* {
            return [BHTManager BHTSettingsWithAccount:account];
        }];

    if (twitterIcon) {
        [bhtwitter setValue:twitterIcon forKey:@"icon"];
    }

    objc_setAssociatedObject(bhtwitter, SettingsEntryKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    return bhtwitter;
}

static NSArray* sectionsByInsertingEntry(TFNItemsDataViewController* settingsVC,
                                         NSArray* sections) {
    NSMutableArray* newSections = [sections mutableCopy] ?: [NSMutableArray array];
    [newSections insertObject:@[makeNeoFreeBirdSettingsItem(settingsVC)] atIndex:0];
    return newSections;
}

// Async settings fetches rebuild the sections and discard one-shot inserts, and
// root-ness is unknowable during the first build (not yet on the nav stack). So
// tag the root in viewWillAppear, insert once to repair the first build, and let
// the rebuild transform below re-add the entry on every later snapshot.
static void insertNeoFreeBirdSettingsIfRoot(TFNItemsDataViewController* settingsVC) {
    if (!settingsVCIsRoot(settingsVC)) {
        return;
    }

    objc_setAssociatedObject(settingsVC, SettingsRootKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    if (sectionsContainNeoFreeBirdEntry(settingsVC.sections)) {
        return;
    }

    settingsVC.sections = sectionsByInsertingEntry(settingsVC, settingsVC.sections);
}

static NSArray* sectionsWithNeoFreeBirdEntry(TFNItemsDataViewController* settingsVC,
                                             NSArray* sections) {
    if (!isSettingsClass(settingsVC)) {
        return sections;
    }

    if (![objc_getAssociatedObject(settingsVC, SettingsRootKey) boolValue]) {
        return sections;
    }

    if (sectionsContainNeoFreeBirdEntry(sections)) {
        return sections;
    }

    return sectionsByInsertingEntry(settingsVC, sections);
}

%hook T1GenericSettingsViewController
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    insertNeoFreeBirdSettingsIfRoot(self);
}
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    insertNeoFreeBirdSettingsIfRoot(self);
}
%end

%hook T1SettingsViewController
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    insertNeoFreeBirdSettingsIfRoot(self);
}
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    insertNeoFreeBirdSettingsIfRoot(self);
}
%end

// On X 12.38.1 the settings data source can be replaced asynchronously using
// setSections: or setSections:restoreScrollPosition: without going through
// updatedSections:forStyle:. Hook all three to keep our entry persistent.
%hook TFNItemsDataViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    // On newer settings navigation stacks the controller can be absent from
    // viewControllers during viewWillAppear; retry after it becomes visible.
    if (isSettingsClass(self)) {
        insertNeoFreeBirdSettingsIfRoot(self);
    }
}

- (void)setSections:(NSArray*)sections {
    %orig(sectionsWithNeoFreeBirdEntry(self, sections));
}

- (void)setSections:(NSArray*)sections restoreScrollPosition:(BOOL)restore {
    %orig(sectionsWithNeoFreeBirdEntry(self, sections), restore);
}

- (NSArray*)updatedSections:(NSArray*)sections forStyle:(NSInteger)style {
    NSArray* updatedSections = %orig;
    return sectionsWithNeoFreeBirdEntry(self, updatedSections);
}

%end

// MARK: - NeoFreeBird settings gesture

@interface NFBSettingsGesture : NSObject <UIGestureRecognizerDelegate>
@property (nonatomic, weak) UIViewController* home;
@end

@implementation NFBSettingsGesture

- (BOOL)homeIsVisible {
    UIViewController* home = self.home;
    UINavigationController* nav = home.navigationController;
    if (!home.viewIfLoaded.window || !nav) {
        return NO;
    }

    UIViewController* top = nav.topViewController;
    for (UIViewController* vc = home; vc; vc = vc.parentViewController) {
        if (vc == top) {
            return YES;
        }
    }

    return NO;
}

- (void)handleLongPress:(UILongPressGestureRecognizer*)press {
    if (press.state != UIGestureRecognizerStateBegan || ![self homeIsVisible]) {
        return;
    }

    UIImpactFeedbackGenerator* haptic =
        [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [haptic impactOccurred];

    id account = nil;
    Class hostClass = objc_getClass("T1HostViewController");
    if ([hostClass respondsToSelector:@selector(sharedHostViewController)]) {
        id host = [hostClass sharedHostViewController];
        if ([host respondsToSelector:@selector(currentAccount)]) {
            account = [host currentAccount];
        }
    }

    [self.home.navigationController pushViewController:[BHTManager BHTSettingsWithAccount:account]
                                              animated:YES];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer {
    return [self homeIsVisible];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)other {
    return YES;
}

@end

static const void* SettingsGestureKey = &SettingsGestureKey;

// Code lifted from nyaathea's Twitter tweak (now abandoned)
void attachNeoFreeBirdSettingsGesture(UIViewController* home) {
    UINavigationBar* bar = home.navigationController.navigationBar;
    if (!bar) {
        return;
    }

    NFBSettingsGesture* target = objc_getAssociatedObject(bar, SettingsGestureKey);
    if (target) {
        target.home = home;
        return;
    }

    target = [NFBSettingsGesture new];
    target.home = home;

    UILongPressGestureRecognizer* press =
        [[UILongPressGestureRecognizer alloc] initWithTarget:target
                                                      action:@selector(handleLongPress:)];
    press.cancelsTouchesInView = NO;
    press.delegate = target;
    [bar addGestureRecognizer:press];

    objc_setAssociatedObject(bar, SettingsGestureKey, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
