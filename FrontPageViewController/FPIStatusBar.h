//
//  FPIStatusBar.h
//  FrontPageViewController
//
//  Created by Edward Winget on 6/4/17.
//  Copyright © 2017 junesiphone. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface FPIStatusBar : NSObject

+(NSMutableDictionary *) statusBarInfo;
+(void)enableWifi;
+(void)disableWifi;
+(void)enableBluetooth;
+(void)disableBluetooth;
@end
