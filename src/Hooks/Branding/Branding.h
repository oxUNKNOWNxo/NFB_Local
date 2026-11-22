#import "../HookHelpers.h"

extern __thread BOOL handlingTerminologyLocalization;

NSDictionary<NSString*, NSString*>* RenameKeyOverrides(void);
NSString* PillLabelText(void);
NSString* RestoreTwitterTerminology(NSString* input);
NSAttributedString* RestoreTwitterAttributed(NSAttributedString* input);

// NFB_Local: official X localization fallback for unresolved UI keys.
NSString* TwitterHostLocalizationFallbackForKey(NSString* key);
