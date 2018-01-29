//
//  FPIWeather.m
//  FrontPageViewController
//
//  Created by Edward Winget on 6/4/17.
//  Copyright © 2017 junesiphone. All rights reserved.
//

#import "FPIWeather.h"
#import <objc/runtime.h>
#import "Weather.h"
//#import <CydiaSubstrate/CydiaSubstrate.h>

#define deviceVersion [[[UIDevice currentDevice] systemVersion] floatValue]

City * city;


@interface WFTemperature : NSObject
@property (nonatomic) double celsius;
@property (nonatomic) double fahrenheit;
@end

@interface CLApproved : CLLocationManager
+ (int)authorizationStatusForBundleIdentifier:(id)arg1;
@end

@interface FPIWeather ()
@end

@implementation FPIWeather

+(int)getIntFromWFTemp: (WFTemperature *) temp withCity: (City *)city{
    if(deviceVersion >= 10.0f){
        return [[objc_getClass("WeatherPreferences") sharedPreferences] isCelsius] ? (int)temp.celsius : (int)temp.fahrenheit;
    }else{
        NSString *tempInt =  [NSString stringWithFormat:@"%@", temp];
        int temp = (int)[tempInt integerValue];
        if (![[objc_getClass("WeatherPreferences") sharedPreferences] isCelsius]){
            temp = ((temp * 9)/5) + 32;
        }
        return temp;
    }
}

+(int)getIntFromTemp:(id)tempID{
    NSString *tempInt =  [NSString stringWithFormat:@"%@", tempID];
    int temp = (int)[tempInt integerValue];

    if (![[objc_getClass("WeatherPreferences") sharedPreferences] isCelsius]){
        temp = ((temp * 9)/5) + 32;
    }
    return temp;
}

//InfoStats
//https://github.com/Matchstic/InfoStats2/blob/master/InfoStats2/IS2WeatherProvider.m

+(int)currentCondition {
    int cond = 0;
    int code = (int)city.conditionCode;
    
    if (deviceVersion >= 7.0f)
        cond =  code;
    else
        cond = city.bigIcon;
    
    if (cond == 32 && ![city isDay]) {
        cond = 31;
    }
    
    if (cond < 0) {
        cond = 0;
    }
    
    return cond;
}

// Thanks to Andrew Wiik & Matchstic for this function.

+(NSString*)nameForCondition:(int)condition {
//    MSImageRef weather = MSGetImageByName("/System/Library/PrivateFrameworks/Weather.framework/Weather");
//
//    CFStringRef *_weatherDescription = (CFStringRef*)MSFindSymbol(weather, "_WeatherDescription") + condition;
//    NSString *cond = (__bridge id)*_weatherDescription;
//
//    return [[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/Weather.framework"] localizedStringForKey:cond value:@"" table:@"WeatherFrameworkLocalizableStrings"];
    return @"test";
}

+(void) sendDataToWebWithCity: (City *) city withObserver: (FrontPageViewController *) observer{
    @try {
        if([city.dayForecasts count] == 0){
            
        }else{
            NSMutableDictionary *weatherInfo =[[NSMutableDictionary alloc] init];
            DayForecast * days = city.dayForecasts[0];
            NSString *naturalCondition;
            NSString *conditionString;
            
            int low;
            int high;
            int temp;
            int feelslike;
            
            if(deviceVersion >= 10.0f){
                low = [self getIntFromWFTemp:[days valueForKey:@"low"] withCity:city];
                high = [self getIntFromWFTemp:[days valueForKey:@"high"]withCity:city];
                temp = [self getIntFromWFTemp:[city valueForKey:@"temperature"]withCity:city];
                feelslike = [self getIntFromWFTemp:[city valueForKey:@"feelsLike"]withCity:city];
            }else{
                low = [self getIntFromTemp:[days valueForKey:@"low"]];
                high = [self getIntFromTemp:[days valueForKey:@"high"]];
                temp = [self getIntFromTemp:[city valueForKey:@"temperature"]];
                feelslike = [self getIntFromTemp:[city valueForKey:@"feelsLike"]];
            }
            
            
            
            NSMutableDictionary *dayForecasts;
            NSMutableArray *fcastArray = [[NSMutableArray alloc] init];
            
            for (DayForecast *day in city.dayForecasts) {
                
                int lowForcast;
                int highForecast;
                
                if(deviceVersion >= 10.0f){
                    lowForcast = [self getIntFromWFTemp:[day valueForKey:@"low"]withCity:city];
                    highForecast = [self getIntFromWFTemp:[day valueForKey:@"high"]withCity:city];
                }else{
                    lowForcast = [self getIntFromTemp:[day valueForKey:@"low"]];
                    highForecast = [self getIntFromTemp:[day valueForKey:@"high"]];
                }
                
                NSString *icon = [NSString stringWithFormat:@"%llu",day.icon];
                
                dayForecasts = [[NSMutableDictionary alloc] init];
                [dayForecasts setValue:[NSNumber numberWithInt:lowForcast] forKey:@"low"];
                [dayForecasts setValue:[NSNumber numberWithInt:highForecast] forKey:@"high"];
                [dayForecasts setValue:[NSString stringWithFormat:@"%llu",day.dayNumber] forKey:@"dayNumber"];
                [dayForecasts setValue:[NSString stringWithFormat:@"%llu",day.dayOfWeek] forKey:@"dayOfWeek"];
                [dayForecasts setValue:icon forKey:@"icon"];
                [fcastArray addObject:dayForecasts];
                
            }
            
            conditionString = [self nameForCondition:[self currentCondition]];
            
            if ([city respondsToSelector:@selector(naturalLanguageDescription)]) {
                naturalCondition = [city naturalLanguageDescription];
            } else {
                naturalCondition = @"No condition";
            }
            bool celsius =  [[objc_getClass("WeatherPreferences") sharedPreferences] isCelsius];
            
            NSMutableString *s = [NSMutableString stringWithString:naturalCondition];
            [s replaceOccurrencesOfString:@"\'" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
            [s replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
            [s replaceOccurrencesOfString:@"/" withString:@"\\/" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
            [s replaceOccurrencesOfString:@"\n" withString:@"\\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
            [s replaceOccurrencesOfString:@"\b" withString:@"\\b" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
            [s replaceOccurrencesOfString:@"\f" withString:@"\\f" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
            [s replaceOccurrencesOfString:@"\r" withString:@"\\r" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
            [s replaceOccurrencesOfString:@"\t" withString:@"\\t" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
            naturalCondition = [NSString stringWithString:s];
        
            
            [weatherInfo setValue:city.name forKey:@"city"];
            [weatherInfo setValue:naturalCondition forKey:@"naturalCondition"];
            [weatherInfo setValue:conditionString forKey:@"condition"];
            [weatherInfo setValue:city.locationID forKey:@"latlong"];
            [weatherInfo setValue:[NSNumber numberWithInt:temp] forKey:@"temperature"];
            [weatherInfo setValue:[NSString stringWithFormat:@"%llu",city.conditionCode] forKey:@"conditionCode"];
            [weatherInfo setValue:[NSString stringWithFormat:@"%@",city.updateTimeString] forKey:@"updateTimeString"];
            [weatherInfo setValue:[NSString stringWithFormat:@"%f",city.humidity] forKey:@"humidity"];
            [weatherInfo setValue:[NSString stringWithFormat:@"%f",city.dewPoint] forKey:@"dewPoint"];
            [weatherInfo setValue:[NSString stringWithFormat:@"%f",city.windChill] forKey:@"windChill"];
            [weatherInfo setValue:[NSNumber numberWithInt:feelslike] forKey:@"feelsLike"];
            [weatherInfo setValue:[NSString stringWithFormat:@"%f",city.windDirection] forKey:@"windDirection"];
            [weatherInfo setValue:[NSString stringWithFormat:@"%f",city.windSpeed] forKey:@"windSpeed"];
            [weatherInfo setValue:[NSString stringWithFormat:@"%f",city.visibility] forKey:@"visibility"];
            [weatherInfo setValue:[NSString stringWithFormat:@"%llu",city.sunsetTime] forKey:@"sunsetTime"];
            [weatherInfo setValue:[NSString stringWithFormat:@"%llu",city.sunriseTime] forKey:@"sunriseTime"];
            [weatherInfo setValue:[NSString stringWithFormat:@"%d", city.precipitationForecast] forKey:@"precipitationForecast"];
            [weatherInfo setValue:[NSNumber numberWithInt:low] forKey:@"low"];
            [weatherInfo setValue:[NSNumber numberWithInt:high] forKey:@"high"];
            [weatherInfo setValue:[NSNumber numberWithBool:celsius] forKey:@"celsius"];
            
            if([[city hourlyForecasts] count] > 0){
                HourlyForecast* precip = [city hourlyForecasts][0];
                [weatherInfo setValue:[NSString stringWithFormat:@"%d", (int)roundf(precip.percentPrecipitation)] forKey:@"chanceofrain"];
            }
            
            [weatherInfo setValue:fcastArray forKey:@"dayForecasts"];
            [observer convertDictToJSON:weatherInfo withName:@"weather"];
            [observer callJSFunction:@"loadWeather()"];
            weatherInfo = nil;
        }
        
    } @catch (NSException *exception) {
        NSLog(@"FrontWeather - Error %@", exception);
    }
}

+(void)loadSavedCityWithObserver: (FrontPageViewController *)observer{
    
    if([[[objc_getClass("WeatherPreferences") sharedPreferences]loadSavedCities] count] > 0){
        CLLocation* location;
        City *currentCity = [[objc_getClass("WeatherPreferences") sharedPreferences]loadSavedCities][0];
        if(currentCity.locationID){
            NSArray *locationArray = [currentCity.locationID componentsSeparatedByString:@","];
            if([locationArray count] > 0){
                double latitude = [locationArray[0] doubleValue];
                double longitude = [locationArray[1] doubleValue];
                location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude)
                                               altitude:0
                                     horizontalAccuracy:0
                                       verticalAccuracy:0
                                              timestamp:[NSDate date]];
            }
        }
        if(deviceVersion < 10.0f){
            [[objc_getClass("TWCLocationUpdater") sharedLocationUpdater] updateWeatherForLocation:location city:currentCity withCompletionHandler:^{
                [self sendDataToWebWithCity: currentCity withObserver:observer];
            }];
        }else{
            [[objc_getClass("TWCLocationUpdater") sharedLocationUpdater] _updateWeatherForLocation:location city:currentCity completionHandler:^{
                [self sendDataToWebWithCity: currentCity withObserver:observer];
            }];
        }
    }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"FrontPage Request"
                                                        message:@"You do not have a location set in the weather app. Please set one."
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

+(void)loadLocalCityWithObserver: (FrontPageViewController *)observer{
    
    City *currentCity = nil;
    currentCity = [[objc_getClass("WeatherPreferences") sharedPreferences]localWeatherCity];
    
    if(!currentCity){
        if([[[objc_getClass("WeatherPreferences") sharedPreferences]loadSavedCities] count] > 0){
            currentCity = [[objc_getClass("WeatherPreferences") sharedPreferences]loadSavedCities][0];
        }else{
            /*
             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"FrontPage Request"
                                                            message:@"You do not have a location set in the weather app. Please set one."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
             */
        }
    }
        [self sendDataToWebWithCity:currentCity withObserver:observer]; //faster loading
    
        CLLocationManager *CLM = [[CLLocationManager alloc] init];
        CLM.delegate = observer;
        WeatherLocationManager* WLM = [objc_getClass("WeatherLocationManager")sharedWeatherLocationManager];
        WLM.delegate = observer;
        if(deviceVersion >= 8.3f){
            if([[objc_getClass("WeatherLocationManager")sharedWeatherLocationManager] respondsToSelector:@selector(setLocationTrackingReady:activelyTracking:watchKitExtension:)]){
                    [WLM setLocationTrackingReady:YES activelyTracking:NO watchKitExtension:NO];
            }

        }
        [WLM setLocationTrackingActive:YES];
        [[objc_getClass("WeatherPreferences") sharedPreferences] setLocalWeatherEnabled:YES];
        
        if(deviceVersion < 10.0f){
            if([[objc_getClass("TWCLocationUpdater") sharedLocationUpdater] respondsToSelector:@selector(updateWeatherForLocation:city:withCompletionHandler:)]){
                
                [[objc_getClass("TWCLocationUpdater") sharedLocationUpdater] updateWeatherForLocation:[WLM location] city:currentCity withCompletionHandler:^{
                    [self sendDataToWebWithCity: currentCity withObserver:observer];
                }];
                
            }
        }else{
            [[objc_getClass("TWCLocationUpdater") sharedLocationUpdater] _updateWeatherForLocation:[WLM location] city:currentCity completionHandler:^{
                [self sendDataToWebWithCity: currentCity withObserver:observer];
            }];
        }
    [WLM setLocationTrackingActive:NO];
    WLM = nil;
}


/* startWeather
 
    is called by FrontPageViewController on a 10 minute interval (or manually by user)
    check to see if locationServices is on or off.
    check if weather is allowing location.
    call either loadSaved or loadLocal City depending on checks
 
 */

+(void)startWeather: (FrontPageViewController *) observer{
    if(![CLLocationManager locationServicesEnabled] || [objc_getClass("CLLocationManager") authorizationStatusForBundleIdentifier:@"com.apple.weather"] == 2){
        [self loadSavedCityWithObserver:observer];
    }else{
        [self loadLocalCityWithObserver:observer];
    }
    
}


@end
