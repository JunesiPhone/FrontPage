//
//  FPIMusic.m
//  FrontPageViewController
//
//  Created by Edward Winget on 6/4/17.
//  Copyright © 2017 junesiphone. All rights reserved.
//

#import "FPIMusic.h"
#import <objc/runtime.h>

@interface SBApplication
- (id)displayName;
- (id)bundleIdentifier;
- (id)displayIdentifier;
- (_Bool)isWebApplication;
- (_Bool)isInternalApplication;
- (_Bool)isSystemProvisioningApplication;
- (_Bool)isSystemApplication;
- (_Bool)isSpringBoard;
- (id)_appInfo;
-(int)dataUsage;
- (id)applicationWithBundleIdentifier:(id)arg1;
- (void)uninstallApplication:(id)arg1;
@end

@interface SBMediaController
@property(readonly, nonatomic) __weak SBApplication *nowPlayingApplication;
+ (id)sharedInstance;
- (BOOL)stop;
- (BOOL)togglePlayPause;
- (BOOL)pause;
- (BOOL)play;
- (BOOL)isPaused;
- (BOOL)isPlaying;
- (BOOL)changeTrack:(int)arg1;
@end

@interface MPUNowPlayingController : NSObject
+(double)_frontpage_elapsedTime;
+(double)_frontpage_currentDuration;
+(id)_frontpage_currentNowPlayingInfo;
+(id)_frontpage_nowPlayingAppDisplayID;
+(id)_frontpage_albumArt;
@end


@interface FPIMusic ()

@end

@implementation FPIMusic


+(NSMutableDictionary *)musicInfo{
    
    NSMutableDictionary *musicInfo =[[NSMutableDictionary alloc] init];

    NSString *bundle = [[objc_getClass("SBMediaController") sharedInstance] nowPlayingApplication].bundleIdentifier;
    bool playin = [[objc_getClass("SBMediaController") sharedInstance] isPlaying];
    NSString *iconImage = @"null";
    
    if([objc_getClass("MPUNowPlayingController") _frontpage_albumArt]){
        UIImage *uiimage = [objc_getClass("MPUNowPlayingController") _frontpage_albumArt];
        NSData *imageData = UIImagePNGRepresentation(uiimage);
        NSString *encodedString = [imageData base64EncodedStringWithOptions:0];
        iconImage = [NSString stringWithFormat:@"data:image/png;base64,%@", encodedString];
    }
    
    if(iconImage && playin){
        [musicInfo setValue:iconImage forKey:@"albumArt"];
    }else{
        [musicInfo setValue:@"src/images/music.jpg" forKey:@"albumArt"];
    }
    
    NSDictionary *info = [objc_getClass("MPUNowPlayingController") _frontpage_currentNowPlayingInfo];
    NSString *artist = [[NSString stringWithFormat:@"%@",[info objectForKey:@"kMRMediaRemoteNowPlayingInfoArtist"]] stringByReplacingOccurrencesOfString:@"'" withString:@""];
    NSString *album = [[NSString stringWithFormat:@"%@",[info objectForKey:@"kMRMediaRemoteNowPlayingInfoAlbum"]] stringByReplacingOccurrencesOfString:@"'" withString:@""];
    NSString *title = [[NSString stringWithFormat:@"%@",[info objectForKey:@"kMRMediaRemoteNowPlayingInfoTitle"]] stringByReplacingOccurrencesOfString:@"'" withString:@""];
    
    NSMutableString *s = [NSMutableString stringWithString:title];
    [s replaceOccurrencesOfString:@"\'" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"/" withString:@"\\/" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"\n" withString:@"\\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"\b" withString:@"\\b" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"\f" withString:@"\\f" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"\r" withString:@"\\r" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"\t" withString:@"\\t" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
    title = [NSString stringWithString:s];

    
    if(album && playin){
        [musicInfo setValue:artist forKey:@"album"];
    }else{
        [musicInfo setValue:@"No Album" forKey:@"album"];
    }
    
    if(artist && playin){
        [musicInfo setValue:artist forKey:@"artist"];
    }else{
        [musicInfo setValue:@"No Artist" forKey:@"artist"];
    }
    
    if(title && playin){
        [musicInfo setValue:title forKey:@"title"];
    }else{
        [musicInfo setValue:@"No Title" forKey:@"title"];
    }
    [musicInfo setValue:[NSNumber numberWithBool:playin] forKey:@"isPlaying"];
    [musicInfo setValue:bundle forKey:@"musicBundle"];
    return  musicInfo;
}
@end
