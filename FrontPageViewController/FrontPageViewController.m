//
//  FrontPageViewController.m
//  FrontPageViewController
//
//  Created by Edward Winget on 5/21/17.
//  Copyright © 2017 junesiphone. All rights reserved.
//

#import "FrontPageViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CydiaSubstrate/CydiaSubstrate.h>
#import <CoreFoundation/CoreFoundation.h>

#include "MediaRemote.h"
#import <objc/runtime.h>
#import <notify.h>
#import "Weather.h"
#include <dlfcn.h>
#import <AudioToolbox/AudioServices.h>
#include <unicode/utf8.h>

#import "FPISystem.h"
#import "FPIBattery.h"
#import "FPIStatusBar.h"
#import "FPISwitcher.h"
#import "FPIApps.h"
#import "FPIMusic.h"
#import "FPIWeather.h"
#import "FPINotifications.h"
#import "FPIFolders.h"
#import "FPIAlarm.h"
#import "FPIApp.h"
#import "FPIMemory.h"

#import <sys/utsname.h>


#define deviceVersion [[[UIDevice currentDevice] systemVersion] floatValue]


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

/* ****    Open Apps    **** */
@interface UIApplication (Undocumented)
- (BOOL)_openURL:(id)arg1;
- (void) launchApplicationWithIdentifier: (NSString*)identifier suspended: (BOOL)suspended;
@property (nonatomic, retain, readonly) UIApplication *_accessibilityFrontMostApplication;
-(void)_runControlCenterBringupTest;
-(void)_runNotificationCenterBringupTest;

@end

@interface SBUserAgent
+(id)sharedUserAgent;
-(void)lockAndDimDevice;
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

//@interface MPUNowPlayingController : NSObject
//- (void)startUpdating;
//- (void)stopUpdating;
//@end


/* getting battery */
@interface SBUIController : NSObject
+(SBUIController *)sharedInstanceIfExists;
-(BOOL)isOnAC;
-(int)batteryCapacityAsPercentage;
-(BOOL)handleHomeButtonSinglePressUp;
-(BOOL)clickedMenuButton;
@end

/* ****    CustomCellForCollectionView    **** */

@interface UIImageCollectionViewCell : UICollectionViewCell
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UILabel *textView;
@end

@implementation UIImageCollectionViewCell
- (id)initWithFrame:(CGRect)frame
{
    self= [super initWithFrame:frame];
    if (self) {
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,20,20)];
        CGFloat borderWidth = 1.0f;
        self.imageView.frame = CGRectInset(self.imageView.frame, -borderWidth, -borderWidth);
        self.imageView.layer.borderColor = [UIColor colorWithRed:0.26 green:0.26 blue:0.26 alpha:1.0].CGColor;
        self.imageView.layer.borderWidth = borderWidth;
        
        self.textView = [[UILabel alloc] initWithFrame:CGRectMake(2, self.frame.size.height - 24, self.frame.size.width - 35, 15)];
        self.textView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
        self.textView.frame =self.imageView.frame = CGRectInset(self.textView.frame, -borderWidth, -borderWidth);
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

/* ****    MainTweakView    **** */
@interface FrontPageViewController ()
//@property (strong, nonatomic) MPUNowPlayingController *musicController;
@end


@implementation FrontPageViewController
/*
    The idea is to grab a notification from tweak.xm which hooks certain methods to get updates of certain items.
 
    The messages go to 
    com.junesiphone.frontpage.updatingbadge
    com.junesiphone.frontpage.updatingmusic
    com.junesiphone.frontpage.updatingbattery
    com.junesiphone.frontpage.updatingstatusbar
    com.junesiphone.frontpage.updatingswitcher
 
    Each on of these will call functions in the webview. 
    loadSwitcher()
    loadStatusBar()
    loadBadges()
    loadMusic()
    loadSystem()
 
    It doesn't matter if the functions exist in the webview, it seems to handle that well.
    Each time one of the functions is updated it updates info for it to setFPIInfo()
 
    setFPIInfo() takes info sent to it and adds it to the global object FPI.
    user can get at items easy
 
    document.getElementById('battery').innerHTML = FPI.system.battery;
    you could put this in loadSystem() or loadStatusBar()
 
    The goal below is to get these messages then sent to webview. It doesn't need to do this when the
    screen is off of when an app is open.
 
    To do this I just track when an app is open, then if any messages are sent it will check if the app is closed.
 
 */
bool switcherPending = NO;
bool statusbarPending = NO;
bool badgesPending = NO;
bool musicPending = NO;
bool systemPending = NO;
bool batteryPending = NO;
bool appsPending = NO;
bool notificationsPending = NO;
bool alarmPending = NO;

-(BOOL)canReloadData{ //return for block
    return isVisible; //isVisible is changed when the screen is on notification in viewDidLoad
}
-(BOOL)checkisInApp{ //return for block
    return isInApp; //isInApp is changed by checkIfAppIsCovering
}
-(void)setStatusBarPending:(BOOL)pending{
    statusbarPending = pending;
}
-(BOOL)getStatusBarPending{
    return statusbarPending;
}
-(void)setBatteryPending:(BOOL)pending{
    batteryPending = pending;
}
-(BOOL)getBatteryPending{
    return batteryPending;
}
-(void)setSystemPending:(BOOL)pending{
    systemPending = pending;
}
-(BOOL)getSystemPending{
    return systemPending;
}
-(void)setSwitcherPending:(BOOL)pending{
    switcherPending = pending;
}
-(BOOL)getSwitcherPending{
    return switcherPending;
}
-(void)setAppsPending:(BOOL)pending{
   appsPending = pending;
}
-(BOOL)getAppsPending{
    return appsPending;
}
-(void)setMusicPending:(BOOL)pending{
    musicPending = pending;
}
-(BOOL)getMusicPending{
    return musicPending;
}
-(void)setNotificationsPending:(BOOL)pending{
    notificationsPending = pending;
}
-(BOOL)getNotificationsPending{
    return notificationsPending;
}
-(void)setAlarmPending:(BOOL)pending{
    alarmPending = pending;
}
-(BOOL)getAlarmPending{
    return alarmPending;
}

// checks if there were updates while the app was opened. If app was opened we pause updates.
// If the user closes the app, the info that was pending should be updated
-(void)checkPendingNotifications{
    BOOL showing = [self canReloadData];
    BOOL inapp = [self checkisInApp];
    if(showing && !inapp){
        if(batteryPending){
            [FPIBattery updateBatteryWithObserver:self];
        }
        if(systemPending){
            [FPISystem updateSystemWithObserver:self];
        }
        if(badgesPending){
            [FPIApps updateAppsWithObserver:self];
            [FPISwitcher updateSwitcherWithObserver:self];
        }
        if(appsPending){
            [FPIApps updateAppsWithObserver:self];
        }
        if(musicPending){
            [FPIMusic updateMusicWithObserver:self];
            
        }
        if(statusbarPending){
            [FPIStatusBar updateStatusBarWithObserver:self];
            
            //[self updateStatusBar];
        }
        if(switcherPending){
            // [self updateSwitcherApps];
            [FPISwitcher updateSwitcherWithObserver:self];
        }
        if(notificationsPending){
            [FPINotifications updateNotificationsWithObserver:self];
        }
        if(alarmPending){
            [FPIAlarm updateAlarmWithObserver:self];
        }
    }
}

//_accessibilityFrontMostApplication will return null if on springboard
-(void)checkIfAppIsCovering{
    UIApplication* app = [[objc_getClass("SpringBoard") sharedApplication] _accessibilityFrontMostApplication];
    if(app){
        isInApp = YES;
    }else{
        isInApp = NO;
    }
}


void respringNotification (CFNotificationCenterRef center,FrontPageViewController * observer,CFStringRef name,const void * object,CFDictionaryRef userInfo) {
    [observer respring];
    
  
}
void deviceUnlock (CFNotificationCenterRef center,FrontPageViewController * observer,CFStringRef name,const void * object,CFDictionaryRef userInfo) {
    [observer callJSFunction:@"deviceUnlocked()"];
}
void openMenu (CFNotificationCenterRef center,FrontPageViewController * observer,CFStringRef name,const void * object,CFDictionaryRef userInfo) {
    [observer showMenu];
    [observer pressHomeButton];
}



/*
 Double tap on webview gives you copy/paste menu. We don't want this.
 We do want this in the terminal view of our webview.
 Here we find out if in terminal and hide paste menu accordingly.
*/

bool inTerminal = NO;
-(void)isInTerminal{
    inTerminal = YES;
}
-(void)isntInTerminal{
    inTerminal = NO;
}

-(void)pressHomeButton{
    if(deviceVersion >= 10.0){
        [[objc_getClass("SBUIController") sharedInstance] handleHomeButtonSinglePressUp];
    }else{
        [[objc_getClass("SBUIController") sharedInstance] clickedMenuButton];
    }
}
//hide the paste buttons on webview, except when in terminal
-(void)processit:(id)sender {
    if(!inTerminal){
        UIMenuController *menu = [UIMenuController sharedMenuController];
        [menu setMenuVisible:NO];
        [menu performSelector:@selector(setMenuVisible:) withObject:[NSNumber numberWithBool:NO] afterDelay:0];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //notification for when webview will show copy/paste
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processit:) name:UIMenuControllerWillShowMenuNotification object:nil];

    isVisible = YES;
    self.view.backgroundColor = [UIColor clearColor];
    
    //detect orientation
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(orientationChanged:)
     name:UIDeviceOrientationDidChangeNotification
     object:[UIDevice currentDevice]];
    
    FrontPageViewController *observer = self;
    
    //set notifications for respring, open FrontPage menu, device lock, and screen off.
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    (__bridge const void *)(observer),
                                    (CFNotificationCallback)respringNotification,
                                    CFSTR("com.junesiphone.frontpage.respring"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately
                                    );
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    (__bridge const void *)(observer),
                                    (CFNotificationCallback)openMenu,
                                    CFSTR("com.junesiphone.frontpage.openmenu"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately
                                    );
    
    
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    (__bridge const void *)(observer),
                                    (CFNotificationCallback)deviceUnlock,
                                    CFSTR("com.junesiphone.frontpage.deviceunlock"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately
                                    );
    //detect screen on or off
    int status = notify_register_dispatch("com.apple.springboard.hasBlankedScreen",
                                          &notifyToken,
                                          dispatch_get_main_queue(), ^(int t) {
                                              uint64_t state;
                                              int result = notify_get_state(notifyToken, &state);
                                              if(state == 0){
                                                  isVisible = YES;
                                              }else{
                                                  isVisible = NO;
                                              }
                                              if (result != NOTIFY_STATUS_OK) {
                                                  NSLog(@"FrontPage - notify_get_state() not returning NOTIFY_STATUS_OK");
                                              }
                                          });
    if (status != NOTIFY_STATUS_OK) {
        NSLog(@"FrontPage - notify_register_dispatch() not returning NOTIFY_STATUS_OK");
    }
    
    [self loadSaved];   //Load a plist to see if any themes are currently applied, if not prepare plist.
    [self addGestures]; //Add gestures to current view
    [self loadWebView]; //Load widget
}

- (void) orientationChanged:(NSNotification *)note{
    UIDevice * device = note.object;
    switch(device.orientation)
    {
        case UIDeviceOrientationPortrait:
            [_themeView setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
            [self callJSFunction:@"viewRotated('portrait')"];
            break;
            
        case UIDeviceOrientationPortraitUpsideDown:
            [_themeView setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
            [self callJSFunction:@"viewRotated('portraitdown')"];
            break;
        case UIDeviceOrientationLandscapeLeft:
            [_themeView setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height )];
            [self callJSFunction:@"viewRotated('landscapeleft')"];
            break;
        case UIDeviceOrientationLandscapeRight:
            [_themeView setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
            [self callJSFunction:@"viewRotated('landscaperight')"];
            break;
            
        default:
            break;
    };
}

/* saves state of widget. If a theme is selected it gets writtent to the plistPath. When the device resprings
    or reboots the last theme loaded will be shown.
*/
-(void)loadSaved{
    _plistPath = @"var/mobile/Documents/FrontPage.plist";
    if([[NSFileManager defaultManager] fileExistsAtPath:_plistPath]){
        _frontPageSettings = [NSMutableDictionary dictionaryWithContentsOfFile:_plistPath];
        if([_frontPageSettings objectForKey:@"Selected"]){
            themeSelected = YES;
        }
    }else{
        _frontPageSettings = [[NSMutableDictionary alloc] init];
    }
}

/* 
    Two Finger Down Gesture shows the themeSetupView where users can select a theme.
 
*/

-(void)addGestures{
    UISwipeGestureRecognizer *downRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(doubleSwipe:)];
    downRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
    [downRecognizer setNumberOfTouchesRequired:2];
    [self.view addGestureRecognizer:downRecognizer];
}

/* themeSetupView buttons */
-(void)buttonPressed:(UIButton *)sender{
    [_themeSetupView removeFromSuperview];
    if (sender.tag == 003){
        [self openApp:@"com.apple.Preferences"];
    }
}

/* 
    Get themes is called when a user swipes down with two fingers. It gathers current installed themes and adds to an array
*/
-(void) getThemes{
    _themeArray = [NSMutableArray array];
    NSArray * directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"var/mobile/Library/FrontPage/" error:nil];
    for(NSString *theme in directoryContents){
        [_themeArray addObject:theme];
    }
}


/* Webview which contains the actual widget*/
-(void) loadWebView{
    _themeView = [[UIWebView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width,self.view.frame.size.height)];
    _themeView.delegate = self;
    _themeView.backgroundColor = [UIColor clearColor];
    _themeView.scrollView.scrollEnabled = NO;
    _themeView.scrollView.bounces = NO;
    
    _themeView.opaque = NO;
    NSString * themeName = [_frontPageSettings objectForKey:@"Selected"];
    if(!themeSelected){
        themeName = @"Welcome";
    }
    NSString *urlStr = [NSString stringWithFormat:@"file:///var/mobile/Library/FrontPage/%@/index.html", themeName];
    NSURL *nsUrl=[NSURL URLWithString:urlStr];
    NSURLRequest *nsRequest=[NSURLRequest requestWithURL:nsUrl];
    [_themeView loadRequest:nsRequest];
    
    [self.view addSubview:_themeView];
    [self.view sendSubviewToBack:_themeView];
}


//Access for webview

//opens app
-(void)openApp:(NSString *)bundle{
     [[objc_getClass("UIApplication") sharedApplication] launchApplicationWithIdentifier:bundle suspended:NO];
}

//user can load plist and return json to loadSettings();
-(void)loadSettings:(NSString *)plist{
    NSString* url = plist;
    NSDictionary *contents = [NSDictionary dictionaryWithContentsOfFile:url];
    NSString *functionCall;
    NSString *function = @"loadSettings";
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:contents
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (! jsonData) {
        //NSLog(@"FrontPage Got an error in loadSettings: %@", error);
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        functionCall = [NSString stringWithFormat:@"%@(%@)", function, jsonString];
        [self callJSFunction:functionCall];
    }
}

//remove app
-(void)uninstallApp:(NSString *)bundle{
    SBApplication * app= [[objc_getClass("SBApplicationController") sharedInstance] applicationWithBundleIdentifier:bundle];
    if(app){
        if(![app isSystemApplication] && ![app isSpringBoard]){
            [[objc_getClass("SBApplicationController") sharedInstance] uninstallApplication:app];
            [self vibrate];
        }
    }
}


//manually update switcher
-(void)updateswitcher{
    [FPISwitcher updateSwitcherWithObserver:self];
}
-(void)openURL: (NSString *)url{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url] options:@{} completionHandler:nil];
}
-(void)openSettings{
    
}

-(void)callJSFunction: (NSString *)function{
    NSString * returnText = [_themeView stringByEvaluatingJavaScriptFromString:function];
    NSLog(@"FrontPage - Return Text for %@ %@", function, returnText);
}
-(void)respring{
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(_relaunchSpringBoardNow)]) {
        [(SpringBoard*)[UIApplication sharedApplication] _relaunchSpringBoardNow];
    } else if (objc_getClass("FBSystemService") && [[objc_getClass("FBSystemService") sharedInstance] respondsToSelector:@selector(exitAndRelaunch:)]) {
        [[objc_getClass("FBSystemService") sharedInstance] exitAndRelaunch:YES];
    }
}
-(void)playmusic{
    [[objc_getClass("SBMediaController") sharedInstance] togglePlayPause];
}
-(void)nexttrack{
    [[objc_getClass("SBMediaController") sharedInstance] changeTrack:1];
}
-(void)prevtrack{
    [[objc_getClass("SBMediaController") sharedInstance] changeTrack:-1];
}
-(void)vibrate{
    AudioServicesPlayAlertSoundWithCompletion(kSystemSoundID_Vibrate, nil);
}
-(void)opencc{
    [[objc_getClass("SpringBoard") sharedApplication] _runControlCenterBringupTest];
}
-(void)opennc{
    [[objc_getClass("SpringBoard") sharedApplication] _runNotificationCenterBringupTest];
}
-(void)updateMemory{
    [FPIMemory loadMemoryWithObserver:self];
}
-(void)enablewifi{
    [FPIStatusBar enableWifi];
}
-(void)disablewifi{
    [FPIStatusBar disableWifi];
}
-(void)refreshWeather{
    [FPIWeather startWeather:self];
}


/* 
 On double swipe create the theme view, make buttons and collection view 
*/

-(void)showMenu{
    [self getThemes];
    _themeSetupView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [_themeSetupView setBackgroundColor:[UIColor clearColor]];
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurEffectView.frame = self.view.bounds;
    blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button addTarget:self
               action:@selector(buttonPressed:)
     forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"Close" forState:UIControlStateNormal];
    button.frame = CGRectMake(0, self.view.frame.size.height - 40, self.view.frame.size.width/2, 40.0);
    button.tag = 002;
    button.backgroundColor = [UIColor blackColor];
    
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeCustom];
    [button2 addTarget:self
                action:@selector(buttonPressed:)
      forControlEvents:UIControlEventTouchUpInside];
    [button2 setTitle:@"Settings" forState:UIControlStateNormal];
    button2.tag = 003;
    button2.frame = CGRectMake(self.view.frame.size.width - (self.view.frame.size.width/2), self.view.frame.size.height - 40, self.view.frame.size.width/2, 40.0);
    button2.backgroundColor = [UIColor blackColor];
    
    [_themeSetupView addSubview:blurEffectView];
    
    UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc] init];
    _collectionView=[[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) collectionViewLayout:layout];
    
    [_collectionView setDataSource:self];
    [_collectionView setDelegate:self];
    
    [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
    [_collectionView registerClass:[UIImageCollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    [_collectionView setBackgroundColor:[UIColor clearColor]];
    
    [_themeSetupView addSubview:_collectionView];
    [_themeSetupView addSubview:button];
    [_themeSetupView addSubview:button2];
    [self.view addSubview:_themeSetupView];
}

- (void)doubleSwipe:(UISwipeGestureRecognizer*)gestureRecognizer{
    [self showMenu];
}

-(void)sleep{
    [[objc_getClass("SBUserAgent") sharedUserAgent]lockAndDimDevice];
}
/* Communication */

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    
    /*
     Calls: (js-call:openApp:BUNDLE)
     window.location = 'js-call:openApp:' + bundle;
     */
    
    NSString *url = [[request URL] absoluteString];
    if ([url hasPrefix:@"frontpage:"]) {
        NSArray *components = [url componentsSeparatedByString:@":"];
        NSString *function = [components objectAtIndex:1];
        
        @try {
            
            if([components count] > 2){
                NSString *func = [NSString stringWithFormat:@"%@:",[components objectAtIndex:1]];
                NSString *param = [NSString stringWithFormat:@"%@",[components objectAtIndex:2]];
                
                if([self respondsToSelector:NSSelectorFromString(func)]){
                    [self performSelector:NSSelectorFromString(func)
                           withObject:param
                           afterDelay:0];
                }
            }else{
                if([self respondsToSelector:NSSelectorFromString(function)]){
                    [self performSelector:NSSelectorFromString(function)
                               withObject:nil
                               afterDelay:0];
                }
                
            }

            
        } @catch (NSException *exception) {
            NSLog(@"FrontPage - ERRERr %@",exception);
        }
        
        return NO;
    }
    return YES;
}


-(void)convertDictToJSON:(NSDictionary *) dict withName:(NSString *) name{
    @try {
        NSData * dictData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
        NSString * jsonObj = [[NSString alloc] initWithData:dictData encoding:NSUTF8StringEncoding];
        NSString * returnText = [_themeView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"setFPIInfo('%@', '%@', '%@')",jsonObj, name, @"parse"]];
        NSLog(@"FrontPage - setFPIInfo() and returned %@", returnText);
        
        //NSLog(@"FixingBullet - object %@", jsonObj);
    } @catch (NSException *exception) {
        NSLog(@"FrontPage - JSON error %@", exception);
    }
    
}



-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

-(void)startWeatherLoop{

    [FPIWeather startWeather:self];
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1200.0 target:self selector:@selector(startWeatherLoop) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)webViewDidFinishLoad:(UIWebView *)webview{
    
    
    @try {
        isInApp = NO;
        
        
        
        @try{
            [FPISystem setupNotificationSystem:self];
        }@catch(NSException *exception){
            NSString* newMessage = [NSString stringWithFormat:@"This is the error: %@", exception];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"System Error"
                                                            message:newMessage
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        
        @try{
            [FPIBattery setupNotificationSystem:self];
        }@catch(NSException *exception){
            NSString* newMessage = [NSString stringWithFormat:@"This is the error: %@", exception];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Battery Error"
                                                            message:newMessage
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        @try{
            [FPIStatusBar setupNotificationSystem:self];
        }@catch(NSException *exception){
            NSString* newMessage = [NSString stringWithFormat:@"This is the error: %@", exception];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Statusbar Error"
                                                            message:newMessage
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        @try{
            [FPISwitcher setupNotificationSystem:self];
        }@catch(NSException *exception){
            NSString* newMessage = [NSString stringWithFormat:@"This is the error: %@", exception];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Switcher Error"
                                                            message:newMessage
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        @try{
            [FPIApps setupNotificationSystem:self];
        }@catch(NSException *exception){
            NSString* newMessage = [NSString stringWithFormat:@"This is the error: %@", exception];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Apps Error"
                                                            message:newMessage
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        @try{
            [FPIApp setupNotificationSystem:self];
        }@catch(NSException *exception){
            NSString* newMessage = [NSString stringWithFormat:@"This is the error: %@", exception];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"App Error"
                                                            message:newMessage
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        @try{
            [FPIMusic setupNotificationSystem:self];
        }@catch(NSException *exception){
            NSString* newMessage = [NSString stringWithFormat:@"This is the error: %@", exception];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Music Error"
                                                            message:newMessage
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        @try{
            [FPINotifications setupNotificationSystem:self];
        }@catch(NSException *exception){
            NSString* newMessage = [NSString stringWithFormat:@"This is the error: %@", exception];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Notifications Error"
                                                            message:newMessage
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        
        @try {
            [FPIFolders loadFoldersWithObserver:self];
        } @catch (NSException *exception) {
            
            NSString* newMessage = [NSString stringWithFormat:@"This is the error: %@", exception];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Weather Error"
                                                            message:newMessage
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        
        @try {
            [FPIAlarm loadAlarmsWithObserver:self];
        } @catch (NSException *exception) {
            
            NSString* newMessage = [NSString stringWithFormat:@"This is the error: %@", exception];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alarm Error"
                                                            message:newMessage
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        
        @try {
            [FPIMemory loadMemoryWithObserver:self];
        } @catch (NSException *exception) {
            
            NSString* newMessage = [NSString stringWithFormat:@"This is the error: %@", exception];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Memory Error"
                                                            message:newMessage
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        
        @try {
            [self startWeatherLoop];
        } @catch (NSException *exception) {
            
            NSString* newMessage = [NSString stringWithFormat:@"This is the error: %@", exception];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Weather Loop Error"
                                                            message:newMessage
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            
        }
        
    
        
        
        
        
    } @catch (NSException *exception) {
        NSLog(@"FrontPage: Error when loading webViewDidFinishLoad %@", exception);
    }
    
    
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.2);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
        NSString * returnText = [_themeView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"FPIloaded()"]];
        NSLog(@"FrontPage: FPILoaded() with return of %@", returnText);
    });
}



/* COllection View */

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [_themeArray count];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    NSString *theme = [[cell viewWithTag:100]text];
        [_frontPageSettings setValue:[NSString stringWithFormat:@"%@",theme] forKey:@"Selected"];
        [_frontPageSettings writeToFile:_plistPath atomically:YES];
    NSString *myURLString = [NSString stringWithFormat: @"file:///var/mobile/Library/FrontPage/%@/index.html", theme];
    NSURL * url = [[NSURL alloc] initWithString:myURLString];
    NSURLRequest * request = [[NSURLRequest alloc] initWithURL:url];
    [_themeView loadRequest:request];
    [_themeSetupView removeFromSuperview];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UIImageCollectionViewCell *cell=[collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.imageView.frame = CGRectMake(0,0,self.view.frame.size.width/3 - 25, self.view.frame.size.height/4);
    NSString *localPath = [NSString stringWithFormat:@"var/mobile/Library/FrontPage/%@/screenshot.jpg", _themeArray[indexPath.row]];

    if([[NSFileManager defaultManager] fileExistsAtPath:localPath]){
        cell.imageView.image = [UIImage imageWithContentsOfFile:localPath];
    }else{
    }
    cell.textView.text = _themeArray[indexPath.row];
    return cell;
}

- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(50, 10, 80, 10); // top, left, bottom, right
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake(self.view.frame.size.width/3 - 20, self.view.frame.size.height/4);
    //return CGSizeMake(120, 200);
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 10.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 10.0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
