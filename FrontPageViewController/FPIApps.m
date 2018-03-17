//
//  FPIApps.m
//  FrontPageViewController
//
//  Created by Edward Winget on 6/4/17.
//  Copyright © 2017 junesiphone. All rights reserved.
//

#import "FPIApps.h"
#import "FrontPageViewController.h"
#import <objc/runtime.h>


@interface FPIApps ()

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

/*Getting Apps */
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
- (_Bool)iconAllowsBadging:(id)arg1;
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
        if([IC iconAllowsBadging:IM.leafIconsByIdentifier[[NSString stringWithFormat:@"%@",bundleID]]]){
            return [IM.leafIconsByIdentifier[[NSString stringWithFormat:@"%@",bundleID]] valueForKey:@"badgeValue"];
        }else{
            return @"0";
        }
        
    } @catch (NSException *exception) {
        //write to log
        return 0;
    }
}


+(void) saveIconImage: (NSString *) bundle withObserver:(id) observer{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if(![FrontPageViewController sharedInstance].iconLock){
            SBIcon * icon = [[[objc_getClass("SBIconController") sharedInstance] model] expectedIconForDisplayIdentifier:bundle];
            UIImage * image = [icon getIconImage:2];
            NSData *imageData = UIImagePNGRepresentation(image);
            NSString *nPath = [NSString stringWithFormat:@"/var/mobile/Library/FrontPageCache/%@.png", bundle];
            [imageData writeToFile:nPath atomically:YES];
        }
    });
}

+(void)saveAllIconImagesWithObserver: (id)observer{
    NSArray *appArray = [[objc_getClass("SBApplicationController") sharedInstance] allApplications];
    for(SBApplication *app in appArray){
        NSString* bundle = app.bundleIdentifier;
        [FPIApps saveIconImage:bundle withObserver:observer];
    }
}


+(NSArray *)appsInfo{
    NSArray *appArray = [[objc_getClass("SBApplicationController") sharedInstance] allApplications];
    NSMutableDictionary *appsInfo =[[NSMutableDictionary alloc] init];
    NSMutableArray *combinedInfo = [[NSMutableArray alloc] init];
    
    NSMutableArray *blacklist = [[NSMutableArray alloc] initWithObjects:@"com.apple.SharedWebCredentialViewService", @"com.apple.AccountAuthenticationDialog", @"com.apple.AdSheetPhone", @"com.apple.AskPermissionUI", @"com.apple.compassCalibrationViewService", @"com.apple.CoreAuthUI", @"com.apple.DemoApp", @"com.apple.Diagnostics", @"com.apple.FacebookAccountMigrationDialog", @"com.apple.GameController", @"com.apple.HealthPrivacyService", @"com.apple.InCallService", @"com.apple.MailcompositionService", @"com.apple.MobileReplayer", @"com.apple.MusicUIService", @"com.apple.PassbookUIService", @"com.apple.PhotosViewService", @"com.apple.PreBoard", @"com.apple.PrintKit.Print-Center", @"com.apple.SiriViewService", @"com.apple.TencentWeiboAccountMigrationDialog", @"com.apple.TrustMe",@"com.apple.WebContentFilter.remoteUI.WebContentAnalysisUI", @"com.apple.WebSheet", @"com.apple.WebViewService", @"com.apple.appleaccount.AACredentialRecoveryDialog", @"com.apple.datadetectors.DDActionsService", @"com.apple.fieldtest", @"com.apple.gamecenter.GameCenterUIService", @"com.apple.iad.iAdOptOut", @"com.apple.ios.StoreKitUIService", @"com.apple.iosdiagnostics", @"com.apple.mobilesms.compose", @"com.apple.mobilesms.notification", @"com.apple.purplebuddy", @"com.apple.quicklook.quicklookd", @"com.apple.share", @"com.apple.uikit.PrintStatus", @"com.kstreich-dev.3gunrestrictor.configapp", @"com.apple.DataActivation", @"com.apple.Home.HomeUIService", @"com.apple.social.SLGoogleAuth", @"com.apple.social.SLYahooAuth", @"com.apple.SafariViewService", @"com.apple.ServerDocuments", @"com.apple.CloudKit.ShareBear", @"com.apple.StreDemoViewService", @"com.apple.Diagnostics.Mitosis", @"com.apple.appleseed.FeedbackAssistant", @"com.apple.StoreDemoViewService", @"undefined", @"com.apple.managedconfiguration.MDMRemoteAlertService", @"com.apple.CompassCalibrationViewService",@"com.apple.MailCompositionService",@"com.apple.webapp",@"com.apple.webapp1",@"com.apple.webapp2",@"com.apple.webapp3",@"com.apple.DiagnosticsService",@"com.apple.ScreenSharingViewService",@"com.apple.SharingViewService", @"com.apple.DiagnosticsService", @"com.apple.VSViewService", @"com.apple.WatchListViewService", @"com.apple.SafariViewService", @"com.apple.CheckerBoard", @"com.apple.SreenSharingViewService", @"com.apple.ScreenshotServicesService", @"com.coolstar.SafeMode", @"com.apple.carkit.DNDBuddy", @"com.apple.WLAccessService", @"com.apple.ChargingViewService", @"com.apple.CTCarrierSpaceAuth", @"com.apple.FTMInternal", @"org.coolstar.SafeMode", @"com.apple.ios.StoreKitUIService", @"com.apple.susuiservice", @"com.apple.AccountAuthenticationDialog", @"com.apple.AdSheetPhone", @"com.apple.appleseed.FeedbackAssistant", @"com.apple.AskPermissionUI", @"com.apple.carkit.DNDBuddy", @"com.apple.ChargingViewService", @"com.apple.CheckerBoard", @"com.apple.CloudKit.ShareBear", @"com.apple.CompassCalibrationViewService", @"com.apple.CoreAuthUI", @"com.apple.CTCarrierSpaceAuth", @"com.apple.DataActivation", @"com.apple.datadetectors.DDActionsService", @"com.apple.DemoApp", @"com.apple.DiagnosticsService", @"com.apple.fieldtest", @"com.apple.FTMInternal", @"com.apple.gamecenter.GameCenterUIService", @"com.apple.HealthPrivacyService", @"com.apple.iad.iAdOptOut", @"com.apple.InCallService", @"com.apple.ios.StoreKitUIService", @"com.apple.MailCompositionService", @"com.apple.MobileReplayer", @"com.apple.mobilesms.compose", @"com.apple.MusicUIService", @"com.apple.PassbookUIService", @"com.apple.PhotosViewService", @"com.apple.PreBoard", @"com.apple.purplebuddy", @"com.apple.SafariViewService", @"com.apple.ScreenSharingViewService", @"com.apple.ScreenshotServicesService", @"com.apple.ServerDocuments", @"com.apple.SharedWebCredentialViewService", @"com.apple.SharingViewService", @"com.apple.social.SLGoogleAuth", @"com.apple.social.SLYahooAuth", @"com.apple.StoreDemoViewService", @"com.apple.susuiservice", @"com.apple.TrustMe", @"com.apple.VSViewService", @"com.apple.WebContentFilter.remoteUI.WebContentAnalysisUI", @"com.apple.WebSheet", @"com.apple.WLAccessService", @"org.coolstar.SafeMode", @"com.apple.family", @"com.apple.Magnifier", nil];
    
    
    //NSLog(@"FrontPage - Updating System %@", appArray);
    NSMutableDictionary *appInfo;
    NSMutableArray *newAppArray = [[NSMutableArray alloc] init];
    NSMutableDictionary *badgesbybundle = [[NSMutableDictionary alloc] init];
    
    @try {
   
   
    for(SBApplication *app in appArray){
    
        if(app.displayName){
            NSString* bundle = app.bundleIdentifier;
            NSLog(@"FPStatus %@", bundle);
            NSMutableString *name = [NSMutableString stringWithString:app.displayName];
    [name replaceOccurrencesOfString:@"\'" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [name length])];
        
        NSString* systemAPP;
        
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
            [newAppArray addObject:appInfo];
            [badgesbybundle setValue:appInfo forKey:bundle];
        }
        }
    }
        
    } @catch (NSException *exception) {
        NSLog(@"FrontPage - FPIApp error %@", exception);
    }
    
    NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByName];
    NSArray *sortedArray = [newAppArray sortedArrayUsingDescriptors:sortDescriptors];
    [appsInfo setValue:sortedArray forKey:@"all"];
    
    [combinedInfo addObject: appsInfo];
    [combinedInfo addObject:badgesbybundle];
    return combinedInfo;
}
@end
