//
//  FPINotifications.m
//  FrontPageViewController
//
//  Created by Edward Winget on 6/4/17.
//  Copyright © 2017 junesiphone. All rights reserved.
//

#import "FPINotifications.h"
#import <objc/runtime.h>


@interface FPINotifications ()

@end

@implementation FPINotifications


+(void)updateNotificationsWithObserver:(FrontPageViewController *)observer{
    NSLog(@"FrontPage - Load LoadingNotificationsCalled");
    NSDate *timeMethod = [NSDate date];
    
    NSMutableDictionary *notificationInfo =[[NSMutableDictionary alloc] init];
    NSMutableDictionary *bulletins = [objc_getClass("BBServer") frontpage_ids];
    NSMutableArray *notificationArray = [[NSMutableArray alloc] init];
    NSMutableDictionary *fullBulletin = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *bulletInfo;
    NSString *bulletKey;
    
    for (NSString *bullet in bulletins) {
        
        bulletKey = bullet;
        fullBulletin = [bulletins objectForKey:bullet];
        NSString *bundle = [fullBulletin objectForKey:@"bundle"];
        NSString *text = [fullBulletin objectForKey:@"text"];
        
        NSMutableString *s = [NSMutableString stringWithString:text];
        [s replaceOccurrencesOfString:@"\'" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
        [s replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
        [s replaceOccurrencesOfString:@"/" withString:@"\\/" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
        [s replaceOccurrencesOfString:@"\n" withString:@"\\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
        [s replaceOccurrencesOfString:@"\b" withString:@"\\b" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
        [s replaceOccurrencesOfString:@"\f" withString:@"\\f" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
        [s replaceOccurrencesOfString:@"\r" withString:@"\\r" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
        [s replaceOccurrencesOfString:@"\t" withString:@"\\t" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
        text = [NSString stringWithString:s];

        bulletInfo = [[NSMutableDictionary alloc] init];
        [bulletInfo setValue:bundle forKey:@"bundle"];
        [bulletInfo setValue:text forKey:@"text"];
        [notificationArray addObject:bulletInfo];
        
    }

    [notificationInfo setValue:notificationArray forKey:@"all"];
    [observer convertDictToJSON:notificationInfo withName:@"notifications"];
    [observer callJSFunction:@"loadNotifications()"];
    notificationInfo = nil;
    bulletins = nil;
    notificationArray = nil;
    fullBulletin = nil;
    bulletInfo = nil;
    
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:timeMethod];
    NSLog(@"FrontPage - Notifications executionTime = %f", executionTime);
    
}

void updatingNotifications (CFNotificationCenterRef center,FrontPageViewController * observer,CFStringRef name,const void * object,CFDictionaryRef userInfo) {
    [observer checkIfAppIsCovering];
    BOOL isAlive = [observer canReloadData];
    BOOL isInApp = [observer checkisInApp];
    NSLog(@"FrontPage - Load isInAPp %@", isInApp ? @"yes" : @"no");
    NSLog(@"FrontPage - Load isAlive %@", isAlive ? @"yes" : @"no");
    if(isAlive && !isInApp){
        NSLog(@"FrontPage - Load Updated");
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 1);
            dispatch_after(delay, dispatch_get_main_queue(), ^(void){
                [FPINotifications updateNotificationsWithObserver:observer];
                [observer setNotificationsPending:NO];
            });
        });
    }else{
        if(isInApp){
            [observer setNotificationsPending:YES];
        }
    }
    [observer checkPendingNotifications];
}

+(void)setupNotificationSystem: (FrontPageViewController *) observer{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
             [FPINotifications updateNotificationsWithObserver:observer];
        });
    });
    
    //schedule for notifications
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    (__bridge const void *)(observer),
                                    (CFNotificationCallback)updatingNotifications,
                                    CFSTR("com.junesiphone.frontpage.updatingnotifications"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately
                                    );
}

@end
