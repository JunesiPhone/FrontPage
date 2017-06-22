//
//  FPIAlarm.m
//  FrontPageViewController
//
//  Created by Edward Winget on 6/5/17.
//  Copyright © 2017 junesiphone. All rights reserved.
//

#import "FPIAlarm.h"
#import <objc/runtime.h>

@interface FPIAlarm ()

@end


@interface ClockManager
+ (id)sharedManager;
-(NSArray *)scheduledLocalNotificationsCache;
-(void)refreshScheduledLocalNotificationsCache;
-(void)resetUpdatesToLocalNotificationsCache;

@end


@interface UIConcreteLocalNotification
- (id)fireDate;
-(id)userInfo;
@end

@implementation FPIAlarm
#define deviceVersion [[[UIDevice currentDevice] systemVersion] floatValue]


+(void)updateAlarmWithObserver:(FrontPageViewController *)observer{
    [observer setAlarmPending:NO];
    NSString *formatStringForHours = [NSDateFormatter dateFormatFromTemplate:@"j" options:0 locale:[NSLocale currentLocale]];
    NSRange containsA = [formatStringForHours rangeOfString:@"a"];
    BOOL hasAMPM = containsA.location != NSNotFound;
    
    @try {
        NSMutableDictionary *alarmInfo = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *finalAlarmInfo =[[NSMutableDictionary alloc] init];
        NSMutableArray *alarmArray = [[NSMutableArray alloc] init];
        NSArray *alarms;
        
        NSMutableDictionary *fromTweak = [objc_getClass("SBClockDataProvider") frontpage_alarms];
        
        if([fromTweak objectForKey:@"alarms"]){
            alarms = [fromTweak objectForKey:@"alarms"];
        }else{
            ClockManager *manager = [objc_getClass("ClockManager") sharedManager];
            if(deviceVersion >= 9.0f){
                [manager refreshScheduledLocalNotificationsCache];
            }
            alarms = [manager scheduledLocalNotificationsCache];
        }
        
        //NSString *date;
        NSString *alarmTime;
        
        if(alarms){
            for(UIConcreteLocalNotification *alarm in alarms){
                // date = alarm.fireDate;
                int hr = [[alarm.userInfo valueForKey:@"hour"] intValue];
                NSString *mn = [NSString stringWithFormat:@"%@", [alarm.userInfo valueForKey:@"minute"]];
                NSString *pm;
                
                if([mn isEqualToString:@"0"]){
                    mn = @"00";
                }
                if(hasAMPM){
                    if(hr > 12){
                        pm = @"PM";
                        hr = hr - 12;
                    }else{
                        pm = @"AM";
                    }
                    if(hr == 0){
                        hr = 12;
                    }
                }else{
                    pm = @"";
                }
                if(alarm.userInfo){
                    alarmTime = [NSString stringWithFormat:@"%d:%@ %@", hr, mn, pm];
                    [alarmInfo setValue:alarmTime forKey:@"time"];
                    //[alarmInfo setValue:date forKey:@"date"];
                    [alarmArray addObject:alarmInfo];
                    
                }
            }
        }
        
        if([alarmArray count] == 0){
            [alarmInfo setValue:alarmTime forKey:@"time"];
            [alarmArray addObject:alarmInfo];
        }
        
        [finalAlarmInfo setValue:alarmArray forKey:@"allalarms"];
        [observer convertDictToJSON:finalAlarmInfo withName:@"alarm"];
        [observer callJSFunction:@"loadAlarms()"];
        
    } @catch (NSException *exception) {
        NSLog(@"FPIAlarm: error on updateAlarmWithObserver %@", exception);
    }
    
}

void updatingAlarm (CFNotificationCenterRef center,FrontPageViewController * observer,CFStringRef name,const void * object,CFDictionaryRef userInfo) {
    [observer checkIfAppIsCovering];
    BOOL isAlive = [observer canReloadData];
    BOOL isInApp = [observer checkisInApp];

    if(isAlive && !isInApp){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 1);
            dispatch_after(delay, dispatch_get_main_queue(), ^(void){
                [FPIAlarm updateAlarmWithObserver:observer];
                [observer setAlarmPending:NO];
            });
        });
    }else{
        if(isInApp){
            [observer setAlarmPending:YES];
        }
    }
    [observer checkPendingNotifications];
}

+(void)loadAlarmsWithObserver: (FrontPageViewController *) observer{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            [FPIAlarm updateAlarmWithObserver:observer];
        });
    });
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    (__bridge const void *)(observer),
                                    (CFNotificationCallback)updatingAlarm,
                                    CFSTR("com.junesiphone.frontpage.updatingalarm"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately
                                    );
    
}
@end
