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

@implementation FPIApp

+(id)getBadgeForBundleID:(NSString *)bundleID{
    SBIconController *IC = [objc_getClass("SBIconController") sharedInstance];
    SBIconModel *IM = [IC model];
    NSString* badgeValue = @"";
    if([IC iconAllowsBadging:IM.leafIconsByIdentifier[[NSString stringWithFormat:@"%@",bundleID]]]){
        if([[IM.leafIconsByIdentifier[[NSString stringWithFormat:@"%@",bundleID]] valueForKey:@"badgeValue"] isEqualToString:@"0"]){
            badgeValue = @"";
        }else{
            badgeValue = [IM.leafIconsByIdentifier[[NSString stringWithFormat:@"%@",bundleID]] valueForKey:@"badgeValue"];
        }
    }else{
        badgeValue = @"";
    }
    return badgeValue;
}

+(NSString *)appInfo{
    NSString* combined = nil;
        if([objc_getClass("SBApplicationController") lastBundleName]){
            NSDictionary *app = [objc_getClass("SBApplicationController") lastBundleName];
            NSString *bundle = [app valueForKey:@"bundle"];
            NSString *value = @"";
            SBIconController *IC = [objc_getClass("SBIconController") sharedInstance];
            SBIconModel *IM = [IC model];
            if([IC iconAllowsBadging:IM.leafIconsByIdentifier[[NSString stringWithFormat:@"%@",bundle]]]){
                value = [app valueForKey:@"value"];
                if([value isEqualToString:@"0"]){
                    value = @"";
                }
            }else{
                value = @"";
            }
            combined = [NSString stringWithFormat:@"FPI.bundle['%@'].badge = %@;",bundle, value];
        }
    return combined;
}

+(NSString*)singleApp{
    NSString* string = nil;
    if([objc_getClass("SBApplicationController") lastBundleName]){
        NSDictionary *app = [objc_getClass("SBApplicationController") lastBundleName];
        NSString *bundle = [app valueForKey:@"bundle"];
        string = [NSString stringWithFormat:@"badgeUpdated('%@')", bundle];
    }
    return string;
}
@end
