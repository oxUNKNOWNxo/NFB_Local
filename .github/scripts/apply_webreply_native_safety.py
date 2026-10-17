from pathlib import Path
import re

# Disable the authenticated x.com intent reply fallback on X 12.33. X can
# reject this path with error 226 (automated-request protection). We do not
# bypass that protection; replies are handed back to X's native composer.
p = Path('src/Hooks/WebReply.x')
text = p.read_text()
anchor = 'static const void* ReplyWebViewDismissingKey = &ReplyWebViewDismissingKey;\n'
helper = '''

// X 12.33 can reject authenticated x.com intent replies with error 226
// (automated-request protection). Do not attempt to bypass that protection.
// Clear any saved opt-in and leave replies to the app's native composer.
static BOOL WebReplyFallbackAllowed(void) {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"reply_in_webview"] != nil) {
        [defaults removeObjectForKey:@"reply_in_webview"];
    }
    return NO;
}
'''
if 'WebReplyFallbackAllowed' not in text:
    if anchor not in text:
        raise SystemExit('WebReply anchor not found')
    text = text.replace(anchor, anchor + helper, 1)
text = text.replace('if (![BHTSettings boolForKey:@"reply_in_webview"]) {',
                    'if (!WebReplyFallbackAllowed()) {')
p.write_text(text)

# Mark the Labs toggle disabled.
p = Path('src/Core/BHTSettings.m')
text = p.read_text()
old = '''                    @{@"key": @"reply_in_webview",
                      @"default": @NO,
                      @"type": @"toggle"}
'''
new = '''                    @{@"key": @"reply_in_webview",
                      @"default": @NO,
                      @"disabled": @YES,
                      @"type": @"toggle"}
'''
if old not in text:
    raise SystemExit('reply_in_webview registry entry not found')
p.write_text(text.replace(old, new, 1))

# Generic disabled-toggle rendering.
p = Path('src/Settings/ModernSettingsPageViewController.m')
text = p.read_text()
old = '''        BOOL isEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:key]
                              ?: toggleData[@"default"] boolValue];
        cell.toggleSwitch.on = isEnabled;
        objc_setAssociatedObject(cell.toggleSwitch, @"prefKey", key, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
'''
new = '''        BOOL isDisabled = [toggleData[@"disabled"] boolValue];
        BOOL isEnabled = isDisabled
                             ? NO
                             : [[[NSUserDefaults standardUserDefaults] objectForKey:key]
                                    ?: toggleData[@"default"] boolValue];
        cell.toggleSwitch.on = isEnabled;
        cell.toggleSwitch.enabled = !isDisabled;
        cell.contentView.alpha = isDisabled ? 0.55 : 1.0;
        objc_setAssociatedObject(cell.toggleSwitch, @"prefKey", key, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
'''
if old not in text:
    raise SystemExit('settings toggle renderer anchor not found')
p.write_text(text.replace(old, new, 1))

# Explain why the experimental setting is disabled.
values = {
    'en': (
        'Web reply fallback (disabled)',
        "Disabled on X 12.33 because web replies can trigger X's anti-automation protection. Replies use the normal in-app composer."
    ),
    'ja': (
        'Web返信フォールバック（無効）',
        'X 12.33ではWeb返信が自動操作判定を受ける可能性があるため無効化しています。返信には通常のアプリ内返信画面を使用します。'
    ),
}
base = Path('layout/Library/Application Support/BHT/BHTwitter.bundle')
for lang, (title, detail) in values.items():
    lp = base / f'{lang}.lproj' / 'Localizable.strings'
    s = lp.read_text()
    s, n1 = re.subn(r'"REPLY_IN_WEBVIEW_TITLE"\s*=\s*"[^"]*";',
                    f'"REPLY_IN_WEBVIEW_TITLE" = "{title}";', s, count=1)
    s, n2 = re.subn(r'"REPLY_IN_WEBVIEW_DETAIL"\s*=\s*"[^"]*";',
                    f'"REPLY_IN_WEBVIEW_DETAIL" = "{detail}";', s, count=1)
    if n1 != 1 or n2 != 1:
        raise SystemExit(f'localization keys not found for {lang}')
    lp.write_text(s)

p = Path('control')
text = p.read_text()
if 'Version: 7.2.2' not in text:
    raise SystemExit('unexpected current local version')
p.write_text(text.replace('Version: 7.2.2', 'Version: 7.2.3', 1))
