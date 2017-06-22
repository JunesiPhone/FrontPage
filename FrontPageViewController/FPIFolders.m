//
//  FPIFolders.m
//  FrontPageViewController
//
//  Created by Edward Winget on 6/4/17.
//  Copyright © 2017 junesiphone. All rights reserved.
//

#import "FPIFolders.h"

@interface FPIFolders ()

@end

@implementation FPIFolders

+(void)loadFoldersWithObserver: (FrontPageViewController *) observer{
    NSDictionary * dict = [NSDictionary dictionaryWithContentsOfFile: @"/var/mobile/Library/SpringBoard/IconSupportState.plist"];
    
    if(dict){
        [observer convertDictToJSON:dict withName:@"folderplist"];
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.4);
        dispatch_after(delay, dispatch_get_main_queue(), ^(void){
            [observer callJSFunction:@"loadFolders()"];
        });
    }else{
        dict = [NSDictionary dictionaryWithContentsOfFile: @"/var/mobile/Library/SpringBoard/IconState.plist"];
        if(dict){
            [observer convertDictToJSON:dict withName:@"folderplist"];
            dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.4);
            dispatch_after(delay, dispatch_get_main_queue(), ^(void){
                [observer callJSFunction:@"loadFolders()"];
            });
        }
    }
}
@end
