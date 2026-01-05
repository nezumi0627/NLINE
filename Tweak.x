#import <UIKit/UIKit.h>

%ctor {
    NSLog(@"[NLINE] Tweak loaded! Preparing alert...");
    
    // アプリ起動後に少し待ってからアラートを表示（UIの準備を待つため）
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"NLINE"
                                                                       message:@"Tweak loaded successfully in jp.naver.line!"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" 
                                                           style:UIAlertActionStyleDefault 
                                                         handler:nil];
        [alert addAction:okAction];
        
        // 最前面のViewControllerを取得して表示
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive) {
                    UIWindowScene *windowScene = (UIWindowScene *)scene;
                    for (UIWindow *w in windowScene.windows) {
                        if (w.isKeyWindow) {
                            window = w;
                            break;
                        }
                    }
                }
                if (window) break;
            }
        }
        
        if (!window) {
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
            window = [UIApplication sharedApplication].keyWindow;
            if (!window) {
                window = [[UIApplication sharedApplication].windows firstObject];
            }
            #pragma clang diagnostic pop
        }
        
        UIViewController *rootViewController = window.rootViewController;
        if (rootViewController) {
            // すでに別のVCがプレゼンされている場合は、その上で表示するようにする
            UIViewController *topController = rootViewController;
            while (topController.presentedViewController) {
                topController = topController.presentedViewController;
            }
            [topController presentViewController:alert animated:YES completion:nil];
            NSLog(@"[NLINE] Alert presented.");
        } else {
            NSLog(@"[NLINE] Error: Could not find rootViewController.");
        }
    });
}

