//
//  browserVC.h
//  FrontPageViewController
//
//  Created by Edward Winget on 2/20/18.
//  Copyright © 2018 junesiphone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface browserVC : UIViewController <UITableViewDelegate,UITableViewDataSource,UIWebViewDelegate, WKNavigationDelegate, WKUIDelegate>{
}


@property (strong,nonatomic) UITableView *table;
@property (strong,nonatomic) NSArray *content;
@property (nonatomic, assign) WKWebView* theme;


@end
