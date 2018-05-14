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

@interface BBServer
+(instancetype)frontpage_sharedInstance;
+(id)frontpage_ids;
- (void)publishBulletin:(id)arg1 destinations:(unsigned long long)arg2 alwaysToLockScreen:(_Bool)arg3;
- (id)_allBulletinsForSectionID:(id)arg1;

- (id)allBulletinIDsForSectionID:(id)arg1;
- (id)noticesBulletinIDsForSectionID:(id)arg1;
- (id)bulletinIDsForSectionID:(id)arg1 inFeed:(unsigned long long)arg2;
@end



@interface BBBulletin : NSObject
@property(copy) NSString *sectionID;
@property(copy) NSString *bulletinID;
@property(copy) NSDictionary *context;
@property(copy) NSString *section;
@property(copy) NSString *message;
@property(copy) NSString *subtitle;
@property(copy) NSString *title;
@end

@implementation FPINotifications


+(NSMutableDictionary *)notificationInfo{
    
    NSMutableDictionary *notificationInfo = [[NSMutableDictionary alloc] init];
    
    @try{
        NSMutableDictionary *bulletins = [objc_getClass("BBServer") frontpage_ids];
        NSMutableArray *notificationArray = [[NSMutableArray alloc] init];
        NSMutableDictionary *fullBulletin = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *bulletInfo;
        NSString *bulletKey;
        
        if([bulletins count] > 0){
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
        }

        [notificationInfo setValue:notificationArray forKey:@"all"];
        bulletins = nil;
        notificationArray = nil;
        fullBulletin = nil;
        bulletInfo = nil;
    }@catch(NSException* error){
        NSLog(@"FrontPage Error in FPINotifications %@", error);
    }
    return notificationInfo;
}
@end
