//
//  FPIBattery.h
//  FrontPageViewController
//
//  Created by Edward Winget on 6/4/17.
//  Copyright © 2017 junesiphone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FrontPageViewController.h"

@interface FPIBattery : NSObject

+(void)setupNotificationSystem:(id)observer;
+(void)updateBatteryWithObserver:(FrontPageViewController *)observer;

@end
