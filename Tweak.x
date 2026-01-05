#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#import <objc/runtime.h>

// --- Device Spoofing (iPad Mode) ---

// 1. UIDevice のフック
// これによりアプリは自分を iPad と認識し、サブデバイスログイン用UI（QRコードなど）を表示する可能性があります。
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

- (NSString *)name {
    return @"iPad";
}

- (NSString *)systemName {
    return @"iPadOS";
}

%end

// 2. uname (POSIX) のフック
// 多くのライブラリがハードウェア識別（iPad13,4等）に使用します。
%hookf(int, uname, struct utsname *value) {
    int ret = %orig(value);
    if (ret == 0) {
        // iPad Pro 11-inch (3rd generation)
        strcpy(value->machine, "iPad13,4");
    }
    return ret;
}

// --- 初期化処理 ---

%ctor {
    NSLog(@"[NLINE] Device spoofing (iPad Mode) initialized.");
    
    // UIの準備が整うのを待ってから、現在の偽装状態をアラートで表示
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIDevice *device = [UIDevice currentDevice];
        NSString *model = [device model];
        UIUserInterfaceIdiom idiom = [device userInterfaceIdiom];
        NSString *idiomStr = (idiom == UIUserInterfaceIdiomPad) ? @"iPad (Tablet)" : @"iPhone";
        
        NSString *msg = [NSString stringWithFormat:@"Current Device State:\nModel: %@\nIdiom: %@\n\nPlease check if 'Login with QR Code' is available.", model, idiomStr];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"NLINE Spoofing"
                                                                       message:msg
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" 
                                                           style:UIAlertActionStyleDefault 
                                                         handler:nil];
        [alert addAction:okAction];
        
        // 最前面のViewControllerを取得
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive) {
                    UIWindowScene *windowScene = (UIWindowScene *)scene;
                    for (UIWindow *w in windowScene.windows) {
                        if (w.isKeyWindow) { window = w; break; }
                    }
                }
                if (window) break;
            }
        }
        if (!window) {
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
            window = [UIApplication sharedApplication].keyWindow;
            #pragma clang diagnostic pop
        }
        
        UIViewController *rootVC = window.rootViewController;
        if (rootVC) {
            UIViewController *topVC = rootVC;
            while (topVC.presentedViewController) {
                topVC = topVC.presentedViewController;
            }
            [topVC presentViewController:alert animated:YES completion:nil];
            NSLog(@"[NLINE] Spoofing status alert presented.");
        }
    });
}

