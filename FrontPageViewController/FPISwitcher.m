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
-(id)mainSwitcherAppLayouts;
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

@interface SBApplicationController : NSObject
+ (id)sharedInstance;
- (id)allApplications;
- (id)applicationWithBundleIdentifier:(id)arg1;

@end


//iOS 11.1.2
@interface SBDisplayItem : NSObject
-(NSString *)displayIdentifier;
@end
@interface SBAppLayout : NSObject
-(NSDictionary *)rolesToLayoutItemsMap;
@end

@implementation FPISwitcher

#define deviceVersion [[[UIDevice currentDevice] systemVersion] floatValue]

+(NSMutableDictionary *)switcherInfo{
    NSMutableDictionary *switcherInfo = [[NSMutableDictionary alloc] init];
    NSMutableArray *switcherArray = [[NSMutableArray alloc] init];
    
    NSArray *switcherApps;
    if(deviceVersion < 9.0){
        switcherApps = [[objc_getClass("SBAppSwitcherModel") sharedInstance] snapshotOfFlattenedArrayOfAppIdentifiersWhichIsOnlyTemporary];
    }

    if(deviceVersion >= 9.0){
        if ([[objc_getClass("SBAppSwitcherModel") sharedInstance] respondsToSelector:@selector(mainSwitcherDisplayItems)]) {
            switcherApps = [[objc_getClass("SBAppSwitcherModel") sharedInstance] mainSwitcherDisplayItems];
        }else if([[objc_getClass("SBAppSwitcherModel") sharedInstance] respondsToSelector:@selector(mainSwitcherAppLayouts)]){
            //NSLog(@"JTest %@", [[objc_getClass("SBAppSwitcherModel") sharedInstance]mainSwitcherAppLayouts]);
            switcherApps = [[objc_getClass("SBAppSwitcherModel") sharedInstance]mainSwitcherAppLayouts];
        }else{
            switcherApps = nil;
        }
    }
    
    
    if(deviceVersion < 9.0){
        for (NSString* currentString in switcherApps){
            SBApplication *app = [[objc_getClass("SBApplicationController") sharedInstance] applicationWithBundleIdentifier:currentString];
            NSString *bundle = app.displayIdentifier;
            [switcherArray addObject:bundle];
        }
    }else if(deviceVersion < 11.0){
        for (SBApplication *app in switcherApps) {
            NSString *bundle = app.displayIdentifier;
            [switcherArray addObject:bundle];
        }
    }else{
        for (SBAppLayout *app in switcherApps) {
            NSDictionary *temp = [app rolesToLayoutItemsMap];
            if(temp){
                NSArray *values = [temp allValues];
                if([values count] > 0){
                    SBDisplayItem *item = [values objectAtIndex:0];
                    if(item){
                        [switcherArray addObject:item.displayIdentifier];
                    }
                }
            }
        }
    }
    
    [switcherInfo setValue:switcherArray forKey:@"bundles"];
    switcherArray = nil;
    switcherApps = nil;
    return switcherInfo;
}
@end
