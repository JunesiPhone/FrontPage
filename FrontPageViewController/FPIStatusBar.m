//
//  FPIStatusBar.m
//  FrontPageViewController
//
//  Created by Edward Winget on 6/4/17.
//  Copyright © 2017 junesiphone. All rights reserved.
//

#import "FPIStatusBar.h"
#import <objc/runtime.h>


@interface FPIStatusBar ()

@end

/*Signal*/
@interface SBTelephonyManager : NSObject
+ (id)sharedTelephonyManager;
- (int)signalStrengthBars;
- (int)signalStrength;
- (id)operatorName;
@end

/* Wifi*/
@interface SBWiFiManager : NSObject
+(id)sharedInstance;
- (int)signalStrengthRSSI;
- (int)signalStrengthBars;
- (id)currentNetworkName;
- (void)setWiFiEnabled:(BOOL)arg1;
@end

/*BlueTooth*/
@interface BluetoothManager : NSObject
+ (id)sharedInstance;
- (BOOL)setEnabled:(BOOL)arg1;
- (BOOL)enabled;
@end

@implementation FPIStatusBar

// --WiFi
// 0 = currentNetworkName, 1 = signalStrengthRSSI, 2 = signalStrengthBars
+(id)getWifiInfo:(int) info{
    SBWiFiManager *WM = [objc_getClass("SBWiFiManager") sharedInstance];
        switch (info) {
            case 0:
                return [WM currentNetworkName];
                break;
            case 1:
                return [NSNumber numberWithInt:[WM signalStrengthRSSI]];
                break;
            case 2:
                return [NSNumber numberWithInt:[WM signalStrengthBars]];
                break;
        }
    return 0;
}

+(void)enableWifi{
    [[objc_getClass("SBWiFiManager") sharedInstance] setWiFiEnabled:YES];
}
+(void)disableWifi{
    [[objc_getClass("SBWiFiManager") sharedInstance] setWiFiEnabled:NO];
}
+(void)enableBluetooth{
    [[objc_getClass("BluetoothManager") sharedInstance] setEnabled:YES];
}
+(void)disableBluetooth{
    [[objc_getClass("BluetoothManager") sharedInstance] setEnabled:NO];
}
// --Signal
// 0 = operatorName, 1 = signalStrength, 2 = signalStrengthBars
+(id)getSignalInfo:(int) info{
    SBTelephonyManager *TM = [objc_getClass("SBTelephonyManager") sharedTelephonyManager];
        switch (info) {
            case 0:
                return [TM operatorName];
                break;
            case 1:
                return 0; //[NSNumber numberWithInt:[TM signalStrength]];
                break;
            case 2:
                return [NSNumber numberWithInt:[TM signalStrengthBars]];
                break;
        }
    return 0;
}


+(NSMutableDictionary *)statusBarInfo{
    BluetoothManager *BM = [objc_getClass("BluetoothManager") sharedInstance];
    bool v = [BM enabled];
    
    NSString *freakinWifi = [NSString stringWithFormat:@"%@",[self getWifiInfo:0]];
    freakinWifi = [[NSString stringWithFormat:@"%@",[self getWifiInfo:0]] stringByReplacingOccurrencesOfString:@"'" withString:@""];
    
    NSString *signalName = [self getSignalInfo:0];
    
    if([freakinWifi isEqualToString:@"(null)"]){
        freakinWifi = @"NA";
    }
    if([signalName isEqualToString:@""]){
        signalName = @"NA";
    }
    
    NSMutableDictionary *statusBarInfo =[[NSMutableDictionary alloc] init];
    [statusBarInfo setValue:freakinWifi forKey:@"wifiName"];
    [statusBarInfo setValue:[self getWifiInfo:1] forKey:@"wifiRSSI"];
    [statusBarInfo setValue:[self getWifiInfo:2] forKey:@"wifiBars"];
    [statusBarInfo setValue:signalName forKey:@"signalName"];
    [statusBarInfo setValue:[self getSignalInfo:1] forKey:@"signalStrength"];
    [statusBarInfo setValue:[self getSignalInfo:2] forKey:@"signalBars"];
    [statusBarInfo setValue:[NSNumber numberWithBool:v] forKey:@"bluetoothEnabled"];
    return statusBarInfo;
}
@end
