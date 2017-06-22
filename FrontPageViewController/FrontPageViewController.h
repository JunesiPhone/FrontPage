//
//  FrontPageViewController.h
//  FrontPageViewController
//
//  Created by Edward Winget on 5/21/17.
//  Copyright © 2017 junesiphone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>



@interface FrontPageViewController : UIViewController <UIWebViewDelegate, UIGestureRecognizerDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout, UIAlertViewDelegate, CLLocationManagerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>{
    UIWebView *_themeView;
    UIView *_themeSetupView;
    UICollectionView *_collectionView;
    NSMutableArray *_themeArray;
    NSMutableDictionary *_frontPageSettings;
    
    NSString *_plistPath;
    int notifyToken;
    BOOL isVisible;
    BOOL isInApp;
    BOOL themeSelected;
    
    
    
 
    
}
-(void)setStatusBarPending:(BOOL)pending;
-(void)setBatteryPending:(BOOL)pending;
-(BOOL)getStatusBarPending;
-(BOOL)getBatteryPending;
-(BOOL)getSystemPending;
-(void)setSystemPending:(BOOL)pending;
-(BOOL)getSwitcherPending;
-(void)setSwitcherPending:(BOOL)pending;
-(BOOL)getAppsPending;
-(void)setAppsPending:(BOOL)pending;
-(BOOL)getMusicPending;
-(void)setMusicPending:(BOOL)pending;
-(BOOL)getNotificationsPending;
-(void)setNotificationsPending:(BOOL)pending;
-(BOOL)getAlarmPending;
-(void)setAlarmPending:(BOOL)pending;

-(void)checkPendingNotifications;
-(void)checkIfAppIsCovering;
-(BOOL)canReloadData;
-(BOOL)checkisInApp;
-(void)convertDictToJSON:(NSDictionary *) dict withName:(NSString *) name;
-(void)callJSFunction: (NSString *)function;
@end

@interface BBServer
+(instancetype)frontpage_sharedInstance;
+(id)frontpage_ids;
- (void)publishBulletin:(id)arg1 destinations:(unsigned long long)arg2 alwaysToLockScreen:(_Bool)arg3;
- (id)_allBulletinsForSectionID:(id)arg1;

- (id)allBulletinIDsForSectionID:(id)arg1;
- (id)noticesBulletinIDsForSectionID:(id)arg1;
- (id)bulletinIDsForSectionID:(id)arg1 inFeed:(unsigned long long)arg2;
@end



@interface BBBulletin : NSObject
@property(copy) NSString *sectionID;
@property(copy) NSString *bulletinID;
@property(copy) NSDictionary *context;
@property(copy) NSString *section;
@property(copy) NSString *message;
@property(copy) NSString *subtitle;
@property(copy) NSString *title;
@end

