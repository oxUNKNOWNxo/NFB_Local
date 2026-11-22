#import "../HookHelpers.h"

extern NSString* const testAlertVersionKey;
extern BOOL testAlertScheduled;
extern BOOL padlockAuthenticated;
extern AuthViewController* padlockController;
UIWindow* activeKeyWindow(void);
void showPadlockOverlay(void);
void removePadlockOverlay(void);
NSString* testAlertVersion(void);
void scheduleTestAlertIfNeeded(void);
void stripLaunchRevealMask(UIView* view);
