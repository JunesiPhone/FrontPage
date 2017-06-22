//
//  FPIApp.h
//  FrontPageViewController
//
//  Created by Edward Winget on 6/9/17.
//  Copyright © 2017 junesiphone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FrontPageViewController.h"

@interface FPIApp : NSObject
+(void)setupNotificationSystem:(id)observer;
+(void)updateAppWithObserver:(FrontPageViewController *)observer;
@end
