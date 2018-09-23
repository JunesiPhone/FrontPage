//
//  Headers.h
//  FrontPageViewController
//
//  Created by Edward Winget on 8/25/17.
//  Copyright © 2017 junesiphone. All rights reserved.
//

#ifndef Headers_h
#define Headers_h


#endif /* Headers_h */

//Adding this to CLLocationManger in some weird but awesome way.
@interface CLApproved : CLLocationManager
+ (int)authorizationStatusForBundleIdentifier:(id)arg1;
@end



@interface SBAppSwitcherModel
+ (id)sharedInstance;
- (id)mainSwitcherDisplayItems;
- (id)snapshot;
-(id)snapshotOfFlattenedArrayOfAppIdentifiersWhichIsOnlyTemporary;
@end







@interface SBUserAgent
+(id)sharedUserAgent;
-(void)lockAndDimDevice;
@end


@interface WKPreferences (Private)
- (void)_setAllowFileAccessFromFileURLs:(BOOL)arg1;
- (void)_setAntialiasedFontDilationEnabled:(BOOL)arg1;
- (void)_setCompositingBordersVisible:(BOOL)arg1;
- (void)_setCompositingRepaintCountersVisible:(BOOL)arg1;
- (void)_setDeveloperExtrasEnabled:(BOOL)arg1;
- (void)_setDiagnosticLoggingEnabled:(BOOL)arg1;
- (void)_setFullScreenEnabled:(BOOL)arg1;
- (void)_setJavaScriptRuntimeFlags:(unsigned int)arg1;
- (void)_setLogsPageMessagesToSystemConsoleEnabled:(BOOL)arg1;
- (void)_setOfflineApplicationCacheIsEnabled:(BOOL)arg1;
- (void)_setSimpleLineLayoutDebugBordersEnabled:(BOOL)arg1;
- (void)_setStandalone:(BOOL)arg1;
- (void)_setStorageBlockingPolicy:(int)arg1;
- (void)_setTelephoneNumberDetectionIsEnabled:(BOOL)arg1;
- (void)_setTiledScrollingIndicatorVisible:(BOOL)arg1;
- (void)_setVisibleDebugOverlayRegions:(unsigned int)arg1;
@end

@interface SBControlCenterController : NSObject
+ (id)sharedInstance;
- (void)presentAnimated:(_Bool)arg1;
@end

@interface UIApplication (webview)
@property (nonatomic, retain, readonly) UIApplication *_accessibilityFrontMostApplication;
- (BOOL)_openURL:(id)arg1;
- (void) launchApplicationWithIdentifier: (NSString*)identifier suspended: (BOOL)suspended;
-(void)_runControlCenterBringupTest;
-(void)_bringUpControlCenter;
-(void)_runNotificationCenterBringupTest;
- (void)_runTodayViewPullDownToSpotlight;
- (id)statusBar;
@end

@interface _UIStatusBar : UIView
@end

@interface SBUIController : NSObject
+(SBUIController *)sharedInstanceIfExists;
-(BOOL)isOnAC;
-(int)batteryCapacityAsPercentage;
-(BOOL)handleHomeButtonSinglePressUp;
-(void)_toggleSwitcher;
-(BOOL)clickedMenuButton;
-(void)openAppDrawer;
@end

@interface SBMainSwitcherViewController : NSObject
+ (id)sharedInstance;
- (_Bool)toggleSwitcherNoninteractively;
@end

@interface SBAssistantController : NSObject
+(id)sharedInstance;
-(void)_activateSiriForPPT;
-(void)activateIgnoringTouches;
@end

@interface SBUIPluginManager : NSObject
+ (id)sharedInstance;
- (_Bool)handleActivationEvent:(int)arg1 eventSource:(int)arg2 withContext:(id)arg3;
@end

/*respring*/
@interface SpringBoard : UIApplication
-(void)_relaunchSpringBoardNow;
@property (nonatomic, retain, readonly) UIApplication *_accessibilityFrontMostApplication;
-(void)reboot;
-(void)_runAppSwitcherBringupTest;
@end

@interface FBSystemService : NSObject
+ (id)sharedInstance;
- (void)exitAndRelaunch:(bool)arg1;
- (void)shutdownAndReboot:(bool)arg1;
@end


@interface SBApplication
- (id)displayName;
- (id)bundleIdentifier;
- (id)displayIdentifier;
- (_Bool)isWebApplication;
- (_Bool)isInternalApplication;
- (_Bool)isSystemProvisioningApplication;
- (_Bool)isSystemApplication;
- (_Bool)isSpringBoard;
- (id)_appInfo;
-(int)dataUsage;
- (id)applicationWithBundleIdentifier:(id)arg1;
- (void)uninstallApplication:(id)arg1;
@end

@interface SBMediaController : NSObject
@property(readonly, nonatomic) __weak SBApplication *nowPlayingApplication;
+ (id)sharedInstance;
- (BOOL)togglePlayPauseForEventSource:(long long)arg1;
- (BOOL)changeTrack:(int)arg1 eventSource:(long long)arg2;
- (BOOL)stop;
- (BOOL)togglePlayPause;
- (BOOL)pause;
- (BOOL)play;
- (BOOL)isPaused;
- (BOOL)isPlaying;
- (BOOL)changeTrack:(int)arg1;
@end

@interface SBSearchGesture : NSObject
- (void)revealAnimated:(_Bool)arg1;
@end
@interface SBIconController : UIViewController{
    SBSearchGesture *_searchGesture;
}
+(instancetype)sharedInstance;
- (id)rootIconListAtIndex:(long long)arg1;
- (id)dockListView;
- (id)contentView;
- (id)model;
@property (nonatomic, retain) UIView* contentView;
@property(readonly, nonatomic) SBSearchGesture *searchGesture;
@end

@interface IWWidgetsPopup : UIViewController {
    NSMutableArray* _widgetsList;    
}
-(void)show;
-(id)init;
@end

@interface UIStatusBar : UIView
@end

//@interface MPUNowPlayingController : NSObject
//- (void)startUpdating;
//- (void)stopUpdating;
//@end


/* getting battery */


/* ****    CustomCellForCollectionView    **** */

@interface UIImageCollectionViewCellNew : UICollectionViewCell
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UILabel *textView;
@end

@implementation UIImageCollectionViewCellNew
- (id)initWithFrame:(CGRect)frame{
    self= [super initWithFrame:frame];
    if (self) {
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,20,20)];
        CGFloat borderWidth = 1.0f;
        self.imageView.frame = CGRectInset(self.imageView.frame, -borderWidth, -borderWidth);
        self.imageView.layer.borderColor = [UIColor colorWithRed:0.26 green:0.26 blue:0.26 alpha:1.0].CGColor;
        self.imageView.layer.borderWidth = borderWidth;
        self.imageView.tag = 3000;
        self.textView = [[UILabel alloc] initWithFrame:CGRectMake(2, self.frame.size.height - 24, self.frame.size.width - 35, 15)];
        self.textView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
        self.textView.frame = CGRectInset(self.textView.frame, -borderWidth, -borderWidth);
        self.textView.tintColor = [UIColor whiteColor];
        self.textView.textColor = [UIColor whiteColor];
        self.textView.textAlignment = NSTextAlignmentCenter;
        self.textView.font = [self.textView.font fontWithSize:8];
        self.textView.tag = 100;
        self.textView.alpha = 1;
        self.textView.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.imageView];
        [self.contentView addSubview:self.textView];
    }
    return self;
}
@end

@interface SBHomeScreenView : UIView
@end
