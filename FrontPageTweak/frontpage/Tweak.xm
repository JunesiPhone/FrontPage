#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import "substrate.h"



@interface NSUserDefaults (FrontPage)
- (id)objectForKey:(NSString *)key inDomain:(NSString *)domain;
- (void)setObject:(id)value forKey:(NSString *)key inDomain:(NSString *)domain;
@end

@interface SBIconListView : UIView
- (void)showAllIcons;
@end

@interface SBRootIconListView : SBIconListView
@end

@interface SBDockIconListView : SBRootIconListView
@end

@interface SBLockScreenManager
	+(id)sharedInstance;
	-(BOOL)isUILocked;
@end

@interface SpringBoard : NSObject
	- (void)_relaunchSpringBoardNow;
	+(id)sharedInstance;
	-(void)clearMenuButtonTimer;
@end

@interface SBIconListPageControl : UIPageControl
-(void)setIsFading:(BOOL)value;
-(BOOL)isFading;
@end


@interface UIApplication (edited)
-(id)_accessibilityFrontMostApplication;
- (id)statusBar;
@end

// @interface UIStatusBar
//   -(void)setForegroundColor:(UIColor *)arg1;
//   - (void)setHidden:(BOOL)arg1;
// @end




@interface UIConcreteLocalNotification
- (id)fireDate;
-(id)userInfo;
@end

@interface SBFolderView : UIView
@end

@interface SBFolderView (edited)
@end

@interface SBFolderController : NSObject
@property (nonatomic,retain,readonly) SBFolderView* contentView;
@end

@interface SBIconController : UIViewController
-(SBFolderController*)_rootFolderController;
+(instancetype)sharedInstance;
- (id)rootIconListAtIndex:(long long)arg1;
- (id)dockListView;
- (id)contentView;
- (id)model;
@property (nonatomic, retain) UIView* contentView;
@end

@interface NSDistributedNotificationCenter
+ (id)defaultCenter;
@end

@interface SBApplicationController
- (void)applicationService:(id)arg1 setBadgeValue:(id)arg2 forBundleIdentifier:(id)arg3;
- (void)applicationsAdded:(id)arg1;
+(id)lastBundleName;
@end

@interface SBBadgeCountRecipe
+ (id)title;
- (void)_changeBadge:(int)arg1;
- (void)handleVolumeDecrease;
- (void)handleVolumeIncrease;
@end

@interface SBIcon
- (void)setBadge:(id)arg1;
-(void)noteBadgeDidChange;
@end

@interface SBMainSwitcherViewController
- (void)switcherContentController:(id)arg1 selectedItem:(id)arg2;
- (void)switcherContentController:(id)arg1 deletedItem:(id)arg2;
@end

@interface MPUNowPlayingController : NSObject
- (void)_updateCurrentNowPlaying;
- (void)_updateNowPlayingAppDisplayID;
- (void)_updatePlaybackState;
- (void)_updateTimeInformationAndCallDelegate:(BOOL)arg1;
- (BOOL)currentNowPlayingAppIsRunning;
- (id)nowPlayingAppDisplayID;
- (double)currentDuration;
- (double)currentElapsed;
- (id)currentNowPlayingArtwork;
- (id)currentNowPlayingArtworkDigest;
- (id)currentNowPlayingInfo;
- (id)currentNowPlayingMetadata;
-(void)startUpdating;
@end

@interface FrontPageViewController : UIViewController
+(instancetype)sharedInstance;
-(void) hitPoint:(CGPoint)point withEvent:(UIEvent *)event;

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
@end

@interface BBServer : NSObject
- (id)allBulletinIDsForSectionID:(id)arg1;
@end

@interface BBBulletin : NSObject
@property(copy) NSString *sectionID;
@property(copy) NSString *bulletinID;
@property(copy) NSDictionary *context;
@property(copy) NSString *section;
@property(copy) NSString *message;
@property(copy) NSString *subtitle;
@property(copy) NSString *title;
@end

@interface SBUserAgent
+(id)sharedUserAgent;
-(void)lockAndDimDevice;
@end

@interface SBDockView : UIView
+ (double)defaultHeight;
@end

@interface SBIconScrollView : UIView
@end
@interface SBRootFolderView : UIView
@end

//extern "C" Boolean _AXSReduceMotionEnabled();
//extern "C" void _AXSSetReduceMotionEnabled(BOOL enabled);

static float deviceVersion = [[[UIDevice currentDevice] systemVersion] floatValue];

static NSString *nsDomainString = @"com.junesiphone.frontpage";
static NSString *nsNotificationString = @"com.junesiphone.frontpage/preferences.changed";
static BOOL enabled = NO;
static BOOL top = NO;

static BOOL hideIcons = NO;
static BOOL hideDock = NO;
static BOOL hideDots = NO;

static BOOL applied;
static BOOL loaded;
static BOOL iconlock;
static BOOL interaction;

static Class principalClass;
static id instance;
static UIView *insView;
static UIView *topViewSB;
static UIColor *color = [UIColor clearColor];
NSBundle *FPBundle;


// /* Hiding Dock */
static void goHideDock(){
	SBDockIconListView* dockListView = [[objc_getClass("SBIconController") sharedInstance] dockListView];
	SBDockView* dockView = (SBDockView*)[dockListView superview];
	if(hideDock){
		dockView.alpha = 0;
		dockView.userInteractionEnabled = NO;
		dockView.hidden = YES;
	}
	//hidingDock = YES;
}
static void goShowDock(){
	SBDockIconListView* dockListView = [[objc_getClass("SBIconController") sharedInstance] dockListView];
	SBDockView* dockView = (SBDockView*)[dockListView superview];
	if(!hideDock){
		dockView.alpha = 1;
		dockView.userInteractionEnabled = YES;
		dockView.hidden = NO;
	}
	//hidingDock = NO;
}


// %hook SBDockView
// 	-(void)setBackgroundAlpha:(double)arg1{
// 		if(hideDots){
// 			%orig(0.0);
// 		}else{
// 			%orig(1.0);
// 		}
// 	}
// %end

/* Hide Dots */


static void goHideDots(){
	//hidingDots = YES;
	SBFolderView* folderView = [[objc_getClass("SBIconController") sharedInstance] _rootFolderController].contentView;
	if (!folderView) return;
	SBIconListPageControl* pageControl = MSHookIvar<SBIconListPageControl*>(folderView, "_pageControl");
	pageControl.alpha = 0;
	pageControl.hidden = YES;
}
static void goShowDots(){
	//hidingDots = NO;
	SBFolderView* folderView = [[objc_getClass("SBIconController") sharedInstance] _rootFolderController].contentView;
	if (!folderView) return;
	SBIconListPageControl* pageControl = MSHookIvar<SBIconListPageControl*>(folderView, "_pageControl");
	pageControl.alpha = 1;
	pageControl.hidden = NO;
}

/* If user swipes down to show search pagedots will show again */
%hook SBIconListPageControl
	- (double)defaultHeight{
		if(hideDots){
			self.alpha = 0;

			self.hidden = YES;
		}
		return %orig;
	}
%end

static void hideShowItems(){
	topViewSB = [[%c(SBIconController) sharedInstance] _rootFolderController].contentView;
	for(UIView *v in topViewSB.subviews){
	     if([v isKindOfClass:[UIView class]] && !v.hidden){
	     	topViewSB = v;
	     }
	}
		[topViewSB addSubview:insView];
	if(!top){
		 [topViewSB sendSubviewToBack:insView];
	}else{
		[topViewSB bringSubviewToFront:insView];
	}
	if(!hideDots){
		goShowDots();
	}else{
		goHideDots();
	}
	if(!hideDock){
		goShowDock();
	}else{
		goHideDock();
	}
}
//when app closes? and when screen unlocks
%hook SBLockScreenManager
	-(void)_finishUIUnlockFromSource:(int)arg1 withOptions:(id)arg2 {
		%orig;
		hideShowItems();
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.junesiphone.frontpage.deviceunlock"), NULL, NULL, true);
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.junesiphone.frontpage.updatingsystem"), NULL, NULL, true);
	}
%end

static void showRespringAlert(){
	NSLog(@"FPRespring called");
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.junesiphone.frontpage.alertrespring"), NULL, NULL, true);
}
static void disableFrontPage(){
	[insView removeFromSuperview];
	insView = nil;
	topViewSB = nil;
	applied = NO;
	principalClass = nil;
	instance = nil;
	enabled = NO;
	top = 0;
	hideDock = NO;
	hideIcons = NO;
	hideDots = NO;

	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:@"enabled" inDomain:nsDomainString];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:@"top" inDomain:nsDomainString];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:@"hideDots" inDomain:nsDomainString];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:@"hideDock" inDomain:nsDomainString];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:@"hideIcons" inDomain:nsDomainString];

	[[NSUserDefaults standardUserDefaults] synchronize];
	 goShowDots();
	 goShowDock();
	 if(deviceVersion < 11){
	 	[[objc_getClass("SBUserAgent") sharedUserAgent]lockAndDimDevice];
	 }else{
	 	showRespringAlert();
	 }
	//_AXSSetReduceMotionEnabled(NO);
	//[[objc_getClass("SBUserAgent") sharedUserAgent]lockAndDimDevice];
}

//topViewSB = ((SBIconController*)[%c(SBIconController) sharedInstance]).contentView;
static void loadFrontPage(){
	NSLog(@"FPStatus loading");
	if(!applied){
		if((SBIconController*)[%c(SBIconController) sharedInstance]){
    		/*
				Goal: Find a view on the SBRootFolderView that isn't hidden. This is directly under IconScrollView
				so it will get touches when we disable them in the IconScrollView
    		*/
			topViewSB = [[%c(SBIconController) sharedInstance] _rootFolderController].contentView;

			//d=[[SBIconController sharedInstance] _rootFolderController].contentView

			for(UIView *v in topViewSB.subviews){
			     if([v isKindOfClass:[UIView class]] && !v.hidden){
			     	topViewSB = v;
			     }
			}
		}else{
			topViewSB = nil;
		}

		if(topViewSB){
			FPBundle = [NSBundle bundleWithPath:@"/Library/FrontPage/FrontPageViewController.bundle"];
			[FPBundle load];
			principalClass = [FPBundle principalClass];
			instance = [[principalClass alloc] init];
			UIViewController *ins = instance;
			insView = ins.view;
			insView.tag = 12345679;
			[topViewSB addSubview:insView];
			if(interaction){
				insView.userInteractionEnabled = NO;
			}else{
				insView.userInteractionEnabled = YES;
			}
			if(!top){
				[topViewSB sendSubviewToBack:insView];
			}else{
				[topViewSB bringSubviewToFront:insView];
				//_AXSSetReduceMotionEnabled(YES);
			}
			applied = YES;
		}
	}
	if(iconlock){
			CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.junesiphone.frontpage.iconLock"), NULL, NULL, true);
		}else{
			CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.junesiphone.frontpage.iconUnlock"), NULL, NULL, true);
		}
}

// When app opens
%hook SBWorkspace
	-(id)_slaveTransactionsForTransitionRequest:(id)arg1{
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.junesiphone.frontpage.updatingswitcher"), NULL, NULL, true);
		return %orig;
	}
	-  (void)sceneManager:(id)arg1 willCommitUpdateForScene:(id)arg2 transactionID:(unsigned long long)arg3{
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.junesiphone.frontpage.updatingswitcher"), NULL, NULL, true);
		return %orig;
	}
%end

/*
	Goal: If icon is pressed Open app, if not block touches to allow view below (FrontPage) to use them.
	SideEffect: ScrollView cannot be scrolled unless an icon is the point of the scroll.
	Fix: I have no clue, but works in this case.

	Update: Instead of checking if an icon is pressed, check what is under the icon. Specifically check
	the subview with our tag. If our tag is found and something is tappable block the view. Otherwise
	it allows easy scrolling and still opens icons.
	SideEffect: If an icon is tapped and it is on top of the widget it wont open the app.

	Update: Just do 2 loops. One to check if something in our view is tappable. The other to check
	if an icon is being tapped. If an icon isn't being tapped cancel it so our view can grab it. If
	an icon is tapped grab it. BOOM!

	Final Note for now. This makes our background widgets tappable, but the widget must define its
	width and height because the webview grabs everything. So if we narrow the view to the exact size
	we will have a small tappable section. Each theme in the plist contains width, height, x and y.
	y can be set to fromtop:100, frombottom:100, fromleft:100, fromright:100 or center. Width can be auto or an int, same for height
*/

%hook SBRootIconListView
	-(double)sideIconInset{
		if(hideIcons){
			self.hidden = YES;
		}	
		return %orig;
	}
%end

%hook SBIconController

- (void)popToCurrentRootIconListWhenPossible{ //don't need relayout if icons are hidden
	if(!hideIcons){
		%orig;
	}
}

- (void)popToCurrentRootIconList{ //don't need relayout if icons are hidden
	if(!hideIcons){
		%orig;
	}
}

/* causes folder in dock to not hide */

// - (void)popExpandedIconFromLocation:(long long)arg1 withTransitionRequest:(id)arg2 animated:(_Bool)arg3 completion:(id)arg4{ //don't need relayout if icons are hidden
// 	if(!hideIcons){
// 		%orig;
// 	}
// }

/* causes issues on iOS10 */

// - (void)popExpandedIconWithTransitionRequest:(id)arg1 animated:(_Bool)arg2 completion:(id)arg3{ //don't need relayout if icons are hidden
// 	if(!hideIcons){
// 		%orig;
// 	}
// }

- (void)layoutMonitor:(id)arg1 didUpdateDisplayLayout:(id)arg2 withContext:(id)arg3{ //don't need relayout if icons are hidden
	if(!hideIcons){
		%orig;
	}
}


- (_Bool)isDisplayingIcon:(id)arg1 inLocation:(long long)arg2{ //stops animation to icon when app is opened or closed
	if(hideIcons){
		return NO;
	}else{
		return %orig;
	}
}
%end

%hook SBIconScrollView
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
	if(!top && applied){
		bool isSomethingToTapInOurView = nil;
		bool isAnIconBeingTapped = nil;
		for (UIView* subviewInOurs in self.superview.subviews ) {
			if((UIView*)[subviewInOurs viewWithTag:12345679]){
    			if ( [subviewInOurs hitTest:[self convertPoint:point toView:subviewInOurs] withEvent:event] != nil ) {
    				isSomethingToTapInOurView = YES;
				}
    		}
	    }
	    for (UIView* subview in self.subviews ) {
	        if ( [subview hitTest:[self convertPoint:point toView:subview] withEvent:event] != nil ) {
	            if([subview isKindOfClass:[%c(SBRootIconListView) class]] || [subview isKindOfClass:[%c(IWWidgetsView) class]]){ //we only want to check SBRootIconList now. Could add iWidgets.
	            	for (UIView* subview2 in subview.subviews ) {
	            		if ( [subview2 hitTest:[self convertPoint:point toView:subview2] withEvent:event] != nil ) {
	            			isAnIconBeingTapped = YES;
	            		}
	            	}
	            }
	        }
	    }
	    if(isSomethingToTapInOurView && !isAnIconBeingTapped){
	    	return NO;
	    }
	    return %orig;
	}else{
		return %orig;
	}
}
%end

//Animations with Reduce Motion on. //Found hooks https://github.com/greenywd/NoMotion/blob/master/Tweak.xm
// %group effect_group
// 	%hook _UIMotionEffectEngine
// 	+ (BOOL)_motionEffectsSupported{
// 		if(top){
// 			return YES;
// 		}else{
// 			return %orig;
// 		}
// 	}

// 	+ (BOOL)_motionEffectsEnabled{
// 	    if(top){
// 			return YES;
// 		}else{
// 			return %orig;
// 		}
// 	}
// 	%end

// 	%hook UIView
// 	+ (BOOL)_shouldEnableUIKitDefaultParallaxEffects{
// 	    if(top){
// 			return YES;
// 		}else{
// 			return %orig;
// 		}
// 	}

// 	+ (BOOL)_motionEffectsEnabled{
// 	    if(top){
// 			return YES;
// 		}else{
// 			return %orig;
// 		}
// 	}

// 	+ (BOOL)_motionEffectsSupported{
// 	    if(top){
// 			return YES;
// 		}else{
// 			return %orig;
// 		}
// 	}
// 	%end
// %end //effect_group

/* End Switcher Updates */

// static void checkStatusbar(){
// 	UIApplication *sbapp = [objc_getClass("UIApplication") sharedApplication];
// 			SBLockScreenManager *lsMan = [objc_getClass("SBLockScreenManager") sharedInstance];
// 			NSString *ckBundle = [[sbapp _accessibilityFrontMostApplication] bundleIdentifier];
// 			BOOL onLS = [lsMan isUILocked];
// 	        BOOL onSB = ckBundle == nil ? YES : NO;
// 	        if(SBStat && onSB && !onLS){
// 	        	UIView* statusbar = [[objc_getClass("UIApplication") sharedApplication] statusBar];
// 	        	UIStatusBarForegroundView *foregroundView = MSHookIvar<UIStatusBarForegroundView *>(statusbar, "_foregroundView");
// 				[foregroundView setHidden:YES];
// 				foregroundView.alpha = 0;
// 				//foregroundView.backgroundColor = color;
// 				HBLogInfo(@"stbar  FGView %@", foregroundView);
// 	        }else{
// 	        	if(LSStat && onLS){
// 					UIView* statusbar = [[objc_getClass("UIApplication") sharedApplication] statusBar];
//     				UIStatusBarForegroundView *foregroundView = MSHookIvar<UIStatusBarForegroundView *>(statusbar, "_foregroundView");
// 					[foregroundView setHidden:YES];
// 					foregroundView.alpha = 0;
// 					//foregroundView.backgroundColor = color;
// 				}
// 	        }
// }


%hook SpringBoard
-(void)applicationDidFinishLaunching:(id)application{
    %orig;
}


//[statusBar setForegroundAlpha:0 animationParameters:animationParams];
-(void)frontDisplayDidChange:(id)arg1{
	hideShowItems();
    %orig;
}
-(long long)_frontMostAppOrientation{
	//goHideDock();
	return %orig;
}

- (_Bool)isShowingHomescreen{
	bool isShowing = %orig;

	if(isShowing){
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.junesiphone.frontpage.updatingmusic"), NULL, NULL, true);
	}
	//%init(statusbarHider);
    //%init(effect_group);

	loaded = YES;
    if(enabled){
    	loadFrontPage();
      	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.junesiphone.frontpage.updatingapps"), NULL, NULL, true);
     }
	return %orig;
}
%end



/* Stole from InfoStats2 by Matchstic: https://github.com/Matchstic/InfoStats2/blob/3070e9bdf3b8d18e7cb7df014dcb70954709751f/InfoStats2/InfoStats2.xm */
static MPUNowPlayingController *globalMPUNowPlaying;
%hook MPUNowPlayingController
- (id)init {
    id orig = %orig;
    globalMPUNowPlaying = orig;
    return orig;
}

%new
+(id)_frontpage_currentNowPlayingInfo {
    return [globalMPUNowPlaying currentNowPlayingInfo];
}

%new
+(id)_frontpage_albumArt{
	if([globalMPUNowPlaying currentNowPlayingArtwork] == NULL){
		MPUNowPlayingController *nowPlayingController=[[objc_getClass("MPUNowPlayingController") alloc] init];
		[nowPlayingController startUpdating];
		return [nowPlayingController currentNowPlayingArtwork];
	}
	return [globalMPUNowPlaying currentNowPlayingArtwork];
}
%end


%hook SBStatusBarStateAggregator
- (void)_notifyItemChanged:(int)arg1{
	%orig;
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.junesiphone.frontpage.updatingstatusbar"), NULL, NULL, true);
}
%end


%hook SBUIController
- (void)updateBatteryState:(id)arg1{
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.junesiphone.frontpage.updatingbattery"), NULL, NULL, true);
	%orig;
}

%end

// MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef information) {
//         NSLog(@"FPMusic We got the information: %@", information);
// 	});

%hook SBMediaController
- (void)_mediaRemoteNowPlayingInfoDidChange:(id)arg1{
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.junesiphone.frontpage.updatingmusic"), NULL, NULL, true);
	return %orig;
}

- (void)_nowPlayingInfoChanged{
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.junesiphone.frontpage.updatingmusic"), NULL, NULL, true);
	return %orig;
}
%end

/*
	Detects when any badges change, forwards that to the FPViewController which gathers all icon badges and forwards to the webview object for themes to use;
*/
static NSMutableDictionary *appBadge = [[NSMutableDictionary alloc]init];

%hook SBUserAgent
- (void)setBadgeNumberOrString:(id)arg1 forApplicationWithID:(id)arg2{
	%orig;
	// NSLog(@"FrontPageLog FROMTWEAK %@", arg1);
	// NSLog(@"FrontPageLog FROMTWEAK %@", arg2);
	NSString *bg = [NSString stringWithFormat:@"%@", arg1];
	if([bg isEqualToString:@""]){
		bg = @"0";
	}
		//CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.junesiphone.frontpage.updatingapps"), NULL, NULL, true);
    if(arg2){
          [appBadge setObject:bg forKey:@"value"];
          [appBadge setObject:arg2 forKey:@"bundle"];
    }
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.junesiphone.frontpage.app"), NULL, NULL, true);
}
%end


/* SBApplication handles if badges need changed from within app. Example if you delete a mail SBUserAgent won't get the message, SBApplicationController will */
%hook SBApplicationController

%new
+(id)lastBundleName{
  return appBadge;
}

/* note: if string is "" it will cause issues*/
- (void)applicationService:(id)arg1 setBadgeValue:(id)arg2 forBundleIdentifier:(id)arg3{
  	%orig;
  	NSString *bg = [NSString stringWithFormat:@"%@", arg2];
  	if([bg isEqualToString:@""] || [bg isEqualToString:@"(null)"]){
		bg = @"0";
	}
  	if(arg3){
		[appBadge setObject:bg forKey:@"value"];
		[appBadge setObject:arg3 forKey:@"bundle"];
  	}
  	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.junesiphone.frontpage.app"), NULL, NULL, true);
  	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.junesiphone.frontpage.updatingnotifications"), NULL, NULL, true);
}

- (void)_sendInstalledAppsDidChangeNotification:(id)arg1 removed:(id)arg2 modified:(id)arg3{
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.junesiphone.frontpage.newappinstalled"), NULL, NULL, true);
	%orig;
}
%end


//Alarm
static NSMutableDictionary *alarmsUIConcreteLocalNotifications = [[NSMutableDictionary alloc]init];
%hook SBClockDataProvider

-(void)_handleClockNotificationUpdate:(id)arg1{
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.junesiphone.frontpage.updatingalarm"), NULL, NULL, true);
	%orig;
}

-(void)_publishAlarmsWithScheduledNotifications:(__unsafe_unretained UIConcreteLocalNotification*)arg1{
	if(arg1 != nil){
		[alarmsUIConcreteLocalNotifications setObject: arg1 forKey:@"alarms"];
	}
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.junesiphone.frontpage.updatingalarm"), NULL, NULL, true);
	return %orig;
}

%new
+(id)frontpage_alarms{
	return alarmsUIConcreteLocalNotifications;
}
%end


//BBServer - Notifications
static BBServer *sharedServer;
static NSMutableDictionary *ncNotificationCounts2 = [[NSMutableDictionary alloc]init];

%hook BBServer

%new
+(id)frontpage_ids{
	return ncNotificationCounts2;
}

-(id)init {
    sharedServer = %orig;
    return sharedServer;
}

-(void)publishBulletin:(__unsafe_unretained BBBulletin*)arg1 destinations:(unsigned long long)arg2 alwaysToLockScreen:(_Bool)arg3 {
	if(arg1.message){
		 NSMutableDictionary *ncNotificationCounts = [[NSMutableDictionary alloc]init];
    	[ncNotificationCounts setObject:arg1.message forKey:@"text"];
    	[ncNotificationCounts setObject:[arg1.sectionID copy] forKey:@"bundle"];
    	[ncNotificationCounts2 setObject:ncNotificationCounts forKey:[arg1.bulletinID copy]];
    	ncNotificationCounts = nil;
	}
    %orig;
}
%end

// static void appClosed(){
// 	hideShowItems();
// }

static void notificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {

	NSNumber *inter = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"userinteraction" inDomain:nsDomainString];

	NSNumber *n = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"enabled" inDomain:nsDomainString];
	NSNumber *t = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"top" inDomain:nsDomainString];
  	NSNumber *c = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"iconlock" inDomain:nsDomainString];

  	NSNumber *dots = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"hideDots" inDomain:nsDomainString];
  	NSNumber *dock = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"hideDock" inDomain:nsDomainString];
  	NSNumber *icons = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"hideIcons" inDomain:nsDomainString];


	enabled = (n)? [n boolValue]:NO;
	top = (t)? [t boolValue]:NO;
	iconlock = (c)? [c boolValue]:NO;

	interaction = (inter)? [inter boolValue]:NO;

	hideIcons = (icons) ? [icons boolValue] : NO;
	hideDock = (dock) ? [dock boolValue] : NO;
	hideDots = (dots) ? [dots boolValue] : NO;

	if(interaction){
		if(insView){
			insView.userInteractionEnabled = NO;
		}
	}else{
		if(insView){
			insView.userInteractionEnabled = YES;
		}
	}

	if(iconlock){
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.junesiphone.frontpage.iconLock"), NULL, NULL, true);
	}else{
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.junesiphone.frontpage.iconUnlock"), NULL, NULL, true);
	}

	if(loaded){
		//hideShowItems();
	}

	if(enabled){
		//_AXSSetReduceMotionEnabled(YES);
		if (!applied) {
	        if (loaded) {
	            loadFrontPage();
	        }
	    }
	}else{
	    if (insView) {
	    	instance = nil;
	        [insView removeFromSuperview];
	        disableFrontPage();
	    }
	    if(applied){
	    	//[[objc_getClass("SBUserAgent") sharedUserAgent]lockAndDimDevice];
	    }
	    applied = NO;
	    top = NO;
	}
}


%ctor {
	notificationCallback(NULL, NULL, NULL, NULL, NULL);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
		NULL,
		notificationCallback,
		(CFStringRef)nsNotificationString,
		NULL,
		CFNotificationSuspensionBehaviorCoalesce);

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
        NULL,
		(CFNotificationCallback)disableFrontPage,
        CFSTR("com.junesiphone.frontpage.disableFrontPage"),
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately);
}
