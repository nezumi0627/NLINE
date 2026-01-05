#import <UIKit/UIKit.h>

// --- Constants & Metadata ---
static NSString *const NLINE_VERSION = @"1.0.1";
static NSString *const GITHUB_URL = @"https://github.com/nezumi0627/NLINE";

// --- Siri (Intents) Crash Bypass ---
%hook INVocabulary
+ (id)sharedVocabulary { return nil; }
- (void)setVocabularyStrings:(id)arg1 ofType:(long long)arg2 { return; }
- (void)removeAllVocabularyStrings { return; }
%end

// --- Device Spoofing (iPad Mode) ---
%hook UIDevice
- (UIUserInterfaceIdiom)userInterfaceIdiom { return UIUserInterfaceIdiomPad; }
- (NSString *)model { return @"iPad"; }
- (NSString *)localizedModel { return @"iPad"; }
- (NSString *)systemName { return @"iPadOS"; }
%end

// --- NLINE Custom Settings UI ---

@interface NLINEAboutViewController : UIViewController
@end

@implementation NLINEAboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"NLINE Settings";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:scrollView];
    
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.spacing = 20;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:stackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [stackView.topAnchor constraintEqualToAnchor:scrollView.topAnchor constant:40],
        [stackView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [stackView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20]
    ]];
    
    // Title
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"NLINE Control Panel";
    titleLabel.font = [UIFont boldSystemFontOfSize:24];
    [stackView addArrangedSubview:titleLabel];
    
    // Test Button
    UIButton *testBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [testBtn setTitle:@"Run Connection Test" forState:UIControlStateNormal];
    testBtn.backgroundColor = [UIColor systemBlueColor];
    [testBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    testBtn.layer.cornerRadius = 10;
    // Padding (Modern way is using configuration, but for simplicity we remove the deprecated one)
    [testBtn addTarget:self action:@selector(handleTest) forControlEvents:UIControlEventTouchUpInside];
    [stackView addArrangedSubview:testBtn];
    
    // GitHub Button
    UIButton *githubBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [githubBtn setTitle:@"GitHub: nezumi0627" forState:UIControlStateNormal];
    [githubBtn addTarget:self action:@selector(handleGitHub) forControlEvents:UIControlEventTouchUpInside];
    [stackView addArrangedSubview:githubBtn];
    
    // Spacer
    UIView *spacer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 40)];
    [stackView addArrangedSubview:spacer];
    
    // Versions
    NSString *lineVer = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    UILabel *versionLabel = [[UILabel alloc] init];
    versionLabel.text = [NSString stringWithFormat:@"LINE Version: %@\nNLINE Version: %@", lineVer, NLINE_VERSION];
    versionLabel.font = [UIFont systemFontOfSize:12];
    versionLabel.textColor = [UIColor systemGrayColor];
    versionLabel.numberOfLines = 0;
    versionLabel.textAlignment = NSTextAlignmentCenter;
    [stackView addArrangedSubview:versionLabel];
}

- (void)handleTest {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Test" message:@"Hook status: Normal\nDevice Spoofing: Active" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)handleGitHub {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:GITHUB_URL] options:@{} completionHandler:nil];
}

@end

// --- Hooking Settings ---
@interface SettingsViewController : UIViewController
- (void)openNLINE;
@end

%hook SettingsViewController

- (void)viewDidLoad {
    %orig;
    UIBarButtonItem *nlineBtn = [[UIBarButtonItem alloc] initWithTitle:@"NLINE" style:UIBarButtonItemStylePlain target:self action:@selector(openNLINE)];
    self.navigationItem.rightBarButtonItem = nlineBtn;
}

%new
- (void)openNLINE {
    NLINEAboutViewController *vc = [[NLINEAboutViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

%end

// --- Initialization & UI Inspector ---

%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    NSLog(@"[NLINE] VC Appeared: %@", NSStringFromClass([self class]));
}
%end

%ctor {
    NSLog(@"[NLINE] Tweak loaded with UI Inspector.");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive) {
                    window = [(UIWindowScene *)scene windows].firstObject;
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
                                                                           message:@"iPad Mode & UI Inspector enabled.\n\nInstructions:\n1. Check Logs for 'VC Appeared'\n2. Use the button below to identify the current screen."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"Identify Top VC" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Wdeprecated-declarations"
                UIWindow *win = [UIApplication sharedApplication].keyWindow;
                if (!win) win = [[UIApplication sharedApplication].windows firstObject];
                
                UIViewController *top = win.rootViewController;
                while (top.presentedViewController) top = top.presentedViewController;
                
                // If it's a navigation controller, get the top visible one
                if ([top isKindOfClass:[UINavigationController class]]) {
                    top = [(UINavigationController *)top visibleViewController];
                }
                
                NSString *className = NSStringFromClass([top class]);
                UIAlertController *idAlert = [UIAlertController alertControllerWithTitle:@"Current VC" message:className preferredStyle:UIAlertControllerStyleAlert];
                [idAlert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                
                [win.rootViewController presentViewController:idAlert animated:YES completion:nil];
                #pragma clang diagnostic pop
            }]];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            
            UIViewController *topVC = window.rootViewController;
            while (topVC.presentedViewController) topVC = topVC.presentedViewController;
            [topVC presentViewController:alert animated:YES completion:nil];
            NSLog(@"[NLINE] Startup alert presented.");
        }
    });
}

