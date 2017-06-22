//
//  FPIMemory.h
//  FrontPageViewController
//
//  Created by Edward Winget on 6/19/17.
//  Copyright © 2017 junesiphone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FrontPageViewController.h"

@interface FPIMemory : NSObject
+(void)loadMemoryWithObserver: (FrontPageViewController *) observer;
+(void)updateMemoryWithObserver:(FrontPageViewController *)observer;
@end
