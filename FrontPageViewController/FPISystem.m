//
//  FPISystem.m
//  FrontPageViewController
//
//  Created by Edward Winget on 6/4/17.
//  Copyright © 2017 junesiphone. All rights reserved.
//
#import "FPISystem.h"
#import <sys/utsname.h>
#import <EventKit/EventKit.h>

#define deviceVersion [[[UIDevice currentDevice] systemVersion] floatValue]

@implementation FPISystem


+ (NSString*) deviceName{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString* code = [NSString stringWithCString:systemInfo.machine
                                        encoding:NSUTF8StringEncoding];
    
    static NSDictionary* deviceNamesByCode = nil;
    if (!deviceNamesByCode) {
        
        deviceNamesByCode = @{@"i386"      :@"Simulator",
                              @"x86_64"    :@"Simulator",
                              @"iPod1,1"   :@"iPod Touch",        // (Original)
                              @"iPod2,1"   :@"iPod Touch",        // (Second Generation)
                              @"iPod3,1"   :@"iPod Touch",        // (Third Generation)
                              @"iPod4,1"   :@"iPod Touch",        // (Fourth Generation)
                              @"iPod7,1"   :@"iPod Touch",        // (6th Generation)
                              @"iPhone1,1" :@"iPhone",            // (Original)
                              @"iPhone1,2" :@"iPhone",            // (3G)
                              @"iPhone2,1" :@"iPhone",            // (3GS)
                              @"iPad1,1"   :@"iPad",              // (Original)
                              @"iPad2,1"   :@"iPad 2",            //
                              @"iPad3,1"   :@"iPad",              // (3rd Generation)
                              @"iPhone3,1" :@"iPhone 4",          // (GSM)
                              @"iPhone3,3" :@"iPhone 4",          // (CDMA/Verizon/Sprint)
                              @"iPhone4,1" :@"iPhone 4S",         //
                              @"iPhone5,1" :@"iPhone 5",          // (model A1428, AT&T/Canada)
                              @"iPhone5,2" :@"iPhone 5",          // (model A1429, everything else)
                              @"iPad3,4"   :@"iPad",              // (4th Generation)
                              @"iPad2,5"   :@"iPad Mini",         // (Original)
                              @"iPhone5,3" :@"iPhone 5c",         // (model A1456, A1532 | GSM)
                              @"iPhone5,4" :@"iPhone 5c",         // (model A1507, A1516, A1526 (China), A1529 | Global)
                              @"iPhone6,1" :@"iPhone 5s",         // (model A1433, A1533 | GSM)
                              @"iPhone6,2" :@"iPhone 5s",         // (model A1457, A1518, A1528 (China), A1530 | Global)
                              @"iPhone7,1" :@"iPhone 6 Plus",     //
                              @"iPhone7,2" :@"iPhone 6",          //
                              @"iPhone8,1" :@"iPhone 6S",         //
                              @"iPhone8,2" :@"iPhone 6S Plus",    //
                              @"iPhone8,4" :@"iPhone SE",         //
                              @"iPhone9,1" :@"iPhone 7",          //
                              @"iPhone9,3" :@"iPhone 7",          //
                              @"iPhone9,2" :@"iPhone 7 Plus",     //
                              @"iPhone9,4" :@"iPhone 7 Plus",     //
                              
                              @"iPad4,1"   :@"iPad Air",          // 5th Generation iPad (iPad Air) - Wifi
                              @"iPad4,2"   :@"iPad Air",          // 5th Generation iPad (iPad Air) - Cellular
                              @"iPad4,4"   :@"iPad Mini",         // (2nd Generation iPad Mini - Wifi)
                              @"iPad4,5"   :@"iPad Mini",         // (2nd Generation iPad Mini - Cellular)
                              @"iPad4,7"   :@"iPad Mini",         // (3rd Generation iPad Mini - Wifi (model A1599))
                              @"iPad6,7"   :@"iPad Pro (12.9\")", // iPad Pro 12.9 inches - (model A1584)
                              @"iPad6,8"   :@"iPad Pro (12.9\")", // iPad Pro 12.9 inches - (model A1652)
                              @"iPad6,3"   :@"iPad Pro (9.7\")",  // iPad Pro 9.7 inches - (model A1673)
                              @"iPad6,4"   :@"iPad Pro (9.7\")"   // iPad Pro 9.7 inches - (models A1674 and A1675)
                              };
    }
    
    NSString* deviceName = [deviceNamesByCode objectForKey:code];
    
    if (!deviceName) {
        // Not found on database. At least guess main device type from string contents:
        if ([code rangeOfString:@"iPod"].location != NSNotFound) {
            deviceName = @"iPod Touch";
        }
        else if([code rangeOfString:@"iPad"].location != NSNotFound) {
            deviceName = @"iPad";
        }
        else if([code rangeOfString:@"iPhone"].location != NSNotFound){
            deviceName = @"iPhone";
        }
        else {
            deviceName = @"Unknown";
        }
    }
    
    return deviceName;
}

+(id)getDeviceInfo:(int) info{
        
        UIDevice *currentDevice = [UIDevice currentDevice];
        switch (info) {
            case 0:
                return [currentDevice name];
                break;
            case 1:
                return [currentDevice systemVersion];
                break;
        }
        return 0;
}

+(NSString *)addBackslashes:(NSString *)string {
    /*
     
     Escape characters so we can pass a string via stringByEvaluatingJavaScriptFromString
     
     */
    
    // Escape the characters
    string = [string stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    string = [string stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    string = [string stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
    string = [string stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    string = [string stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    string = [string stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
    return string;
}

+(NSDictionary *)systemInfo{
    NSMutableDictionary *systemInfo =[[NSMutableDictionary alloc] init];
    NSString *formatStringForHours = [NSDateFormatter dateFormatFromTemplate:@"j" options:0 locale:[NSLocale currentLocale]];
    NSRange containsA = [formatStringForHours rangeOfString:@"a"];
    BOOL hasAMPM = containsA.location != NSNotFound;
    NSString *twentyFour;
    
    if(hasAMPM){
        twentyFour = @"no";
    }else{
        twentyFour = @"yes";
    }
    
    //Version 8.3 (Build 12F70)
    NSString *firmwareBuild = [NSProcessInfo processInfo].operatingSystemVersionString;
    //8.3
    NSString *firmware = [UIDevice currentDevice].systemVersion;
    //iOS
    NSString *systemname = [UIDevice currentDevice].systemName;
    //iPhone
    NSString *deviceType = [UIDevice currentDevice].model;
    //iPhone6
    NSString *model = [FPISystem deviceName];
    model = [[NSString stringWithFormat:@"%@",model] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    model = [[NSString stringWithFormat:@"%@",model] stringByReplacingOccurrencesOfString:@"\\" withString:@""];
    //fake it
    NSString *serial = @"JKDNSEOGME87JS7DL";
    //DeviceName
    NSString *freakinName = [NSString stringWithFormat:@"%@",[self getDeviceInfo:0]];
    freakinName = [[NSString stringWithFormat:@"%@",[self getDeviceInfo:0]] stringByReplacingOccurrencesOfString:@"'" withString:@""];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDictionary *attr = [fm attributesOfFileSystemForPath:@"/" error:nil];
    NSDictionary *attr2 = [fm attributesOfFileSystemForPath:@"/var/mobile" error:nil];
    
    float totalsizeGb = [[attr objectForKey:NSFileSystemSize]floatValue] / 1000000000;
    float totalsizeGb2 = [[attr2 objectForKey:NSFileSystemSize]floatValue] / 1000000000;
    
    float freesizeGb = [[attr objectForKey:NSFileSystemFreeSize]floatValue] / 1000000000;
    float freesizeGb2 = [[attr2 objectForKey:NSFileSystemFreeSize]floatValue] / 1000000000;
    
    float totalGB = totalsizeGb + totalsizeGb2;
    float freeGB = freesizeGb + freesizeGb2;
    
    
    if(deviceVersion >= 11){
        totalsizeGb = totalsizeGb / 2;
        totalsizeGb2 = totalsizeGb2 / 2;
        freesizeGb = freesizeGb / 2;
        freesizeGb2 = freesizeGb2 / 2;
        totalGB = totalGB / 2;
        freeGB = freeGB / 2;
    }
    EKEventStore *store;
    
    if(!store){
        store = [[EKEventStore alloc] init];
    }
    
    NSDate *start = [NSDate date];
    NSDate *end = [NSDate dateWithTimeInterval:25920000 sinceDate:start];
    

    NSPredicate* predicate = [store predicateForEventsWithStartDate:start endDate:end calendars:nil];
    NSArray *events = [store eventsMatchingPredicate:predicate];
   
    NSMutableDictionary *dateDict;
    NSMutableArray *dateDictArray = [[NSMutableArray alloc] init];
    NSString *dupeCatch;
    
    for (EKEvent *object in events) {
        NSString* info = [NSString stringWithFormat:@"%@", object.title];
        NSCharacterSet *cs = [NSCharacterSet characterSetWithCharactersInString:@"!~`@#$%^&*-+();:=_{}[],.<>?\\/|\"\'"];
        
        NSString *filtered = [[info componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
        NSMutableString *finalString = [NSMutableString stringWithString:filtered];
        [finalString replaceOccurrencesOfString:@"gmail" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [finalString length])];
        [finalString replaceOccurrencesOfString:@"coms" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [finalString length])];
        [finalString replaceOccurrencesOfString:@"yahoo" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [finalString length])];
        [finalString replaceOccurrencesOfString:@"couk" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [finalString length])];
        filtered = [NSString stringWithString:finalString];
        
        if (!([dupeCatch rangeOfString:filtered].location == NSNotFound)) {
            dateDict = [[NSMutableDictionary alloc]init];
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"MM-dd-YYYY"];
            NSString* date = [dateFormat stringFromDate:object.startDate];
            [dateDict setValue:[self addBackslashes:date] forKey:@"date"];
            
            [dateDict setValue:filtered forKey:@"title"];
            [dateDictArray addObject:dateDict];
        }
        dupeCatch = [NSString stringWithFormat:@"%@", filtered];
    }


    
    [systemInfo setValue:twentyFour forKey:@"twentyfour"];
    [systemInfo setValue:freakinName forKey:@"deviceName"];
    [systemInfo setValue:[self getDeviceInfo:1] forKey:@"systemVersion"];
    [systemInfo setValue:firmwareBuild forKey:@"firmwareBuild"];
    [systemInfo setValue:firmware forKey:@"firmware"];
    [systemInfo setValue:systemname forKey:@"systemName"];
    [systemInfo setValue:serial forKey:@"serial"];
    [systemInfo setValue:deviceType forKey:@"deviceType"];
    [systemInfo setValue:freakinName forKey:@"name"];
    [systemInfo setValue:model forKey:@"model"];
    [systemInfo setValue:dateDictArray forKey:@"events"];
    [systemInfo setValue:[NSNumber numberWithFloat:totalsizeGb] forKey:@"rootStorage"];
    [systemInfo setValue:[NSNumber numberWithFloat:freesizeGb] forKey:@"rootfreeStorage"];
    [systemInfo setValue:[NSNumber numberWithFloat:totalsizeGb2] forKey:@"mobileStorage"];
    [systemInfo setValue:[NSNumber numberWithFloat:freesizeGb2] forKey:@"mobilefreeStorage"];
    [systemInfo setValue:[NSNumber numberWithFloat:totalGB] forKey:@"totalStorage"];
    [systemInfo setValue:[NSNumber numberWithFloat:freeGB] forKey:@"freeStorage"];
    return systemInfo;
}
@end
