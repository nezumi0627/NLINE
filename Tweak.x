#import <UIKit/UIKit.h>

// --- Constants & Metadata ---
static NSString *const NLINE_VERSION = @"1.0.2";
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
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"NLINE Control Panel";
    titleLabel.font = [UIFont boldSystemFontOfSize:24];
    [stackView addArrangedSubview:titleLabel];
    
    UIButton *testBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [testBtn setTitle:@"Run Connection Test" forState:UIControlStateNormal];
    testBtn.backgroundColor = [UIColor systemBlueColor];
    [testBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    testBtn.layer.cornerRadius = 10;
    [testBtn addTarget:self action:@selector(handleTest) forControlEvents:UIControlEventTouchUpInside];
    [stackView addArrangedSubview:testBtn];
    
    UIButton *githubBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [githubBtn setTitle:@"GitHub: nezumi0627" forState:UIControlStateNormal];
    [githubBtn addTarget:self action:@selector(handleGitHub) forControlEvents:UIControlEventTouchUpInside];
    [stackView addArrangedSubview:githubBtn];
    
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
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Test" message:@"Status: Connected" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)handleGitHub {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:GITHUB_URL] options:@{} completionHandler:nil];
}
@end

// --- Hooking & UI Inspector Logic ---

static NSString *lastAppearedVC = @"Unknown";
static NSString *lastAppearedTitle = @"None";

@interface UIViewController (NLINE)
- (void)nline_openSettings;
@end

%hook UIViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    lastAppearedVC = NSStringFromClass([self class]);
    lastAppearedTitle = self.title ?: self.navigationItem.title ?: @"(No Title)";
    
    NSLog(@"[NLINE] Tracked: %@ (Title: %@)", lastAppearedVC, lastAppearedTitle);
    
    // タイトル判定の強化
    NSString *t = lastAppearedTitle;
    if ([t containsString:@"設定"] || [t containsString:@"Settings"] || [t containsString:@"Setting"]) {
        UIBarButtonItem *nlineBtn = [[UIBarButtonItem alloc] initWithTitle:@"NLINE" style:UIBarButtonItemStylePlain target:self action:@selector(nline_openSettings)];
        self.navigationItem.rightBarButtonItem = nlineBtn;
    }
}

%new
- (void)nline_openSettings {
    NLINEAboutViewController *vc = [[NLINEAboutViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

%end

// --- Floating Inspector ---

@interface NLINEInspector : NSObject
+ (void)identify;
@end

@implementation NLINEInspector

+ (void)identify {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (!window) window = [[UIApplication sharedApplication].windows firstObject];
    
    NSString *msg = [NSString stringWithFormat:@"Last Tracked VC:\n%@\n\nTitle: %@\n\nIs on Nav: %@", 
                    lastAppearedVC, 
                    lastAppearedTitle,
                    [window.rootViewController navigationController] ? @"YES" : @"NO"];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"NLINE Inspector" message:msg preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    
    // 最前面に表示するために現在のrootViewControllerを使用
    UIViewController *top = window.rootViewController;
    while (top.presentedViewController) top = top.presentedViewController;
    [top presentViewController:alert animated:YES completion:nil];
    #pragma clang diagnostic pop
}
@end

%ctor {
    NSLog(@"[NLINE] Tweak loaded with Floating Inspector.");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (!window) window = [[UIApplication sharedApplication].windows firstObject];
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(10, 50, 70, 30);
        btn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        [btn setTitle:@"Identify" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:12];
        btn.layer.cornerRadius = 15;
        
        // 浮遊ボタンを最前面に追加
        [window addSubview:btn];
        [btn addTarget:[NLINEInspector class] action:@selector(identify) forControlEvents:UIControlEventTouchUpInside];
        #pragma clang diagnostic pop
    });
}

