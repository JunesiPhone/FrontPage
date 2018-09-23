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

@interface SBApplicationIcon
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
-(BOOL)iconAllowsLaunch:(id)arg1 ;
@end

@interface SBApplicationController : NSObject
+ (id)sharedInstance;
- (id)allApplications;
- (id)applicationWithBundleIdentifier:(id)arg1;
- (void)uninstallApplication:(id)arg1;
-(id)lastBundleName;
@end

@interface SBIconModel : NSObject
-(NSArray*)visibleIconIdentifiers;
-(id)expectedIconForDisplayIdentifier:(id)arg1 ;
@property(retain, nonatomic) NSDictionary *leafIconsByIdentifier;
@end

@interface SBIconViewMap : NSObject {
    SBIconModel *_model;
}
+ (SBIconViewMap *)switcherMap;
+ (SBIconViewMap *)homescreenMap;
- (SBIconModel *)iconModel;
@end

@interface SBIconController : NSObject
+(instancetype)sharedInstance;
-(BOOL)scrollToIconListAtIndex:(int)index animate:(BOOL)animate;
- (id)model;
- (_Bool)iconAllowsBadging:(id)arg1;
- (SBIconViewMap *)homescreenIconViewMap;
@end

@interface SBIcon
- (id)getIconImage:(int)arg1;
@end;

@implementation FPIApps

/*
    Get badge for application by bundle id if that app has badges enabled.
*/

+(id)getBadgeForBundleID:(NSString *)bundleID{
    SBIconController *iconController = [objc_getClass("SBIconController") sharedInstance];
    SBIconModel *iconModel = [iconController model];
    SBApplicationIcon *appIcon = iconModel.leafIconsByIdentifier[bundleID];
    if([iconController iconAllowsBadging:appIcon]){
        return [iconModel.leafIconsByIdentifier[bundleID] valueForKey:@"badgeValue"];
    }else{
        return @"0";
    }
}

/*
    Get list of springboard Icons to compare to master application list.
*/

+(NSArray *) springboardIcons{
    static SBIconModel *iconModel;
    if (!iconModel) {
        if ([objc_getClass("SBIconViewMap") instancesRespondToSelector:@selector(iconModel)]) {
            SBIconViewMap *viewMap;
            if ([objc_getClass("SBIconViewMap") respondsToSelector:@selector(homescreenMap)]) {
                viewMap = [objc_getClass("SBIconViewMap") homescreenMap];
            } else {
                viewMap = [(SBIconController *)[objc_getClass("SBIconController") sharedInstance] homescreenIconViewMap];
            }
            iconModel = [viewMap iconModel];
        } else {
            iconModel = (SBIconModel *)[objc_getClass("SBIconViewMap") sharedInstance];
        }
    }
    return [iconModel visibleIconIdentifiers];
}

/*
    Save a local image of the app icon for all FP themes to use.
*/

+(void) saveIconImage: (NSString *) bundle withObserver:(id) observer{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if(![FrontPageViewController sharedInstance].iconLock){
            SBIcon * icon = [[[objc_getClass("SBIconController") sharedInstance] model] expectedIconForDisplayIdentifier:bundle];
            @try{
                UIImage * image = [icon getIconImage:2];
                NSData *imageData = UIImagePNGRepresentation(image);
                NSString *nPath = [NSString stringWithFormat:@"/var/mobile/Library/FrontPageCache/%@.png", bundle];
                            [imageData writeToFile:nPath atomically:YES];
            }@catch(NSException*err){
                NSLog(@"FrontPageInfo ERROR %@ for bundle in saveIconImage (FPIApps) %@", err, bundle);
            }
        }
    });
}

/*
    Loop allApplications and save a local image for FP themes.
*/
+(void)saveAllIconImagesWithObserver: (id)observer{
    NSArray *appArray = [[objc_getClass("SBApplicationController") sharedInstance] allApplications];
    NSArray* iconList = [FPIApps springboardIcons];
    for(SBApplication *app in appArray){
        NSString* bundle = app.bundleIdentifier;
        if([iconList containsObject:bundle]){
            [FPIApps saveIconImage:bundle withObserver:observer];
        }
    }
}

+(NSArray *)appsInfo{
    NSArray *appArray = [[objc_getClass("SBApplicationController") sharedInstance] allApplications];
    NSArray* iconList = [FPIApps springboardIcons];
    NSMutableDictionary *appsInfo =[[NSMutableDictionary alloc] init];
    NSMutableArray *combinedInfo = [[NSMutableArray alloc] init];
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
                if(app.isSystemApplication){
                    systemAPP = @"yes";
                }else{
                    systemAPP = @"no";
                }
                int dataUsage = app.dataUsage;
                if([iconList containsObject:bundle]){
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
        NSLog(@"FrontPageInfo FPIApp error appsInfo %@", exception);
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
