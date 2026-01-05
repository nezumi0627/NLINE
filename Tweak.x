#import <UIKit/UIKit.h>

// --- Siri (Intents) Crash Bypass ---
// Prevent crash caused by missing com.apple.developer.siri entitlement in sideloaded environments.
%hook INVocabulary
+ (id)sharedVocabulary { return nil; }
- (void)setVocabularyStrings:(id)arg1 ofType:(long long)arg2 { return; }
- (void)removeAllVocabularyStrings { return; }
%end

// --- Device Spoofing (iPad Mode) ---

%hook UIDevice

- (UIUserInterfaceIdiom)userInterfaceIdiom {
    return UIUserInterfaceIdiomPad;
}

- (NSString *)model {
    return @"iPad";
}

- (NSString *)localizedModel {
    return @"iPad";
}

- (NSString *)systemName {
    return @"iPadOS";
}

%end

// --- Initialization ---

%ctor {
    NSLog(@"[NLINE] Tweak loaded safely with Siri bypass.");
    
    // UIの準備を待つため10秒待機
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive) {
                    UIWindowScene *windowScene = (UIWindowScene *)scene;
                    window = windowScene.windows.firstObject;
                    break;
                }
            }
        }
        
        if (!window) {
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
            window = [UIApplication sharedApplication].keyWindow;
            #pragma clang diagnostic pop
        }
        
        if (window && window.rootViewController) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"NLINE Active"
                                                                           message:@"iPad Spoofing & Siri Bypass enabled."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            
            UIViewController *topVC = window.rootViewController;
            while (topVC.presentedViewController) {
                topVC = topVC.presentedViewController;
            }
            [topVC presentViewController:alert animated:YES completion:nil];
            NSLog(@"[NLINE] Status alert presented.");
        }
    });
}

