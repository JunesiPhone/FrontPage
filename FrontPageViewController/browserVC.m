//
//  broswerVC.m
//  FrontPageViewController
//
//  Created by Edward Winget on 2/20/18.
//  Copyright © 2018 junesiphone. All rights reserved.
//

#import "browserVC.h"
#import "FrontPageViewController.h"

@interface browserVC ()

@end

NSString *oldPart = @"";
NSMutableArray *urlHistory;
int steps = 0;
NSArray * extensionList;

@implementation browserVC

-(void)setArray:(NSString *)part{
    @try{
    NSString* basePath = @"/Library/Themes";
    if(![part isEqualToString:@""]){
        NSString *sep = @"/";
            if([[oldPart substringFromIndex: [oldPart length] - 1] isEqualToString:@"/"]){
                sep = @"";
            }
            oldPart = [NSString stringWithFormat:@"%@%@%@", oldPart, sep, part];
            basePath = [NSString stringWithFormat:@"%@", oldPart];
        }else{
            oldPart = basePath;
        }
        if (![urlHistory containsObject:part]){
           [urlHistory addObject:part];
            steps = steps + 1;
        }
        basePath = [basePath stringByReplacingOccurrencesOfString:@"//" withString:@"/"];
        
    NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:basePath error:Nil];
        
    _content = dirs;
    [self.table reloadData];
    }@catch(NSException *err){
        NSLog(@"FPTest err %@", err);
    }
}

-(void)createTable{
    self.table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.table.delegate = self;
    self.table.dataSource = self;
    [self.view addSubview:self.table];
    [self setArray:@""];
    [self createBackAndClose];
}

-(void) buttonClicked:(UIButton*)sender{
    if((int)sender.tag == 0001){
        @try{
            if((steps - 1) <= 0){
                steps = 0;
                oldPart =[oldPart stringByReplacingOccurrencesOfString:[urlHistory objectAtIndex:steps] withString:@""];
                [self setArray:@""];
                return;
            }else{
                 steps = steps - 1;
                @try{
                oldPart =[oldPart stringByReplacingOccurrencesOfString:[urlHistory objectAtIndex:steps] withString:@""];
                oldPart =[oldPart stringByReplacingOccurrencesOfString:[urlHistory objectAtIndex:steps -1] withString:@""];
                }@catch(NSException *error){
                    NSLog(@"FPTest error %@", error);
                }
                @try{
                    [urlHistory removeObjectAtIndex:steps];
                }@catch(NSException *error){
                    NSLog(@"FPTest error2 %@", error);
                }
                [self setArray:[urlHistory objectAtIndex:steps - 1]];
            }
        }@catch(NSException *err){
            NSLog(@"FPTest %@", err);
        }
    }
    if((int)sender.tag == 0002){
        NSLog(@"FPTest EXIT");
        [self dismissViewControllerAnimated:NO completion:nil];
        NSString* func = [NSString stringWithFormat:@"selectedImageFromFPCancelled()"];
        [_theme evaluateJavaScript:func completionHandler:^(id object, NSError *error) {
        }];
    }
}

-(void)createBackAndClose{
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 10, 100)];
    UIBarButtonItem *button1 = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleDone target:self action:@selector(buttonClicked:)];
    button1.tag = 0001;
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *button2=[[UIBarButtonItem alloc]initWithTitle:@"Exit" style:UIBarButtonItemStyleDone target:self action:@selector(buttonClicked:)];
    button2.tag = 0002;
    [toolbar setItems:[[NSArray alloc] initWithObjects:button1,spacer,button2,nil]];
    [toolbar setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin];
    
    self.table.tableHeaderView = toolbar;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    extensionList = [NSArray arrayWithObjects:@"plist", @"js", @"html", @"gif", @"bmp", @"jpg", @"css", @"bundle", @"txt", @"ttf", @"otf", @"mp3", @"wav", @"mov", @"ogg", @"deb", @"zip", @"7z" ,@"tar.gz", @"bin", @"dmg", @"db", @"bin",@"psd",@"svg",@"ico",@"tiff", @"htm",@"php",@"bak", @"mp4",@"h264",@"avi" , nil];
    urlHistory = [[NSMutableArray alloc] init];
    [self createTable];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _content.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentifier = @"cellIdentifier";
    UITableViewCell *cell = [self.table dequeueReusableCellWithIdentifier:cellIdentifier];
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    if([[_content objectAtIndex:indexPath.row] containsString:@".png"]){
        NSString *path = [NSString stringWithFormat:@"file://%@/%@", oldPart, [_content objectAtIndex:indexPath.row]];
        NSString* urlEsc = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSData * imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlEsc]];
        UIImage *image = [UIImage imageWithData:imageData];
        cell.imageView.image = image;
    }else{
        cell.imageView.image = nil;
    }
    cell.textLabel.text =  [_content objectAtIndex:indexPath.row];
    if([extensionList containsObject:[[_content objectAtIndex:indexPath.row]pathExtension]]){
        cell.userInteractionEnabled = NO;
        cell.textLabel.alpha = 0.2;
    }else{
        cell.textLabel.alpha = 1;
        cell.userInteractionEnabled = YES;
    }
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if([[_content objectAtIndex:indexPath.row] containsString:@".png"]){
        NSString *path = [NSString stringWithFormat:@"file://%@/%@", oldPart, [_content objectAtIndex:indexPath.row]];
        NSString* urlEsc = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString* func = [NSString stringWithFormat:@"selectedImageFromFP('%@')", urlEsc];
        [_theme evaluateJavaScript:func completionHandler:^(id object, NSError *error) {
        }];
        [self dismissViewControllerAnimated:NO completion:nil];
    }else{
       [self setArray:[_content objectAtIndex:indexPath.row]];
    }
}
@end






