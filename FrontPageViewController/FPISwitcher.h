//
//  FPISwitcher.h
//  FrontPageViewController
//
//  Created by Edward Winget on 6/4/17.
//  Copyright © 2017 junesiphone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FrontPageViewController.h"

@interface FPISwitcher : NSObject

+(void)setupNotificationSystem:(id)observer;
+(void)updateSwitcherWithObserver:(FrontPageViewController *)observer;

@end
