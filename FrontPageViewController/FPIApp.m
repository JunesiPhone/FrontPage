//
//  FPIApp.m
//  FrontPageViewController
//
//  Created by Edward Winget on 6/9/17.
//  Copyright © 2017 junesiphone. All rights reserved.
//

#import "FPIApp.h"
#import <objc/runtime.h>

@interface FPIApp ()
@end

@interface SBApplicationController : NSObject
+ (id)sharedInstance;
- (id)allApplications;
- (id)applicationWithBundleIdentifier:(id)arg1;
- (void)uninstallApplication:(id)arg1;
-(id)lastBundleName;
@end
@interface SBIconController : NSObject
+(instancetype)sharedInstance;
-(BOOL)scrollToIconListAtIndex:(int)index animate:(BOOL)animate;
- (id)model;
@end


@interface SBIcon
- (id)getIconImage:(int)arg1;
@end;


@interface SBIconModel : NSObject
-(NSArray*)visibleIconIdentifiers;
-(id)expectedIconForDisplayIdentifier:(id)arg1 ;
@property(retain, nonatomic) NSDictionary *leafIconsByIdentifier;
@end

@implementation FPIApp

+(id)getBadgeForBundleID:(NSString *)bundleID{
    @try {
        SBIconController *IC = [objc_getClass("SBIconController") sharedInstance];
        SBIconModel *IM = [IC model];
        return [IM.leafIconsByIdentifier[[NSString stringWithFormat:@"%@",bundleID]] valueForKey:@"badgeValue"];
    } @catch (NSException *exception) {
        return 0;
    }
}

+(void)updateAppWithObserver:(FrontPageViewController *)observer{
    @try {
        if([objc_getClass("SBApplicationController") lastBundleName]){
            NSDictionary *app = [objc_getClass("SBApplicationController") lastBundleName];
            NSString *bundle = [app valueForKey:@"bundle"];
            NSString *value = [app valueForKey:@"value"];
        
            [observer callJSFunction:[NSString stringWithFormat:@"FPI.bundle['%@'].badge = %@;",bundle, value]];
            [observer callJSFunction:[NSString stringWithFormat:@"badgeUpdated('%@')", bundle]];
        }
    } @catch (NSException *exception) {
        NSLog(@"FrontPage Bundle Load %@", exception);
    }
}

void newAppUpdated (CFNotificationCenterRef center,FrontPageViewController * observer,CFStringRef name,const void * object,CFDictionaryRef userInfo) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
             [FPIApp updateAppWithObserver:observer];
        });
    });
}

+(void)setupNotificationSystem: (FrontPageViewController *) observer{
    
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    (__bridge const void *)(observer),
                                    (CFNotificationCallback)newAppUpdated,
                                    CFSTR("com.junesiphone.frontpage.app"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately
                                    );
}

@end
