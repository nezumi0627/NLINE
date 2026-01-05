#import <UIKit/UIKit.h>

// --- Constants & Metadata ---
static NSString *const NLINE_VERSION = @"1.0.3";
static NSString *const GITHUB_URL = @"https://github.com/nezumi0627/NLINE";

// --- Forward Declarations ---
@interface LINESettingsViewController : UIViewController
- (void)nline_openSettings;
@end

@interface LineSettingsUI_AboutViewController : UIViewController
@end

@interface NLINEAboutViewController : UIViewController
@end

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

// --- UI Management ---

@interface NLINEAboutViewManager : NSObject
+ (void)setupAboutUIOnViewController:(UIViewController *)vc;
@end

@implementation NLINEAboutViewManager
+ (void)setupAboutUIOnViewController:(UIViewController *)vc {
    vc.title = @"NLINE Settings";
    vc.view.backgroundColor = [UIColor systemBackgroundColor];
    
    for (UIView *subview in vc.view.subviews) {
        [subview removeFromSuperview];
    }
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:vc.view.bounds];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [vc.view addSubview:scrollView];
    
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.spacing = 25;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:stackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [stackView.topAnchor constraintEqualToAnchor:scrollView.topAnchor constant:50],
        [stackView.leadingAnchor constraintEqualToAnchor:vc.view.leadingAnchor constant:20],
        [stackView.trailingAnchor constraintEqualToAnchor:vc.view.trailingAnchor constant:-20]
    ]];
    
    UILabel *logoLabel = [[UILabel alloc] init];
    logoLabel.text = @"NLINE";
    logoLabel.font = [UIFont systemFontOfSize:40 weight:UIFontWeightHeavy];
    logoLabel.textColor = [UIColor systemGreenColor];
    [stackView addArrangedSubview:logoLabel];
    
    UILabel *subLabel = [[UILabel alloc] init];
    subLabel.text = @"Premium Tweak for LiveContainer";
    subLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    subLabel.textColor = [UIColor systemGrayColor];
    [stackView addArrangedSubview:subLabel];
    
    UIButton *testBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [testBtn setTitle:@"Connection Test" forState:UIControlStateNormal];
    testBtn.backgroundColor = [UIColor systemGreenColor];
    [testBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    testBtn.layer.cornerRadius = 12;
    testBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    // Removed deprecated setContentEdgeInsets
    [testBtn addTarget:vc action:@selector(nline_handleTest) forControlEvents:UIControlEventTouchUpInside];
    [stackView addArrangedSubview:testBtn];
    
    UIButton *githubBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [githubBtn setTitle:@"GitHub: nezumi0627" forState:UIControlStateNormal];
    [githubBtn addTarget:vc action:@selector(nline_handleGitHub) forControlEvents:UIControlEventTouchUpInside];
    [stackView addArrangedSubview:githubBtn];
    
    NSString *lineVer = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    UILabel *versionLabel = [[UILabel alloc] init];
    versionLabel.text = [NSString stringWithFormat:@"LINE Version: %@\nNLINE Version: %@", lineVer, NLINE_VERSION];
    versionLabel.font = [UIFont systemFontOfSize:11];
    versionLabel.textColor = [UIColor lightGrayColor];
    versionLabel.numberOfLines = 0;
    versionLabel.textAlignment = NSTextAlignmentCenter;
    [stackView addArrangedSubview:versionLabel];
}
@end

@implementation NLINEAboutViewController
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [NLINEAboutViewManager setupAboutUIOnViewController:self];
}
@end

// --- Hooks ---

static NSString *lastAppearedVC = @"Unknown";
static NSString *lastAppearedTitle = @"None";
static BOOL isShowingInspector = NO;

%hook UIViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (isShowingInspector) return;
    
    NSString *className = NSStringFromClass([self class]);
    if ([className hasPrefix:@"UIAlert"] || [className hasPrefix:@"NLINE"]) return;
    
    lastAppearedVC = className;
    lastAppearedTitle = self.title ?: self.navigationItem.title ?: @"(No Title)";
}

%new
- (void)nline_handleTest {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"NLINE Test" message:@"Device Spoofing: iPad Mode Active\nBypass: Siri Intents Enabled" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

%new
- (void)nline_handleGitHub {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:GITHUB_URL] options:@{} completionHandler:nil];
}

%end

%hook LineSettingsUI_AboutViewController
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    [NLINEAboutViewManager setupAboutUIOnViewController:self];
}
%end

%hook LINESettingsViewController
- (void)viewDidLoad {
    %orig;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"NLINE" style:UIBarButtonItemStylePlain target:self action:@selector(nline_openSettings)];
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
    isShowingInspector = YES;
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (!window) window = [[UIApplication sharedApplication].windows firstObject];
    
    NSString *msg = [NSString stringWithFormat:@"Last Tracked VC:\n%@\n\nTitle: %@", 
                    lastAppearedVC, 
                    lastAppearedTitle];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"NLINE Inspector" message:msg preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        isShowingInspector = NO;
    }]];
    
    UIViewController *top = window.rootViewController;
    while (top.presentedViewController) top = top.presentedViewController;
    [top presentViewController:alert animated:YES completion:nil];
    #pragma clang diagnostic pop
}
@end

%ctor {
    NSLog(@"[NLINE] Tweak loaded safely.");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (!window) window = [[UIApplication sharedApplication].windows firstObject];
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(10, 60, 70, 30);
        btn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        [btn setTitle:@"Identify" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:12];
        btn.layer.cornerRadius = 15;
        
        [window addSubview:btn];
        [btn addTarget:[NLINEInspector class] action:@selector(identify) forControlEvents:UIControlEventTouchUpInside];
        #pragma clang diagnostic pop
    });
}
