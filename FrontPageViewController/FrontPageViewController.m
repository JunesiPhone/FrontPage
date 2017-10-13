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
#import <EventKit/EventKit.h>

#include "MediaRemote.h"
#import <objc/runtime.h>
#import <notify.h>
#import "Weather.h"
#include <dlfcn.h>
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
#import "Headers.h"
#import <AudioToolbox/AudioServices.h>
#import <sys/utsname.h>

#define deviceVersion [[[UIDevice currentDevice] systemVersion] floatValue]

@interface FrontPageViewController ()

@end



@implementation FrontPageViewController

NSString* rotation = @"portrait";
bool deviceLocked = YES;
bool springBoardEnabled = NO;
NSTimer *weatherTimer;
static bool webViewIsLoaded = NO;

static EKEventStore *store;

+ (instancetype)sharedInstance {
    static id _sharedInstance = nil;
    @synchronized([self class]) {
        if (_sharedInstance == nil) {
            _sharedInstance = [[[self class] alloc] init];
        }
    }
    return _sharedInstance;
}


-(bool)checkIfInApp{
    UIApplication* app = [[objc_getClass("SpringBoard") sharedApplication] _accessibilityFrontMostApplication];
    bool isInThere;
    if(app){
        [self setScreenIsInApp:YES];
        isInThere = YES;
    }else{
        [self setScreenIsInApp:NO];
        isInThere = NO;
    }
    return isInThere;
}

void iconLock (CFNotificationCenterRef center,FrontPageViewController * observer,CFStringRef name,const void * object,CFDictionaryRef userInfo) {
    [[FrontPageViewController sharedInstance] setIconLock:YES];
}
void iconUnlock (CFNotificationCenterRef center,FrontPageViewController * observer,CFStringRef name,const void * object,CFDictionaryRef userInfo) {
    [[FrontPageViewController sharedInstance] setIconLock:NO];
}

int statusbarLastCalled = 0;

-(int)returnStatusbarLastCalled{
    return statusbarLastCalled;
}
-(void)setStatusbarLastCalled: (int) seconds{
    statusbarLastCalled = seconds;
}

int switcherLastCalled = 0;

-(int)returnSwitcherLastCalled{
    return switcherLastCalled;
}
-(void)setSwitcherLastCalled: (int) seconds{
    switcherLastCalled = seconds;
}


void respringNotification (CFNotificationCenterRef center,FrontPageViewController * observer,CFStringRef name,const void * object,CFDictionaryRef userInfo) {
    [observer respring];
}
void deviceUnlock (CFNotificationCenterRef center,FrontPageViewController * observer,CFStringRef name,const void * object,CFDictionaryRef userInfo) {
    deviceLocked = NO;
    [observer callJSFunction:@"deviceUnlocked()"];
    
    NSDictionary* systemInfo = [FPISystem systemInfo];
    [observer convertDictToJSON:systemInfo withName:@"system"];
    [observer callJSFunction:@"loadSystem()"];
    
    
}
void openMenu (CFNotificationCenterRef center,FrontPageViewController * observer,CFStringRef name,const void * object,CFDictionaryRef userInfo) {
    [observer showMenu];
    [observer pressHomeButton];
}

-(void)pressHomeButton{
    if(deviceVersion >= 10.0){
        [[objc_getClass("SBUIController") sharedInstance] handleHomeButtonSinglePressUp];
    }else{
        [[objc_getClass("SBUIController") sharedInstance] clickedMenuButton];
    }
}

-(void)setWidth:(NSString *) widthValue{

    [_frontPageThemeSettings setValue:widthValue forKey:@"width"];
    
    _themeView.frame = CGRectMake(_themeView.frame.origin.x, _themeView.frame.origin.y, [widthValue intValue], _themeView.frame.size.height);
    
    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, [widthValue intValue], self.view.frame.size.height);
}

#pragma - mark Apply Settings

-(void)applyThemeSettings{
    NSString *width = [_frontPageThemeSettings valueForKey:@"width"];
    NSString *height = [_frontPageThemeSettings valueForKey:@"height"];
    NSString *x = [_frontPageThemeSettings valueForKey:@"x"];
    NSString *y = [_frontPageThemeSettings valueForKey:@"y"];
    
    
    int sizeofdock = 96;
    int widthoftheme;
    int heightoftheme;
    int xoftheme = 0;
    int yoftheme = 0;
    
    if([rotation isEqualToString:@"landscape"]){
        sizeofdock = 96;
    }else{
        sizeofdock = 0;
    }
    
    if([width isEqualToString:@"auto"]){
        widthoftheme = self.view.frame.size.width;
    }else{
        widthoftheme = [[_frontPageThemeSettings valueForKey:@"width"] intValue];
    }
    
    if([height isEqualToString:@"auto"]){
        heightoftheme = self.view.frame.size.height;
    }else{
        heightoftheme = [[_frontPageThemeSettings valueForKey:@"height"] intValue];
    }
    
    if ([y rangeOfString:@":"].location == NSNotFound) {
        //string does not contain :
        if([y isEqualToString:@"center"]){
            yoftheme = self.view.frame.size.height/2 - (heightoftheme / 2);
        }else{
            yoftheme = [[_frontPageThemeSettings valueForKey:@"x"] intValue];
        }
    } else {
        //string contains :
        NSArray* ycomp = [y componentsSeparatedByString:@":"];
        if([ycomp count] > 0){
            if([ycomp[0] isEqualToString:@"fromtop"]){
                yoftheme = [ycomp[1] intValue];
            } else if([ycomp[0] isEqualToString:@"frombottom"]){
                yoftheme = fabs(([ycomp[1] intValue] - self.view.superview.frame.size.height) - sizeofdock);
            }
        }
    }
    if ([x rangeOfString:@":"].location == NSNotFound) {
        //string does not contain :
        if([x isEqualToString:@"center"]){
            xoftheme = self.view.frame.size.width/2 - (widthoftheme / 2) - (sizeofdock /2);
        }else{
            xoftheme = [[_frontPageThemeSettings valueForKey:@"x"] intValue];
        }
    } else {
        //string contains :
        NSArray* xcomp = [x componentsSeparatedByString:@":"];
        if([xcomp count] > 0){
            if([xcomp[0] isEqualToString:@"fromleft"]){
                xoftheme = [xcomp[1] intValue];
            } else if([xcomp[0] isEqualToString:@"fromright"]){
                xoftheme = fabs([xcomp[1] intValue] - self.view.superview.frame.size.width);
            }
        }
    }
    
    
    self.view.frame = CGRectMake(xoftheme, yoftheme, widthoftheme, heightoftheme);
    _themeView.frame = CGRectMake(0, 0, widthoftheme, heightoftheme);

}

#pragma - mark Theme Settings

-(void)loadThemeSettings: (NSString *) theme{
    NSString *pathForFile = [NSString stringWithFormat: @"/var/mobile/Library/FrontPage/%@/Info.plist", theme];
    if([[NSFileManager defaultManager] fileExistsAtPath:pathForFile]){
        _frontPageThemeSettings = [NSMutableDictionary dictionaryWithContentsOfFile:pathForFile];
        [self applyThemeSettings];
    }
}

- (void)removeWebViewDoubleTapGestureRecognizer:(UIView *)view{
       for (UIGestureRecognizer *recognizer in [view gestureRecognizers]) {
                if ([recognizer isKindOfClass:[UITapGestureRecognizer class]] && [(UITapGestureRecognizer *)recognizer numberOfTapsRequired] == 2) {
                        [view removeGestureRecognizer:recognizer];
                    }
          }
      for (UIView *subview in view.subviews) {
            [self removeWebViewDoubleTapGestureRecognizer:subview];
      }
}



#pragma mark - View Did Load

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setScreenIsOn:YES];
    
    if(!store){
        store = [[EKEventStore alloc] init];
    }
    
    
    FrontPageViewController *observer = self;
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    (__bridge const void *)(observer),
                                    (CFNotificationCallback)iconLock,
                                    CFSTR("com.junesiphone.frontpage.iconLock"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately
                                    );
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    (__bridge const void *)(observer),
                                    (CFNotificationCallback)iconUnlock,
                                    CFSTR("com.junesiphone.frontpage.iconUnlock"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately
                                    );
   
    [FrontPageViewController sharedInstance].mainView = self.view;
    
    
    [self loadSaved];   //Load a plist to see if any themes are currently applied, if not prepare plist.
    [self addGestures]; //Add gestures to current view
    
    _plistPath = @"var/mobile/Documents/FrontPage.plist";
    if([[NSFileManager defaultManager] fileExistsAtPath:_plistPath]){
        _frontPageSettings = [NSMutableDictionary dictionaryWithContentsOfFile:_plistPath];
        if([_frontPageSettings objectForKey:@"Selected"]){
            NSString* themeName = [_frontPageSettings objectForKey:@"Selected"];
            if(![themeName isEqualToString:@"SpringBoard"]){
                [self loadWebView:themeName];
            }
        }
    }
    
    //notification for when webview will show copy/paste
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processit:) name:UIMenuControllerWillShowMenuNotification object:nil];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    //detect orientation
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(orientationChanged:)
     name:UIDeviceOrientationDidChangeNotification
     object:[UIDevice currentDevice]];
    
    
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
                                                  [self setScreenIsOn:YES];
                                                  
                                              }else{
                                                  [self setScreenIsOn:NO];
                                                  dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.1);
                                                  dispatch_after(delay, dispatch_get_main_queue(), ^(void){
                                                      [self callJSFunction:@"deviceLocked()"];
                                                      deviceLocked = YES;
                                                      springBoardEnabled = NO;
                                                  });
                                              }
                                              if (result != NOTIFY_STATUS_OK) {
                                                  NSLog(@"FrontPage - notify_get_state() not returning NOTIFY_STATUS_OK");
                                              }
                                          });
    if (status != NOTIFY_STATUS_OK) {
        NSLog(@"FrontPage - notify_register_dispatch() not returning NOTIFY_STATUS_OK");
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showMenu)
                                                 name:@"showMenu"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateWeatherNow)
                                                 name:@"updateWeather"
                                               object:nil];
    
    
    dispatch_time_t delayIconSave = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.5);
    dispatch_after(delayIconSave, dispatch_get_main_queue(), ^(void){
        if(![[FrontPageViewController sharedInstance] isIconLock]){
            [FPIApps saveAllIconImagesWithObserver:self];
        }
    });
    [self startWeatherLoop];
    //[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(checkWebViewTitle) userInfo:nil repeats:YES];
    
}

#pragma - mark Rotate

//when device is rotated we want to resize according to theme settings
-(void)resizeWebView{
        if(_frontPageThemeSettings){
            [self applyThemeSettings];
        }
}
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}
//detect orientationChange
- (void) orientationChanged:(NSNotification *)note{
    UIDevice * device = note.object;
    if(![self isScreenInApp] && !deviceLocked){
        switch(device.orientation){
            case UIDeviceOrientationPortrait:
                rotation = @"portrait";
                if(webViewIsLoaded){
                        [self callJSFunction:@"viewRotated('portrait')"];
                }
                [self resizeWebView];
                break;
            case UIDeviceOrientationLandscapeLeft:
                if(webViewIsLoaded){
                    [self callJSFunction:@"viewRotated('landscapeleft')"];
                }
                rotation = @"landscape";
                [self resizeWebView];
                break;
            case UIDeviceOrientationLandscapeRight:
                if(webViewIsLoaded){
                    [self callJSFunction:@"viewRotated('landscaperight')"];
                }
                rotation = @"landscape";
                [self resizeWebView];
                break;
            default:
                break;
        };
    }
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
            [self loadThemeSettings:[_frontPageSettings objectForKey:@"Selected"]];
        }
    }else{
        _frontPageSettings = [[NSMutableDictionary alloc] init];
    }
}

/*
 Two Finger Down Gesture shows the themeSetupView where users can select a theme.
 
 */
- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
}

-(void)addGestures{
    
    UISwipeGestureRecognizer *downRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(doubleSwipe:)];
    downRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
    [downRecognizer setNumberOfTouchesRequired:2];
    [self.view addGestureRecognizer:downRecognizer];
    
    
    UISwipeGestureRecognizer *upRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(doubleSwipeup:)];
    upRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
    [upRecognizer setNumberOfTouchesRequired:2];
    [self.view addGestureRecognizer:upRecognizer];
}

/* themeSetupView buttons */
-(void)buttonPressed:(UIButton *)sender{
    [_themeSetupView removeFromSuperview];
    if (sender.tag == 003){
        NSURL* fpPath = [NSURL URLWithString:@"prefs:root=FrontPage"];
        if ([[UIApplication sharedApplication] canOpenURL:fpPath]){
            [[UIApplication sharedApplication] openURL:fpPath];
        }else{
            [self openApp:@"com.apple.Preferences"];
        }
    }
    [self loadThemeSettings:[_frontPageSettings objectForKey:@"Selected"]];
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
    directoryContents = nil;
}


#pragma - mark Calls From WebView
//Access for webview

//opens app
-(void)openApp:(NSString *)bundle{
    [[objc_getClass("UIApplication") sharedApplication] launchApplicationWithIdentifier:bundle suspended:NO];
}

//manually update switcher
-(void)updateswitcher{
    [self injectSwitcherIsNotification:NO];
}

/* On double swipe create the theme view, make buttons and collection view */
-(void)showMenu{
    
    //looking for theme setup view
    if((UIView *)[[UIApplication sharedApplication].keyWindow.rootViewController.view viewWithTag:4870905]){
        [(UIView *)[[UIApplication sharedApplication].keyWindow.rootViewController.view viewWithTag:4870905] removeFromSuperview];
    }
    
    [self getThemes];
    
    if(_themeSetupView){
        [_themeSetupView removeFromSuperview];
    }
    
    self.view.frame = CGRectMake(0, 0, self.view.superview.frame.size.width, self.view.superview.frame.size.height);
    _themeView.frame = CGRectMake(0, 0, self.view.superview.frame.size.width, self.view.superview.frame.size.height);
    
    _themeSetupView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    
    [_themeSetupView setBackgroundColor:[UIColor clearColor]];
    _themeSetupView.tag = 4870905;
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
    
    //NSLog(@"FrontPage %@", _collectionView);
    
    [_collectionView setDataSource:self];
    [_collectionView setDelegate:self];
    
    [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
    [_collectionView registerClass:[UIImageCollectionViewCellNew class] forCellWithReuseIdentifier:@"cell"];
    [_collectionView setBackgroundColor:[UIColor clearColor]];
    
    [_themeSetupView addSubview:_collectionView];
    [_themeSetupView addSubview:button];
    [_themeSetupView addSubview:button2];
    
    //need top view to display over icons, iOS8 doesn't work though:(
    UIView* topView = [UIApplication sharedApplication].keyWindow.rootViewController.view;
    if(topView == nil){ //iOS8 doesn't respond to keyWindow.rootViewController
        topView = [UIApplication sharedApplication].keyWindow;
        [topView addSubview:_themeSetupView];
        [topView bringSubviewToFront:_themeSetupView];
    }else{
        [topView addSubview:_themeSetupView];
        [topView bringSubviewToFront:_themeSetupView];
    }
}

- (void)doubleSwipe:(UISwipeGestureRecognizer*)gestureRecognizer{
    [self showMenu];
}

-(void)doubleSwipeup:(UISwipeGestureRecognizer *)gestureRecognizer{
    if(objc_getClass("IWWidgetsPopup")){
        IWWidgetsPopup *iWidgetView = [[objc_getClass("IWWidgetsPopup") alloc]init];
        [iWidgetView show];
    }
}

-(void)sleep{
    [[objc_getClass("SBUserAgent") sharedUserAgent]lockAndDimDevice];
}

-(void)updateWeatherNow{
    [FPIWeather startWeather:self];
}
-(void)startWeatherLoop{
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 1.0);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
        if(![weatherTimer isValid] && !springBoardEnabled) {
            weatherTimer = [NSTimer scheduledTimerWithTimeInterval:1195.0 target:self selector:@selector(startWeatherLoop) userInfo:nil repeats:NO];
            [[NSRunLoop mainRunLoop] addTimer:weatherTimer forMode:NSRunLoopCommonModes];
            [self updateWeatherNow];
        }
    });
}

#pragma mark - Check Pending
-(void)checkPendingNotifications{
    if(webViewIsLoaded && [self isScreenOn] && ![self checkIfInApp]){
        if([self isSystemPending]){
            [self setSystemPending:NO];
            [self injectSystemIsNotification:YES];
        }
        if([self isBatteryPending]){
            [self setBatteryPending:NO];
            [self injectBatteryIsNotification:YES];
        }
        if([self isStatusBarPending]){
            [self setStatusBarPending:NO];
            [self injectStatusBarIsNotification:YES];
        }
        if([self isSwitcherPending]){
            [self setSwitcherPending:NO];
            [self injectSwitcherIsNotification:YES];
        }
        if([self isAppsPending]){
            [self setAppsPending:NO];
            [self injectAppsIsNotification:YES];
        }
        if([self isAppPending]){
            [self setAppPending:NO];
            [self injectSingleApp];
        }
        if([self isMusicPending]){
            [self setMusicPending:NO];
            [self injectMusicIsNotification:YES];
        }
        if([self isNotificationsPending]){
            [self setNotificationsPending:NO];
            [self injectNotificationsIsNotification:YES];
        }
        if([self isAlarmsPending]){
            [self setAlarmsPending:NO];
            [self injectAlarmIsNotification:YES];
        }

    }
}

#pragma mark - Notification Callbacks

void systemCalled(CFNotificationCenterRef center,FrontPageViewController * observer,CFStringRef name,const void * object,CFDictionaryRef userInfo){
    [observer injectSystemIsNotification:YES];
    [observer checkPendingNotifications];
}
void batteryCalled(CFNotificationCenterRef center,FrontPageViewController * observer,CFStringRef name,const void * object,CFDictionaryRef userInfo){
    [observer injectBatteryIsNotification:YES];
    [observer checkPendingNotifications];
}
void statusbarCalled(CFNotificationCenterRef center,FrontPageViewController * observer,CFStringRef name,const void * object,CFDictionaryRef userInfo){
    [observer injectStatusBarIsNotification:YES];
    [observer checkPendingNotifications];
}
void switcherCalled(CFNotificationCenterRef center,FrontPageViewController * observer,CFStringRef name,const void * object,CFDictionaryRef userInfo){
    [observer injectSwitcherIsNotification:YES];
    [observer checkPendingNotifications];
}
void newAppUpdated(CFNotificationCenterRef center,FrontPageViewController * observer,CFStringRef name,const void * object,CFDictionaryRef userInfo){
    [observer injectSingleApp];
}
void updatingApps(CFNotificationCenterRef center,FrontPageViewController * observer,CFStringRef name,const void * object,CFDictionaryRef userInfo){
    [FPIApps saveAllIconImagesWithObserver:observer];
    [observer injectAppsIsNotification:YES];
    [observer checkPendingNotifications];
}
void updatingMusic(CFNotificationCenterRef center,FrontPageViewController * observer,CFStringRef name,const void * object,CFDictionaryRef userInfo){
    [observer injectMusicIsNotification:YES];
    [observer checkPendingNotifications];
}
void updatingNotifications(CFNotificationCenterRef center,FrontPageViewController * observer,CFStringRef name,const void * object,CFDictionaryRef userInfo){
    [observer injectNotificationsIsNotification:YES];
    [observer checkPendingNotifications];
}
void updatingAlarm(CFNotificationCenterRef center,FrontPageViewController * observer,CFStringRef name,const void * object,CFDictionaryRef userInfo){
    [observer injectAlarmIsNotification:YES];
    [observer checkPendingNotifications];
}

#pragma mark - Notifications

-(void)unregisterNotifications{
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), CFSTR("com.junesiphone.frontpage.updatingsystem"), NULL);
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), CFSTR("com.junesiphone.frontpage.updatingbattery"), NULL);
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), CFSTR("com.junesiphone.frontpage.updatingstatusbar"), NULL);
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), CFSTR("com.junesiphone.frontpage.updatingswitcher"), NULL);
     CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), CFSTR("com.junesiphone.frontpage.app"), NULL);
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), CFSTR("com.junesiphone.frontpage.updatingapps"), NULL);
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), CFSTR("com.junesiphone.frontpage.updatingnewappinstalled"), NULL);
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), CFSTR("com.junesiphone.frontpage.updatingmusic"), NULL);
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), CFSTR("com.junesiphone.frontpage.updatingnotifications"), NULL);
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), CFSTR("com.junesiphone.frontpage.updatingalarm"), NULL);
}

#pragma mark - Injections

-(void)loadReminders{
    NSPredicate *predicate2 = [store predicateForRemindersInCalendars:nil];
    [store fetchRemindersMatchingPredicate:predicate2 completion:^(NSArray *reminders) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSMutableArray *eventsDictArray = [[NSMutableArray alloc] init];
            NSMutableDictionary *eventsDict;
            for (EKReminder *object in reminders) {
                if(!object.completionDate && object.title){
                    eventsDict = [[NSMutableDictionary alloc]init];
                    [eventsDict setValue:object.title forKey:@"title"];
                    //[eventsDict setValue:object.dueDate forKey:@"date"];
                    [eventsDictArray addObject:eventsDict];
                }
            }
            NSMutableDictionary *info =[[NSMutableDictionary alloc] init];
            [info setValue:eventsDictArray forKey:@"all"];
            [self convertDictToJSON:info withName:@"reminders"];
            [self callJSFunction:@"loadReminders()"];
        });
    }];
}


-(void)injectSystemIsNotification: (bool)notification{
    if(notification){
        if(![self isScreenOn] || [self checkIfInApp]){
            [self setSystemPending:YES];
            return;
        }
    }
    [self loadReminders];
    NSDictionary* systemInfo = [FPISystem systemInfo];
    [self convertDictToJSON:systemInfo withName:@"system"];
    [self callJSFunction:@"loadSystem()"];
}

-(void)injectBatteryIsNotification: (bool)notification{
    if(notification){
        if(![self isScreenOn] || [self checkIfInApp]){
            [self setBatteryPending:YES];
            return;
        }
    }
    NSDictionary* batteryInfo = [FPIBattery batteryInfo];
    [self convertDictToJSON:batteryInfo withName:@"battery"];
    [self callJSFunction:@"loadBattery()"];
}

-(void)injectStatusBarIsNotification: (bool)notification{
    if(notification){
        if(![self isScreenOn] || [self checkIfInApp]){
            [self setStatusBarPending:YES];
            return;
        }
    }
    NSDictionary* statusBarInfo = [FPIStatusBar statusBarInfo];
    [self convertDictToJSON:statusBarInfo withName:@"statusbar"];
    [self callJSFunction:@"loadStatusBar()"];
}

-(void)injectSwitcherIsNotification: (bool)notification{
    if(notification){
        if(![self isScreenOn] || [self checkIfInApp]){
            [self setSwitcherPending:YES];
            return;
        }
    }
    NSDictionary* switcherInfo = [FPISwitcher switcherInfo];
    [self convertDictToJSON:switcherInfo withName:@"switcher"];
    [self callJSFunction:@"loadSwitcher()"];
}

-(void)injectAppsIsNotification: (bool)notification{
    if(notification){
        if(![self isScreenOn] || [self checkIfInApp]){
            [self setAppsPending:YES];
            return;
        }
    }
    NSArray* combinedInfo = [FPIApps appsInfo];
    if([combinedInfo count] == 2){
        NSDictionary* appsInfo = combinedInfo[0];
        NSDictionary* bundleInfo = combinedInfo[1];
        [self convertDictToJSON:appsInfo withName:@"apps"];
        [self convertDictToJSON:bundleInfo withName:@"bundle"];
        [self callJSFunction:@"loadApps()"];
    }
}

-(void)injectSingleApp{
    if(![self isScreenOn] || [self checkIfInApp]){
        [self setAppPending:YES];
        return;
    }
    NSString* appInfo = [FPIApp appInfo];
    NSString* single = [FPIApp singleApp];
    if(appInfo != nil){
        [self callJSFunction:appInfo];
        [self callJSFunction:single];
    }
}
-(void)injectMusicIsNotification:(bool)notification{
    if(notification){
        if(![self isScreenOn] || [self checkIfInApp]){
            [self setMusicPending:YES];
            return;
        }
    }
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.5);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
        NSDictionary* musicInfo = [FPIMusic musicInfo];
        [self convertDictToJSON:musicInfo withName:@"music"];
        [self callJSFunction:@"loadMusic()"];
    });
}
-(void)injectNotificationsIsNotification:(bool)notification{
    if(notification){
        if(![self isScreenOn] || [self checkIfInApp]){
            [self setNotificationsPending:YES];
            return;
        }
    }
    NSDictionary* notificationInfo = [FPINotifications notificationInfo];
    [self convertDictToJSON:notificationInfo withName:@"notifications"];
    [self callJSFunction:@"loadNotifications()"];
}

-(void)injectFoldersIsNotification:(bool)notification{
    NSDictionary* folderInfo = [FPIFolders injectFolders];
    [self convertDictToJSON:folderInfo withName:@"folderplist"];
    [self callJSFunction:@"loadFolders()"];
}

-(void)injectAlarmIsNotification:(bool)notification{
    if(notification){
        if(![self isScreenOn] || [self checkIfInApp]){
            [self setAlarmsPending:YES];
            return;
        }
    }
    NSDictionary* alarmInfo = [FPIAlarm alarmInfo];
    [self convertDictToJSON:alarmInfo withName:@"alarm"];
    [self callJSFunction:@"loadAlarms()"];
}

-(void)injectMemoryIsNotification:(bool)notification{
    NSDictionary* memoryInfo = [FPIMemory memoryInfo];
    [self convertDictToJSON:memoryInfo withName:@"memory"];
    [self callJSFunction:@"loadMemory()"];
}

#pragma mark - Start All Info

-(void)startEverything{

    
    bool system = [[_frontPageThemeSettings objectForKey:@"usessysteminfo"]boolValue];
    bool battery = [[_frontPageThemeSettings objectForKey:@"usesbatteryinfo"]boolValue];
    bool statusbar = [[_frontPageThemeSettings objectForKey:@"usesstatusbarinfo"]boolValue];
    bool switcher = [[_frontPageThemeSettings objectForKey:@"usesswitcherinfo"]boolValue];
    bool apps = [[_frontPageThemeSettings objectForKey:@"usesappsinfo"]boolValue];
    bool notifications = [[_frontPageThemeSettings objectForKey:@"usesnotificationinfo"] boolValue];
    bool folders = [[_frontPageThemeSettings objectForKey:@"usesfolderinfo"]boolValue];
    bool music = [[_frontPageThemeSettings objectForKey:@"usesmusicinfo"]boolValue];
    bool alarm = [[_frontPageThemeSettings objectForKey:@"usesalarminfo"]boolValue];
    bool weather = [[_frontPageThemeSettings objectForKey:@"usesweatherinfo"]boolValue];
    
    
    //if nil is returned it will be false so works without issues.
    
    //NSLog(@"FrontPage Notifications: %@", _frontPageThemeSettings);
    
    if(system){
        [self injectSystemIsNotification:NO];
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),(__bridge const void *)(self),(CFNotificationCallback)systemCalled,CFSTR("com.junesiphone.frontpage.updatingsystem"),NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
    }
    if(battery){
        [self injectBatteryIsNotification:NO];
         CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),(__bridge const void *)(self),(CFNotificationCallback)batteryCalled,CFSTR("com.junesiphone.frontpage.updatingbattery"),NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
    }
    if(statusbar){
        [self injectStatusBarIsNotification:NO];
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),(__bridge const void *)(self),(CFNotificationCallback)statusbarCalled, CFSTR("com.junesiphone.frontpage.updatingstatusbar"), NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
    }
    if(switcher){
        [self injectSwitcherIsNotification:NO];
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self),(CFNotificationCallback)switcherCalled,CFSTR("com.junesiphone.frontpage.updatingswitcher"),NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
    }
    if(apps){
        [self injectAppsIsNotification:NO];
        [self injectSingleApp]; // call after apps
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),(__bridge const void *)(self),(CFNotificationCallback)newAppUpdated,CFSTR("com.junesiphone.frontpage.app"),NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
        
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),(__bridge const void *)(self),(CFNotificationCallback)updatingApps,CFSTR("com.junesiphone.frontpage.updatingapps"),NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
        
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),(__bridge const void *)(self),(CFNotificationCallback)updatingApps,CFSTR("com.junesiphone.frontpage.newappinstalled"),NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
    }
    if(notifications){
        [self injectNotificationsIsNotification:NO];
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),(__bridge const void *)(self),(CFNotificationCallback)updatingNotifications,CFSTR("com.junesiphone.frontpage.updatingnotifications"),NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
    }
    if(folders){
        [self injectFoldersIsNotification:NO];
    }
    if(music){
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),(__bridge const void *)(self),(CFNotificationCallback)updatingMusic,CFSTR("com.junesiphone.frontpage.updatingmusic"),NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
    }
    if(alarm){
        [self injectAlarmIsNotification:NO];
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),(__bridge const void *)(self),(CFNotificationCallback)updatingAlarm,CFSTR("com.junesiphone.frontpage.updatingalarm"),NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
    }
    [self callJSFunction:@"FPIloaded()"];
    
    if(weather){
        [self updateWeatherNow];
    }
    
    [self checkPendingNotifications];
    [self loadReminders];
}

#pragma mark - CollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [_themeArray count];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    NSString *theme = [[cell viewWithTag:100]text];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:_plistPath]){
        _frontPageSettings = [NSMutableDictionary dictionaryWithContentsOfFile:_plistPath];
        [_frontPageSettings setValue:[NSString stringWithFormat:@"%@",theme] forKey:@"Selected"];
        [_frontPageSettings writeToFile:_plistPath atomically:YES];
    }else{
        _frontPageSettings = [[NSMutableDictionary alloc] init];
        [_frontPageSettings setValue:[NSString stringWithFormat:@"%@",theme] forKey:@"Selected"];
        [_frontPageSettings writeToFile:_plistPath atomically:YES];
    }
    
    [self loadSaved];
    
    if([theme isEqualToString:@"SpringBoard"]){
        
        if(_themeView){
            [_themeView removeFromSuperview];
            webViewIsLoaded = NO;
        }else{
            [_themeView removeFromSuperview];
        }
        
        [_themeSetupView removeFromSuperview];
        
        springBoardEnabled = YES;
        webViewIsLoaded = NO;
        
        
        CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), CFSTR("com.junesiphone.frontpage.iconLock"), NULL);
        CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), CFSTR("com.junesiphone.frontpage.iconUnlock"), NULL);
        CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), CFSTR("com.junesiphone.frontpage.openmenu"), NULL);
        CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), CFSTR("com.junesiphone.frontpage.respring"), NULL);
        CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), CFSTR("com.junesiphone.frontpage.deviceunlock"), NULL);

        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.junesiphone.frontpage.disableFrontPage"), NULL, NULL, true);

        
    }else{
        NSString *myURLString = [NSString stringWithFormat: @"file:///var/mobile/Library/FrontPage/%@/index.html", theme];
        NSURL * url = [[NSURL alloc] initWithString:myURLString];
        NSURLRequest * request = [[NSURLRequest alloc] initWithURL:url];
        
        if(_themeView){
            [_themeView loadRequest:request];

        }else{
            [self loadWebView:theme];
        }
        
        self.view.frame = CGRectMake(0, 0, self.view.superview.frame.size.width, self.view.superview.frame.size.height);
        _themeView.frame = CGRectMake(0, 0, self.view.superview.frame.size.width, self.view.superview.frame.size.height);
        [self loadThemeSettings:theme];
        [_themeSetupView removeFromSuperview];
    }
    //[[objc_getClass("SBUserAgent") sharedUserAgent]lockAndDimDevice];
    [self unregisterNotifications]; //hopefully unregistering notifications that aren't registered isn't an issue.
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UIImageCollectionViewCellNew *cell=[collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    //cell.imageView.frame = CGRectMake(0,0,self.view.frame.size.width/3 - 25, self.view.frame.size.height/4);
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ){
       cell.imageView.frame = CGRectMake(0,0,320/2,569/2);
       cell.textView.frame = CGRectMake(2, cell.imageView.frame.size.height - 24, cell.imageView.frame.size.width - 35, 15);

    }else{
        cell.imageView.frame = CGRectMake(0,0,self.view.frame.size.width/3 - 25, self.view.frame.size.height/4);
    }
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
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ){
        return CGSizeMake(320/2, 569/2);
    }else{
        return CGSizeMake(self.view.frame.size.width/3 - 20, self.view.frame.size.height/4);
    }
    
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 10.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 10.0;
}

#pragma mark - WKWebView

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURLRequest *request = navigationAction.request;
    NSString *url = [[request URL]absoluteString];
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
            NSLog(@"FrontPage - Error in WKWebView Decide Policy %@",exception);
        }
        
        decisionHandler(WKNavigationActionPolicyCancel);
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"FrontPage Message"
                                          message:message
                                          preferredStyle:UIAlertControllerStyleAlert];
    
        [alertController addAction:[UIAlertAction actionWithTitle:@"Got it!"
                                                            style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction *action) {
                                                              completionHandler();
                                                          }]];
    
    if ([UIApplication sharedApplication].keyWindow.rootViewController.isViewLoaded && [UIApplication sharedApplication].keyWindow.rootViewController.view.window) {
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
    } else {
        completionHandler();
    }
}

-(void)loadWebView:(NSString *)themeName{
    
    if([themeName isEqualToString:@"SpringBoard"]){
        return;
    }
    [[FrontPageViewController sharedInstance] setIsThemeSpringBoard:NO];
    NSString *urlStr = [NSString stringWithFormat:@"file:///var/mobile/Library/FrontPage/%@/index.html", themeName];
    NSURL *nsUrl=[NSURL URLWithString:urlStr];
    if ([WKWebView class]) {
        WKWebViewConfiguration *theConfiguration = [[WKWebViewConfiguration alloc] init];
        WKUserContentController *controller = [[WKUserContentController alloc] init];
        [controller addScriptMessageHandler:self name:@"observe"];
        
        WKPreferences *preferences = [[WKPreferences alloc] init];
        [preferences setJavaScriptEnabled: YES];
        
        if(deviceVersion >= 9.0){
            [preferences _setAllowFileAccessFromFileURLs:YES];
        }
        //figure out iOS8
       
        [theConfiguration setPreferences:preferences];
        
        theConfiguration.userContentController = controller;
        _themeView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width,self.view.frame.size.height) configuration:theConfiguration];
        _themeView.navigationDelegate = self;
        _themeView.opaque = false;
        _themeView.UIDelegate = self;
        _themeView.backgroundColor = [UIColor clearColor];
        _themeView.scrollView.backgroundColor = [UIColor clearColor];
        _themeView.scrollView.scrollEnabled = NO;
        _themeView.scrollView.bounces = NO;
        NSURLRequest *nsrequest=[NSURLRequest requestWithURL:nsUrl];
        //[_themeView loadFileURL:nsUrl allowingReadAccessToURL:nsUrl];
        [_themeView loadRequest:nsrequest];
        [self.view addSubview:_themeView];
    } else {
        //show alert
        
    }
    [self removeWebViewDoubleTapGestureRecognizer:_themeView];
}
-(void)checkWebViewTitle{
    NSString* title = [NSString stringWithFormat:@"%@", _themeView.URL];
    /*
     NSString* titlePiece = @"file";
    if([title isEqualToString:@"(null)"]){
        title = @"file";
    }else{
        NSArray *titleArray = [title componentsSeparatedByString:@":"];
        if([titleArray count] > 0){
            titlePiece = titleArray[0];
        }
    }
     */
    //if ([title isEqualToString:@"about:blank"] || ![titlePiece isEqualToString:@"file"]) {
    if ([title isEqualToString:@"about:blank"]) {
        [self reloadWebViewCompletely];
    }
}
-(void)reloadWebViewCompletely{
    [self unregisterNotifications];
    [_themeView reload];
    [self startEverything];
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView{
    /*
     UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"FrontPage Error"
                                 message:@"WebView did terminate process."
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    //Add Buttons
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:@"Reload"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    [self reloadWebViewCompletely];

                                }];
    
    UIAlertAction* noButton = [UIAlertAction
                               actionWithTitle:@"Cancel"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   //Handle no, thanks button
                               }];
    
    //Add your buttons to alert controller
    
    [alert addAction:yesButton];
    [alert addAction:noButton];
    
    [self presentViewController:alert animated:YES completion:nil];
     */
    [self reloadWebViewCompletely];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    [self resizeWebView];
    [self startEverything];
    [self callJSFunction:@"deviceUnlocked()"];
    webViewIsLoaded = YES;
}


-(void)convertDictToJSON:(NSDictionary *) dict withName:(NSString *) name{
    NSData * dictData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    NSString * jsonObj = [[NSString alloc] initWithData:dictData encoding:NSUTF8StringEncoding];
    NSString* function = [NSString stringWithFormat:@"setFPIInfo('%@', '%@', '%@')",jsonObj, name, @"parse"];
    [self callJSFunction:function];
    dictData = nil;
    jsonObj = nil;
}

#pragma mark - Evaluate Script

-(NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)script{
    //NSLog(@"FrontPage Calling Script %@", script);
    [_themeView evaluateJavaScript:script completionHandler:^(id object, NSError *error) { }];
    return @"Done";
}
//-(NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)script{
//    __block NSString *resultString = nil;
//    __block BOOL finished = NO;
//    [_themeView evaluateJavaScript:script completionHandler:^(id result, NSError *error) {
//        if (error == nil) {
//            if (result != nil) {
//                resultString = [NSString stringWithFormat:@"%@", result];
//            }
//        }else{
//            NSLog(@"FrontPage Error with script: %@, %@", script, error.localizedDescription);
//        }
//        finished = YES;
//    }];
//    
//    while (!finished){
//        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
//    }
//    return resultString;
//}

-(void)callJSFunction: (NSString *)function{
//    if([function isEqualToString:@"loadBattery()"]){
//        function = [NSString stringWithFormat:@"try{loadBattery()}catch(err){document.body.innerHTML = err;document.body.style.opacity = 1;}"];
//    }
    [self stringByEvaluatingJavaScriptFromString:function];
}

#pragma mark - Calls From Webview

-(void)openURL: (NSString *)url{
    NSString* address = [NSString stringWithFormat:@"http://%@",url];
    if([[UIApplication sharedApplication] respondsToSelector:@selector(openURL:options:completionHandler:)]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:address] options:@{} completionHandler:nil];
    }else{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:address]];
    }
}
-(void)openswitcher{
    if ([[objc_getClass("SBUIController")sharedInstance] respondsToSelector:@selector(_toggleSwitcher)]) {
        [[objc_getClass("SBUIController") sharedInstance] _toggleSwitcher];
    } else if (objc_getClass("SBMainSwitcherViewController") && [[objc_getClass("SBMainSwitcherViewController") sharedInstance] respondsToSelector:@selector(toggleSwitcherNoninteractively)]) {
        [[objc_getClass("SBMainSwitcherViewController") sharedInstance] toggleSwitcherNoninteractively];
    }
}
//siri <= iOS9 + 10
-(void)opensiri{
    if ([[objc_getClass("SBAssistantController") sharedInstance] respondsToSelector:@selector(_activateSiriForPPT)]) {
        [[objc_getClass("SBAssistantController") sharedInstance] _activateSiriForPPT];
    } else if([[objc_getClass("SBUIPluginManager") sharedInstance] respondsToSelector:@selector(handleActivationEvent:eventSource:withContext:)]) {
        [[objc_getClass("SBUIPluginManager") sharedInstance] handleActivationEvent:1 eventSource:1 withContext:nil];
    }
}

-(void)opensearch{
    [[objc_getClass("SBSearchGesture") sharedInstance] revealAnimated:YES];
}



-(void)openSettings{
    
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
    [self injectMemoryIsNotification:NO];
    //[FPIMemory manualUpdate:self];
}
-(void)enablewifi{
    [FPIStatusBar enableWifi];
}
-(void)disablewifi{
    [FPIStatusBar disableWifi];
}
-(void)enablebluetooth{
    [FPIStatusBar enableBluetooth];
}
-(void)disablebluetooth{
    [FPIStatusBar disableBluetooth];
}
-(void)refreshWeather{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateWeather" object:self];
}
// open appdrawer
-(void)openappdrawer{
    if([[objc_getClass("SBUIController") sharedInstanceIfExists] respondsToSelector:@selector(openAppDrawer)]){
        [[objc_getClass("SBUIController") sharedInstanceIfExists] openAppDrawer];
    }
}

-(void)hidespringboardicons{
    SBIconController* shared = [objc_getClass("SBIconController") sharedInstance];
    for (int i = 0; i <= 4; i++){
        if([shared rootIconListAtIndex:i] != nil){
            UIView *iconViewList = [shared rootIconListAtIndex:i];
            iconViewList.alpha = 0;
        }
    }
}

-(void)showspringboardicons{
    SBIconController* shared = [objc_getClass("SBIconController") sharedInstance];
    for (int i = 0; i <= 4; i++){
        if([shared rootIconListAtIndex:i] != nil){
            UIView *iconViewList = [shared rootIconListAtIndex:i];
            iconViewList.alpha = 1;
        }
    }
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
            if([[objc_getClass("SBApplicationController") sharedInstance] respondsToSelector:@selector(uninstallApplication:)]) {
                [[objc_getClass("SBApplicationController") sharedInstance] uninstallApplication:app];
                [self vibrate];
            }
        }
    }
}

-(void)isInTerminal{
    [self setIsInTerminalCheck:YES];
}
-(void)isntInTerminal{
    [self setIsInTerminalCheck:NO];
}

/*
 Double tap on webview gives you copy/paste menu. We don't want this.
 We do want this in the terminal view of our webview.
 Here we find out if in terminal and hide paste menu accordingly.
 */

//hide the paste buttons on webview, except when in terminal
-(void)processit:(id)sender {
    if(![self isInTerminalCheck]){
        UIMenuController *menu = [UIMenuController sharedMenuController];
        [menu setMenuVisible:NO];
        [menu performSelector:@selector(setMenuVisible:) withObject:[NSNumber numberWithBool:NO] afterDelay:0];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    NSLog(@"FrontPage - did receive memory warning");
}

@end
