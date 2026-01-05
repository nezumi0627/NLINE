#import <UIKit/UIKit.h>

// クラスがUIViewを継承していることを明示して、.hidden プロパティを使えるようにします
@interface NLBannerAdView : UIView
@end

// --- 広告ブロックセクション ---
// LINEの広告管理クラス等をフックして非表示にします
%hook NLAdManager 
- (void)showAd:(id)arg1 {
    // 広告を表示する処理をスキップ
    return;
}
%end

%hook NLBannerAdView
- (void)layoutSubviews {
    %orig;
    self.hidden = YES; // バナーを強制非表示
}
%end

// --- 既読回避セクション ---
// 既読を送るリクエストをフックして中断します
// 注意: メソッド名はLINEのバージョンにより変わる可能性があります
%hook MessageService
- (void)sendReadReceipt:(id)arg1 {
    // 既読通知を送らない
    NSLog(@"[NLINE] Blocked sending read receipt.");
    return;
}
%end

// 動作確認用
%ctor {
    NSLog(@"[NLINE] Loaded successfully in LiveContainer!");
}
