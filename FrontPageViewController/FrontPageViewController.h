//
//  FrontPageViewController.h
//  FrontPageViewController
//
//  Created by Edward Winget on 5/21/17.
//  Copyright © 2017 junesiphone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <EventKit/EventKit.h>
#import <CoreLocation/CoreLocation.h>
#import <WebKit/WebKit.h>
//#import "FPVC+WKWebview.h"
//#import "FPVC+Pending.h"

@interface FrontPageViewController : UIViewController <UIWebViewDelegate, UIGestureRecognizerDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout, UIAlertViewDelegate, CLLocationManagerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate,WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate>{
    WKWebView *_themeView;
    UIView *_themeSetupView;
    UIView *_mainView;
    UICollectionView *_collectionView;
    NSMutableArray *_themeArray;
    NSMutableDictionary *_frontPageSettings;
    NSMutableDictionary *_frontPageThemeSettings;
    NSString *_plistPath;
    int notifyToken;
    BOOL themeSelected;
    BOOL webViewFullyLoaded;


}

@property(strong,nonatomic) WKWebView *WKthemeView;
@property(strong,nonatomic) UIView *mainView;
@property (nonatomic, getter=isDockHiding) BOOL hideDock;
@property (nonatomic, getter=isDotsHiding) BOOL hideDots;
@property (nonatomic, getter=isIconsHiding) BOOL hideIcons;
@property (nonatomic, getter=isIconLock) BOOL iconLock;
@property (nonatomic, getter=isThemeSpringBoard) BOOL isThemeSpringBoard;
@property (nonatomic, getter=isInTerminalCheck) BOOL isInTerminalCheck;
@property (nonatomic, getter=isSystemPending) BOOL systemPending;
@property (nonatomic, getter=isBatteryPending) BOOL batteryPending;
@property (nonatomic, getter=isStatusBarPending) BOOL statusBarPending;
@property (nonatomic, getter=isSwitcherPending) BOOL switcherPending;
@property (nonatomic, getter=isAppPending) BOOL appPending;
@property (nonatomic, getter=isAppsPending) BOOL appsPending;
@property (nonatomic, getter=isMusicPending) BOOL musicPending;
@property (nonatomic, getter=isWeatherPending) BOOL weatherPending;
@property (nonatomic, getter=isNotificationsPending) BOOL notificationsPending;
@property (nonatomic, getter=isFoldersPending) BOOL foldersPending;
@property (nonatomic, getter=isAlarmsPending) BOOL alarmsPending;
@property (nonatomic, getter=isMemoryPending) BOOL memoryPending;
@property (nonatomic, getter=isScreenOn) BOOL screenIsOn;
@property (nonatomic, getter=isScreenInApp) BOOL screenIsInApp;


+ (instancetype)sharedInstance;
-(void)checkPendingNotifications;
-(bool)checkIfInApp;
-(void)setStatusbarLastCalled:(int)second;
-(int)returnStatusbarLastCalled;
-(void)setSwitcherLastCalled:(int)second;
-(int)returnSwitcherLastCalled;
-(void)startEverything;
-(void)convertDictToJSON:(NSDictionary *) dict withName:(NSString *) name;
-(void)callJSFunction: (NSString *)function;
@end



