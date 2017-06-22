//
//  FPIApps.m
//  FrontPageViewController
//
//  Created by Edward Winget on 6/4/17.
//  Copyright © 2017 junesiphone. All rights reserved.
//

#import "FPIApps.h"
#import <objc/runtime.h>


@interface FPIApps ()

@end

/*Getting Apps */
@interface SBApplicationController : NSObject
+ (id)sharedInstance;
- (id)allApplications;
- (id)applicationWithBundleIdentifier:(id)arg1;
- (void)uninstallApplication:(id)arg1;
-(id)lastBundleName;
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



@implementation FPIApps

// 1 users battery doesn't update after update 1.0.6 I have no idea why and cannot replicate it.
// The idea with the helpers below is to try and catch what is not being handled

+(id)getBadgeForBundleID:(NSString *)bundleID{
    @try {
        SBIconController *IC = [objc_getClass("SBIconController") sharedInstance];
        SBIconModel *IM = [IC model];
        return [IM.leafIconsByIdentifier[[NSString stringWithFormat:@"%@",bundleID]] valueForKey:@"badgeValue"];
    } @catch (NSException *exception) {
        //write to log
        return 0;
    }
}

+(void)updateAppsWithObserver:(FrontPageViewController *)observer{
    NSDate *timeMethod = [NSDate date];
    NSArray *appArray = [[objc_getClass("SBApplicationController") sharedInstance] allApplications];
    NSMutableDictionary *appsInfo =[[NSMutableDictionary alloc] init];
    NSMutableDictionary *iconImages = [[NSMutableDictionary alloc] init];
    
    
    NSMutableArray *blacklist = [[NSMutableArray alloc] initWithObjects:@"com.apple.SharedWebCredentialViewService", @"com.apple.AccountAuthenticationDialog", @"com.apple.AdSheetPhone", @"com.apple.AskPermissionUI", @"com.apple.compassCalibrationViewService", @"com.apple.CoreAuthUI", @"com.apple.DemoApp", @"com.apple.Diagnostics", @"com.apple.FacebookAccountMigrationDialog", @"com.apple.GameController", @"com.apple.HealthPrivacyService", @"com.apple.InCallService", @"com.apple.MailcompositionService", @"com.apple.MobileReplayer", @"com.apple.MusicUIService", @"com.apple.PassbookUIService", @"com.apple.PhotosViewService", @"com.apple.PreBoard", @"com.apple.PrintKit.Print-Center", @"com.apple.SiriViewService", @"com.apple.TencentWeiboAccountMigrationDialog", @"com.apple.TrustMe",@"com.apple.WebContentFilter.remoteUI.WebContentAnalysisUI", @"com.apple.WebSheet", @"com.apple.WebViewService", @"com.apple.appleaccount.AACredentialRecoveryDialog", @"com.apple.datadetectors.DDActionsService", @"com.apple.fieldtest", @"com.apple.gamecenter.GameCenterUIService", @"com.apple.iad.iAdOptOut", @"com.apple.ios.StoreKitUIService", @"com.apple.iosdiagnostics", @"com.apple.mobilesms.compose", @"com.apple.mobilesms.notification", @"com.apple.purplebuddy", @"com.apple.quicklook.quicklookd", @"com.apple.share", @"com.apple.uikit.PrintStatus", @"com.kstreich-dev.3gunrestrictor.configapp", @"com.apple.DataActivation", @"com.apple.Home.HomeUIService", @"com.apple.social.SLGoogleAuth", @"com.apple.social.SLYahooAuth", @"com.apple.SafariViewService", @"com.apple.ServerDocuments", @"com.apple.CloudKit.ShareBear", @"com.apple.StreDemoViewService", @"com.apple.Diagnostics.Mitosis", @"com.apple.appleseed.FeedbackAssistant", @"com.apple.StoreDemoViewService", @"undefined", @"com.apple.managedconfiguration.MDMRemoteAlertService", @"com.apple.CompassCalibrationViewService",@"com.apple.MailCompositionService",@"com.apple.webapp",@"com.apple.webapp1",@"com.apple.webapp2",@"com.apple.webapp3",@"com.apple.DiagnosticsService",@"com.apple.ScreenSharingViewService",@"com.apple.SharingViewService", @"com.apple.DiagnosticsService", @"com.apple.VSViewService", @"com.apple.WatchListViewService", nil];
    
    
    //NSLog(@"FrontPage - Updating System %@", appArray);
    NSMutableDictionary *appInfo;
    NSMutableArray *newAppArray = [[NSMutableArray alloc] init];
    NSMutableDictionary *badgesbybundle = [[NSMutableDictionary alloc] init];
    
    @try {
   
   
    for(SBApplication *app in appArray){
    
        if(app.displayName){
            NSString* bundle = app.bundleIdentifier;
            NSMutableString *name = [NSMutableString stringWithString:app.displayName];
    [name replaceOccurrencesOfString:@"\'" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [name length])];
        
        NSString* systemAPP;
        //NSLog(@"TTDS Name %@", app.isSystemApplication ? @"YES" : @"NO");
        
        if(app.isSystemApplication){
            systemAPP = @"yes";
        }else{
            systemAPP = @"no";
        }
       
        int dataUsage = app.dataUsage;
        
        if(![blacklist containsObject:bundle]){
            appInfo = [[NSMutableDictionary alloc] init];
            [appInfo setValue:bundle forKey:@"bundle"];
            [appInfo setValue:name forKey:@"name"];
            [appInfo setValue:systemAPP forKey:@"systemApp"];
            [appInfo setValue:[self getBadgeForBundleID:bundle] forKey:@"badge"];
            [appInfo setValue:[NSNumber numberWithInt:dataUsage] forKey:@"dataUsage"];
            
            /* Save icons to cache so don't need to encode all the time */
            NSString *iconImage;
            if([iconImages objectForKey:bundle]){
                iconImage = [iconImages objectForKey:bundle];
            }else{
                SBIcon * icon = [[[objc_getClass("SBIconController") sharedInstance] model] expectedIconForDisplayIdentifier:bundle];
                UIImage * image = [icon getIconImage:2];
                NSData *imageData = UIImagePNGRepresentation(image);
                NSString *encodedString = [imageData base64EncodedStringWithOptions:0];
                iconImage = [NSString stringWithFormat:@"data:image/png;base64,%@", encodedString];
                [iconImages setObject:iconImage forKey:bundle];
            }
            [appInfo setValue:iconImage forKey:@"icon"];
            [newAppArray addObject:appInfo];
            [badgesbybundle setValue:appInfo forKey:bundle];
        }
        }
    }
        
    } @catch (NSException *exception) {
        NSLog(@"FrontPage - FPIApp error %@", exception);
    }
    
    //NSLog(@"TTDS %@", appInfo);
    NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByName];
    NSArray *sortedArray = [newAppArray sortedArrayUsingDescriptors:sortDescriptors];
    [appsInfo setValue:sortedArray forKey:@"all"];
    [observer convertDictToJSON:appsInfo withName:@"apps"];
    [observer convertDictToJSON:badgesbybundle withName:@"bundle"];
    [observer callJSFunction:@"loadApps()"];
    
    appArray = nil;
    appsInfo = nil;
    blacklist = nil;
    appInfo = nil;
    newAppArray = nil;
    badgesbybundle = nil;
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:timeMethod];
    NSLog(@"FrontPage - App executionTime = %f", executionTime);
}

void updatingApps (CFNotificationCenterRef center,FrontPageViewController * observer,CFStringRef name,const void * object,CFDictionaryRef userInfo) {
    
    [observer checkIfAppIsCovering];
    
    BOOL isAlive = [observer canReloadData];
    BOOL isInApp = [observer checkisInApp];
    
    if(isAlive && !isInApp){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 1);
            dispatch_after(delay, dispatch_get_main_queue(), ^(void){
                [FPIApps updateAppsWithObserver:observer];
                [observer setAppsPending:NO];
            });
        });
    }else{
        if(isInApp){
            [observer setAppsPending:YES];
        }
    }
    [observer checkPendingNotifications];
}

void newApps (CFNotificationCenterRef center,FrontPageViewController * observer,CFStringRef name,const void * object,CFDictionaryRef userInfo) {
    [FPIApps updateAppsWithObserver:observer];
    [observer callJSFunction:@"appsInstalled()"];
    [[objc_getClass("SBIconController") sharedInstance] scrollToIconListAtIndex:0 animate:YES];
}

+(void)setupNotificationSystem: (FrontPageViewController *) observer{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            [FPIApps updateAppsWithObserver:(FrontPageViewController *)observer]; //call immediately
        });
    });

    
    
    //schedule for notifications
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    (__bridge const void *)(observer),
                                    (CFNotificationCallback)updatingApps,
                                    CFSTR("com.junesiphone.frontpage.updatingapps"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately
                                    );
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    (__bridge const void *)(observer),
                                    (CFNotificationCallback)newApps,
                                    CFSTR("com.junesiphone.frontpage.newappinstalled"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately
                                    );
}


@end
