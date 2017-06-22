//
//  FPIBattery.m
//  FrontPageViewController
//
//  Created by Edward Winget on 6/4/17.
//  Copyright © 2017 junesiphone. All rights reserved.
//

#import "FPIBattery.h"
#import <objc/runtime.h>

@interface FPIBattery ()

@end


/* getting battery */
@interface SBUIController : NSObject
+(SBUIController *)sharedInstanceIfExists;
-(BOOL)isOnAC;
-(int)batteryCapacityAsPercentage;
-(BOOL)handleHomeButtonSinglePressUp;
@end

@implementation FPIBattery
+(id)getBatteryInfo:(int) info{
    @try {
        SBUIController *SB = [objc_getClass("SBUIController") sharedInstanceIfExists];
        NSString *chargeText = ([SB isOnAC]) ? @"Charging" : @"Not Charging";
        int battery = [SB batteryCapacityAsPercentage];
        switch (info) {
            case 0:
                return [NSString stringWithFormat:@"%d",battery];
                break;
            case 1:
                return chargeText;
                break;
            case 2:
                return ([SB isOnAC]) ? @"1" : @"0";
                break;
        }
        return 0;
    } @catch (NSException *exception) {
        //write to log
        return 0;
    }
}

+(void)updateBatteryWithObserver:(FrontPageViewController *)observer{
    NSDate *timeMethod = [NSDate date];
    NSMutableDictionary *batteryInfo =[[NSMutableDictionary alloc] init];
    [batteryInfo setValue:[self getBatteryInfo:0] forKey:@"percent"];
    [batteryInfo setValue:[self getBatteryInfo:1] forKey:@"chargetext"];
    [batteryInfo setValue:[self getBatteryInfo:2] forKey:@"chargestate"];
    [observer convertDictToJSON:batteryInfo withName:@"battery"];
    [observer callJSFunction:@"loadBattery()"];
    batteryInfo = nil;
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:timeMethod];
    NSLog(@"FrontPage - Battery executionTime = %f", executionTime);
    
}

void updatingBattery (CFNotificationCenterRef center,FrontPageViewController * observer,CFStringRef name,const void * object,CFDictionaryRef userInfo) {
    
    [observer checkIfAppIsCovering];
    
    BOOL isAlive = [observer canReloadData];
    BOOL isInApp = [observer checkisInApp];
    
    if(isAlive && !isInApp){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 1);
            dispatch_after(delay, dispatch_get_main_queue(), ^(void){
                [FPIBattery updateBatteryWithObserver:observer];
                [observer setBatteryPending:NO];
            });
        });
    }else{
        if(isInApp){
            [observer setBatteryPending:YES];
        }
    }
    [observer checkPendingNotifications];
}

+(void)setupNotificationSystem: (FrontPageViewController *) observer{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            [FPIBattery updateBatteryWithObserver:observer];
        });
    });
    
    
    //schedule for notifications
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    (__bridge const void *)(observer),
                                    (CFNotificationCallback)updatingBattery,
                                    CFSTR("com.junesiphone.frontpage.updatingbattery"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately
                                    );
}
@end
