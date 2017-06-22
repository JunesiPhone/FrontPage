//
//  FPIApps.h
//  FrontPageViewController
//
//  Created by Edward Winget on 6/4/17.
//  Copyright © 2017 junesiphone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FrontPageViewController.h"

@interface FPIApps : NSObject
+(void)setupNotificationSystem:(id)observer;
+(void)updateAppsWithObserver:(FrontPageViewController *)observer;
@end
