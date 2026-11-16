//
//  Branding.x
//  NeoFreeBird
//

#import "Core/BHTTerminology.h"
#import "HookHelpers.h"

// MARK: - Restore Twitter terminology
// Three layers, driven by locale files in the tweak bundle:
//   1. RenameOverrides.strings — Twitter localization key -> exact replacement,
//      a missing key falls through to the generic replacement
//   2. RenamePhrases.strings — exact source text -> complete translated phrase.
//   3. RenameWords.strings — generic word replacements ("X" -> "Twitter",
//      "Post" -> "Tweet", etc.) applied to localized and server-side strings

// Foundation may localize an error while loading a table. Do not recursively
// enter the dispatch_once initializers on the same thread.
static __thread BOOL handlingTerminologyLocalization = NO;

static NSDictionary<NSString*, NSString*>* RenameTable(NSString* name) {
    BOOL wasHandlingLocalization = handlingTerminologyLocalization;
    handlingTerminologyLocalization = YES;
    @try {
        NSBundle* bundle = [BHTBundle sharedBundle].mainBundle;
        NSString* appLanguage =
            [[NSBundle mainBundle] preferredLocalizations].firstObject ?: @"en";
        NSString* localization =
            [NSBundle preferredLocalizationsFromArray:bundle.localizations
                                       forPreferences:@[appLanguage]]
                .firstObject;

        // preferredLocalizationsFromArray: falls back to en when nothing matches, so
        // reject a mismatch: unsupported languages skip renaming, not get English
        // rules.
        NSString* appCode =
            [[appLanguage stringByReplacingOccurrencesOfString:@"_" withString:@"-"]
                componentsSeparatedByString:@"-"]
                .firstObject;
        NSString* lprojCode =
            [[localization stringByReplacingOccurrencesOfString:@"_" withString:@"-"]
                componentsSeparatedByString:@"-"]
                .firstObject;
        if (![appCode isEqualToString:lprojCode]) {
            return @{};
        }

        // Read the selected directory directly: NSBundle resource lookup can fall
        // back to another language when this particular table is missing.
        NSString* directory = [bundle.bundlePath stringByAppendingPathComponent:
                                                     [localization stringByAppendingPathExtension:@"lproj"]];
        NSString* path = [directory stringByAppendingPathComponent:
                                        [name stringByAppendingPathExtension:@"strings"]];
        return BHTLoadTerminologyTable(path);
    } @finally {
        handlingTerminologyLocalization = wasHandlingLocalization;
    }
}

static NSDictionary<NSString*, NSString*>* RenameKeyOverrides(void) {
    static NSDictionary* overrides = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        overrides = RenameTable(@"RenameOverrides");
    });
    return overrides;
}

static NSArray<NSDictionary*>* RenameEdits(NSString* input) {
    static BHTTerminology* terminology = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString* language = [NSBundle mainBundle].preferredLocalizations.firstObject ?: @"en";
        terminology = [[BHTTerminology alloc] initWithWords:RenameTable(@"RenameWords")
                                                    phrases:RenameTable(@"RenamePhrases")
                                                     locale:[NSLocale localeWithLocaleIdentifier:language]];
    });
    return [terminology editsForString:input];
}

static NSString* RestoreTwitterTerminology(NSString* input) {
    NSArray<NSDictionary*>* edits = RenameEdits(input);
    if (!edits) {
        // Plural formats from .stringsdict may have identical text but carry
        // different localization metadata. Preserve the original string object.
        return input;
    }

    NSMutableString* result = [input mutableCopy];
    for (NSDictionary* edit in edits.reverseObjectEnumerator) {
        [result replaceCharactersInRange:[edit[@"range"] rangeValue]
                              withString:edit[@"repl"]];
    }
    return [result copy];
}

static NSAttributedString* RestoreTwitterAttributed(NSAttributedString* input) {
    NSArray<NSDictionary*>* edits = RenameEdits(input.string);
    if (!edits) {
        return input;
    }

    NSMutableAttributedString* result = [input mutableCopy];
    for (NSDictionary* edit in edits.reverseObjectEnumerator) {
        NSRange range = [edit[@"range"] rangeValue];
        NSDictionary* attrs = [result attributesAtIndex:range.location
                                         effectiveRange:NULL];
        NSAttributedString* piece =
            [[NSAttributedString alloc] initWithString:edit[@"repl"]
                                            attributes:attrs];
        [result replaceCharactersInRange:range withAttributedString:piece];
    }
    return result;
}

// MARK: - Recover host strings when a resource bundle lookup falls through
//
// X 12.33 has several toast paths which can ask the wrong NSBundle for a
// localization key. Foundation then returns the key verbatim even though
// the translation exists in one of X's Swift-package resource bundles.
// Load those official tables directly and use them only when %orig is
// unresolved, so normal localization behavior remains untouched.
static NSString* TwitterLocalizationBaseLanguage(NSString* language) {
    NSString* normalized =
        [language stringByReplacingOccurrencesOfString:@"_" withString:@"-"];
    return [normalized componentsSeparatedByString:@"-"].firstObject;
}

static NSDictionary<NSString*, NSString*>* TwitterHostLocalizationFallbackTable(void) {
    static NSDictionary<NSString*, NSString*>* table = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString* appLanguage =
            [[NSBundle mainBundle] preferredLocalizations].firstObject;
        if (appLanguage.length == 0) {
            appLanguage = [NSLocale preferredLanguages].firstObject ?: @"en";
        }

        NSString* appCode = TwitterLocalizationBaseLanguage(appLanguage);
        NSMutableDictionary<NSString*, NSString*>* merged =
            [NSMutableDictionary dictionary];
        NSArray<NSString*>* bundleNames = @[
            @"T1Strings_T1Strings.bundle",
            @"ChatCore_ChatStrings.bundle",
            @"TwitterSharedStrings_TwitterSharedStrings.bundle"
        ];

        for (NSString* bundleName in bundleNames) {
            NSString* bundlePath =
                [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:bundleName];
            NSBundle* resourceBundle = [NSBundle bundleWithPath:bundlePath];
            if (!resourceBundle) {
                continue;
            }

            NSString* localization =
                [NSBundle preferredLocalizationsFromArray:resourceBundle.localizations
                                           forPreferences:@[appLanguage]]
                    .firstObject;
            if (localization.length == 0 ||
                ![appCode isEqualToString:
                             TwitterLocalizationBaseLanguage(localization)]) {
                continue;
            }

            NSString* stringsPath =
                [resourceBundle pathForResource:@"Localizable"
                                        ofType:@"strings"
                                   inDirectory:nil
                               forLocalization:localization];
            NSData* data = stringsPath ? [NSData dataWithContentsOfFile:stringsPath] : nil;
            if (!data) {
                continue;
            }

            id plist = [NSPropertyListSerialization propertyListWithData:data
                                                                 options:NSPropertyListImmutable
                                                                  format:NULL
                                                                   error:nil];
            if (![plist isKindOfClass:[NSDictionary class]]) {
                continue;
            }

            [(NSDictionary*)plist enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL* stop) {
                if ([key isKindOfClass:[NSString class]] &&
                    [value isKindOfClass:[NSString class]]) {
                    merged[key] = value;
                }
            }];
        }

        table = [merged copy];
    });
    return table ?: @{};
}

static NSString* TwitterHostLocalizationFallbackForKey(NSString* key) {
    if (key.length == 0) {
        return nil;
    }
    NSString* value = TwitterHostLocalizationFallbackTable()[key];
    return [value isKindOfClass:[NSString class]] ? value : nil;
}

// MARK: - Rename localized strings
// Every UI string routes through this Foundation method in 12.3, so the rename
// applies broadly. Skip our own bundle so the tweak's strings aren't
// reprocessed.
%hook NSBundle
- (NSString*)localizedStringForKey:(NSString*)key
                             value:(NSString*)value
                             table:(NSString*)tableName {
<<<<<<< /tmp/tmp.MH94Z4UoXQ
    NSString* result = %orig;
    NSBundle* tweakBundle = [BHTBundle sharedBundle].mainBundle;

    // A valid localized result must not be the key itself. X 12.33 can hit this
    // path for composition-complete toasts and their action/dismiss labels even
    // though the Japanese strings are present in the app. Recover the official
    // value before applying optional Twitter terminology restoration.
    if (self != tweakBundle && key.length > 0 &&
        (result.length == 0 || [result isEqualToString:key])) {
        NSString* fallback = TwitterHostLocalizationFallbackForKey(key);
        if (fallback.length > 0) {
            result = fallback;
        }
    }

    if (![BHTSettings boolForKey:@"restore_twitter_names"] ||
        self == tweakBundle) {
        return result;
    }
=======
    if (handlingTerminologyLocalization) {
        return %orig;
    }
    handlingTerminologyLocalization = YES;
    @try {
        NSString* result = %orig;
        if (![BHTSettings boolForKey:@"restore_twitter_names"] ||
            self == [BHTBundle sharedBundle].mainBundle) {
            return result;
        }
>>>>>>> /tmp/tmp.rS7gvCQK1X

        NSString* override = key ? RenameKeyOverrides()[key] : nil;
        if (override) {
            return override;
        }
        return result.length > 0 ? RestoreTwitterTerminology(result) : result;
    } @finally {
        handlingTerminologyLocalization = NO;
    }
}
%end

// MARK: - Rename server-composed text
// TFNAttributedTextView renders chrome and server-composed URT text that
// carries no localization key, out of the NSBundle hook's reach. The
// TTAStatusBodyAttributedTextView subclass (tweet bodies) is skipped so a
// user's own words aren't mangled.
%hook TFNAttributedTextView
- (void)setTextModel:(TFNAttributedTextModel*)model {
    if (!model || !model.attributedString) {
        %orig(model);
        return;
    }

    NSMutableAttributedString* newString = nil;
    BOOL textChanged = NO;

    if ([BHTSettings boolForKey:@"restore_twitter_names"] &&
        ![self isKindOfClass:%c(TTAStatusBodyAttributedTextView)]) {
        NSAttributedString* source = newString ?: model.attributedString;
        NSAttributedString* renamed = RestoreTwitterAttributed(source);
        if (renamed != source) {
            newString = [renamed mutableCopy];
            textChanged = YES;
        }
    }

    if (!newString) {
        %orig(model);
        return;
    }

    if (textChanged) {
        // Text length changed, so rebuild the model to refresh length-derived
        // state.
        TFNAttributedTextModel* newModel = [[%c(TFNAttributedTextModel) alloc]
            initWithAttributedString:newString];
        %orig(newModel);
    } else if ([model respondsToSelector:@selector(setAttributedString:)]) {
        // Attributes only: keep the model to preserve its layout metadata.
        [model setAttributedString:newString];
        %orig(model);
    } else {
        TFNAttributedTextModel* newModel = [[%c(TFNAttributedTextModel) alloc]
            initWithAttributedString:newString];
        %orig(newModel);
    }
}
%end

// MARK: - Label the "new posts" refresh pill
// The facepile pill variant hardcodes blank text (no feature flag gates it).
// The tweak ships the label in the app's terminology and routes it through the
// rename pipeline, so "restore_twitter_names" converts it per-language.
static NSString* PillLabelText(void) {
    NSString* label =
        [[BHTBundle sharedBundle] localizedStringForKey:@"REFRESH_PILL_TEXT"];
    if ([BHTSettings boolForKey:@"restore_twitter_names"]) {
        label = RestoreTwitterTerminology(label);
    }
    return label;
}

%hook TUIUpdateIndicator

- (void)_recreatePillControlForContentNotification:(id)notification
                                      hideOnScroll:(BOOL)hideOnScroll {
    %orig;

    if (![BHTSettings boolForKey:@"refresh_pill_label"]) {
        return;
    }

    TFNPillControl* pill = self.pillControl;
    NSString* current = [pill.text
        stringByTrimmingCharactersInSet:[NSCharacterSet
                                            whitespaceAndNewlineCharacterSet]];
    if (current.length > 0) {
        return;
    }

    NSString* label = PillLabelText();
    if (label) {
        pill.text = label;
    }
}

%end
