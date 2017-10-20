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


@interface WKPreferences (webview)
@property (assign,setter=_setAllowFileAccessFromFileURLs:,nonatomic) BOOL _allowFileAccessFromFileURLs; 
@end


@interface UIApplication (webview)
@property (nonatomic, retain, readonly) UIApplication *_accessibilityFrontMostApplication;
- (BOOL)_openURL:(id)arg1;
- (void) launchApplicationWithIdentifier: (NSString*)identifier suspended: (BOOL)suspended;
-(void)_runControlCenterBringupTest;
-(void)_runNotificationCenterBringupTest;
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

@interface SBMediaController
@property(readonly, nonatomic) __weak SBApplication *nowPlayingApplication;
+ (id)sharedInstance;
- (BOOL)stop;
- (BOOL)togglePlayPause;
- (BOOL)pause;
- (BOOL)play;
- (BOOL)isPaused;
- (BOOL)isPlaying;
- (BOOL)changeTrack:(int)arg1;
@end

@interface SBIconController : UIViewController
+(instancetype)sharedInstance;
- (id)rootIconListAtIndex:(long long)arg1;
- (id)dockListView;
- (id)contentView;
- (id)model;
@property (nonatomic, retain) UIView* contentView;
@end

@interface IWWidgetsPopup : UIViewController {
    NSMutableArray* _widgetsList;    
}
-(void)show;
-(id)init;
@end


@interface SBSearchGesture : NSObject
-(void)revealAnimated:(BOOL)arg1;
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
