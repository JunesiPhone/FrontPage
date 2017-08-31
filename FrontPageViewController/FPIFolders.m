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

+(NSDictionary *)injectFolders{
    NSDictionary * dict = [NSDictionary dictionaryWithContentsOfFile: @"/var/mobile/Library/SpringBoard/IconSupportState.plist"];
    if(!dict){
        dict = [NSDictionary dictionaryWithContentsOfFile: @"/var/mobile/Library/SpringBoard/IconState.plist"];
        if(!dict){
            dict = [NSDictionary dictionary];
        }
    }
    return dict;
}
@end
