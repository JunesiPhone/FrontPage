//
//  FPIWeather.h
//  FrontPageViewController
//
//  Created by Edward Winget on 6/4/17.
//  Copyright © 2017 junesiphone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FrontPageViewController.h"

@interface FPIWeather : NSObject
+(void)startWeather: (FrontPageViewController *)observer;


+(int)getIntFromWFTemp: (id) temp withCity: (id)city;
+(NSString*)nameForCondition:(int)condition;
+(int)currentCondition;
+(void) sendDataToWebWithCity: (id)city withObserver: (FrontPageViewController *) observer;
+(void)loadSavedCityWithObserver: (FrontPageViewController *)observer;
+(void)loadLocalCityWithObserver: (FrontPageViewController *)observer;

@end
