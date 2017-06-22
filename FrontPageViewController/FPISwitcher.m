//
//  FPISwitcher.m
//  FrontPageViewController
//
//  Created by Edward Winget on 6/4/17.
//  Copyright © 2017 junesiphone. All rights reserved.
//

#import "FPISwitcher.h"
#import <objc/runtime.h>


@interface FPISwitcher ()

@end

@interface SBAppSwitcherModel
+ (id)sharedInstance;
- (id)mainSwitcherDisplayItems;
- (id)snapshot;
-(id)snapshotOfFlattenedArrayOfAppIdentifiersWhichIsOnlyTemporary;
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
@end


@interface SBApplicationController : NSObject
+ (id)sharedInstance;
- (id)allApplications;
- (id)applicationWithBundleIdentifier:(id)arg1;

@end

@implementation FPISwitcher

#define deviceVersion [[[UIDevice currentDevice] systemVersion] floatValue]

+(void)updateSwitcherWithObserver:(FrontPageViewController *)observer{
    NSDate *timeMethod = [NSDate date];
    NSMutableDictionary *switcherInfo = [[NSMutableDictionary alloc] init];
    NSMutableArray *switcherArray = [[NSMutableArray alloc] init];
    
    NSArray *switcherApps;
    if(deviceVersion < 9.0){
        switcherApps = [[objc_getClass("SBAppSwitcherModel") sharedInstance] snapshotOfFlattenedArrayOfAppIdentifiersWhichIsOnlyTemporary];
    }

    if(deviceVersion >= 9.0){
        switcherApps = [[objc_getClass("SBAppSwitcherModel") sharedInstance] mainSwitcherDisplayItems];
    }
    
    
    if(deviceVersion < 9.0){
        for (NSString* currentString in switcherApps){
            SBApplication *app = [[objc_getClass("SBApplicationController") sharedInstance] applicationWithBundleIdentifier:currentString];
            NSString *bundle = app.displayIdentifier;
            [switcherArray addObject:bundle];
        }
        
    }else{
        for (SBApplication *app in switcherApps) {
            NSString *bundle = app.displayIdentifier;
            [switcherArray addObject:bundle];
        }
    }
    
    [switcherInfo setValue:switcherArray forKey:@"bundles"];
    [observer convertDictToJSON:switcherInfo withName:@"switcher"];
    [observer callJSFunction:@"loadSwitcher()"];
    switcherInfo = nil;
    switcherArray = nil;
    switcherApps = nil;
    
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:timeMethod];
    NSLog(@"FrontPage - Switcher executionTime = %f", executionTime);
}

void updatingSwitcher (CFNotificationCenterRef center,FrontPageViewController * observer,CFStringRef name,const void * object,CFDictionaryRef userInfo) {
    
    [observer checkIfAppIsCovering];
    
    BOOL isAlive = [observer canReloadData];
    BOOL isInApp = [observer checkisInApp];
    
    if(isAlive && !isInApp){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 1);
            dispatch_after(delay, dispatch_get_main_queue(), ^(void){
                [FPISwitcher updateSwitcherWithObserver:observer];
                [observer setSwitcherPending:NO];
            });
        });
    }else{
        if(isInApp){
            [observer setSwitcherPending:YES];
        }
    }
    [observer checkPendingNotifications];
}

+(void)setupNotificationSystem: (FrontPageViewController *) observer{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            [FPISwitcher updateSwitcherWithObserver:observer];
        });
    });

    
    //schedule for notifications
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    (__bridge const void *)(observer),
                                    (CFNotificationCallback)updatingSwitcher,
                                    CFSTR("com.junesiphone.frontpage.updatingswitcher"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately
                                    );
}
@end
