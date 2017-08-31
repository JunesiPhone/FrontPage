//
//  FPIAlarm.h
//  FrontPageViewController
//
//  Created by Edward Winget on 6/5/17.
//  Copyright © 2017 junesiphone. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface FPIAlarm : NSObject
+(NSMutableDictionary*)alarmInfo;
@end

@interface SBClockDataProvider
+(id)frontpage_alarms;
@end
