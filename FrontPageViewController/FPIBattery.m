//
//  FPIBattery.m
//  FrontPageViewController
//
//  Created by Edward Winget on 6/4/17.
//  Copyright © 2017 junesiphone. All rights reserved.
//

#import "FPIBattery.h"
#import <objc/runtime.h>

@interface FPIBattery ()

@end

@interface SBUIController : NSObject
+(SBUIController *)sharedInstanceIfExists;
-(BOOL)isOnAC;
-(int)batteryCapacityAsPercentage;
@end

@implementation FPIBattery
+(id)getBatteryInfo:(int) info{
    @try {
        SBUIController *SB = [objc_getClass("SBUIController") sharedInstanceIfExists];
        NSString *chargeText = ([SB isOnAC]) ? @"Charging" : @"Not Charging";
        int battery = [SB batteryCapacityAsPercentage];
        switch (info) {
            case 0:
                return [NSString stringWithFormat:@"%d",battery];
                break;
            case 1:
                return chargeText;
                break;
            case 2:
                return ([SB isOnAC]) ? @"1" : @"0";
                break;
        }
        return 0;
    } @catch (NSException *exception) {
        return 0;
    }
}

+(NSMutableDictionary *)batteryInfo{
    NSMutableDictionary *batteryInfo =[[NSMutableDictionary alloc] init];
    [batteryInfo setValue:[self getBatteryInfo:0] forKey:@"percent"];
    [batteryInfo setValue:[self getBatteryInfo:1] forKey:@"chargetext"];
    [batteryInfo setValue:[self getBatteryInfo:2] forKey:@"chargestate"];
    return batteryInfo;
}
@end
