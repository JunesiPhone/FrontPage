//
//  FPIStatusBar.m
//  FrontPageViewController
//
//  Created by Edward Winget on 6/4/17.
//  Copyright © 2017 junesiphone. All rights reserved.
//

#import "FPIStatusBar.h"
#import <objc/runtime.h>


@interface FPIStatusBar ()

@end

/*Signal*/
@interface SBTelephonyManager : NSObject
+ (id)sharedTelephonyManager;
- (int)signalStrengthBars;
- (int)signalStrength;
- (id)operatorName;
@end

/* Wifi*/
@interface SBWiFiManager : NSObject
+(id)sharedInstance;
- (int)signalStrengthRSSI;
- (int)signalStrengthBars;
- (id)currentNetworkName;
- (void)setWiFiEnabled:(BOOL)arg1;
@end


@implementation FPIStatusBar

// --WiFi
// 0 = currentNetworkName, 1 = signalStrengthRSSI, 2 = signalStrengthBars
+(id)getWifiInfo:(int) info{
    @try {
        SBWiFiManager *WM = [objc_getClass("SBWiFiManager") sharedInstance];
        switch (info) {
            case 0:
                return [WM currentNetworkName];
                break;
            case 1:
                return [NSNumber numberWithInt:[WM signalStrengthRSSI]];
                break;
            case 2:
                return [NSNumber numberWithInt:[WM signalStrengthBars]];
                break;
        }
        return 0;
    } @catch (NSException *exception) {
        //write to log
        return 0;
    }
    
    
}

+(void)enableWifi{
    [[objc_getClass("SBWiFiManager") sharedInstance] setWiFiEnabled:YES];
}
+(void)disableWifi{
    [[objc_getClass("SBWiFiManager") sharedInstance] setWiFiEnabled:NO];
}
// --Signal
// 0 = operatorName, 1 = signalStrength, 2 = signalStrengthBars
+(id)getSignalInfo:(int) info{
    @try {
        SBTelephonyManager *TM = [objc_getClass("SBTelephonyManager") sharedTelephonyManager];
        switch (info) {
            case 0:
                return [TM operatorName];
                break;
            case 1:
                return [NSNumber numberWithInt:[TM signalStrength]];
                break;
            case 2:
                return [NSNumber numberWithInt:[TM signalStrengthBars]];
                break;
        }
        return 0;
    } @catch (NSException *exception) {
        //write to log
        return 0;
    }
}


+(void)updateStatusBarWithObserver:(FrontPageViewController *)observer{
    
    NSDate *timeMethod = [NSDate date];
    NSMutableDictionary *statusBarInfo =[[NSMutableDictionary alloc] init];
    [statusBarInfo setValue:[self getWifiInfo:0] forKey:@"wifiName"];
    [statusBarInfo setValue:[self getWifiInfo:1] forKey:@"wifiRSSI"];
    [statusBarInfo setValue:[self getWifiInfo:2] forKey:@"wifiBars"];
    [statusBarInfo setValue:[self getSignalInfo:0] forKey:@"signalName"];
    [statusBarInfo setValue:[self getSignalInfo:1] forKey:@"signalStrength"];
    [statusBarInfo setValue:[self getSignalInfo:2] forKey:@"signalBars"];
    [observer convertDictToJSON:statusBarInfo withName:@"statusbar"];
    statusBarInfo = nil;
    
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 1);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
        [observer callJSFunction:@"loadStatusBar()"];
    });
    
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:timeMethod];
    NSLog(@"FrontPage - StatusBar executionTime = %f", executionTime);
    
}

void updatingStatusbar (CFNotificationCenterRef center,FrontPageViewController * observer,CFStringRef name,const void * object,CFDictionaryRef userInfo) {
    [observer checkIfAppIsCovering];
    
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 1);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
        BOOL isAlive = [observer canReloadData];
        BOOL isInApp = [observer checkisInApp];
        if(isAlive && !isInApp){
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [FPIStatusBar updateStatusBarWithObserver:observer];
                    [observer setStatusBarPending:NO];
                });
            });
        }else{
            if(isInApp){
                [observer setStatusBarPending:YES];
            }
        }
    });
    [observer checkPendingNotifications];
}

+(void)setupNotificationSystem: (FrontPageViewController *) observer{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            [FPIStatusBar updateStatusBarWithObserver:observer];
        });
    });
    
    
    //schedule for notifications
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    (__bridge const void *)(observer),
                                    (CFNotificationCallback)updatingStatusbar,
                                    CFSTR("com.junesiphone.frontpage.updatingstatusbar"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately
                                    );
}
@end
