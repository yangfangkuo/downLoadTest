//
//  MenuViewController.m
//  DownLoadTest
//
//  Created by Mike on 2019/5/15.
//  Copyright © 2019 Quarkdata. All rights reserved.
//

#import "MenuViewController.h"
#import "DownLoadViewController.h"
#import "ShowViewController.h"
@interface MenuViewController ()

@end

@implementation MenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"选择方式";
    // Do any additional setup after loading the view from its nib.
}
- (IBAction)goDownload:(id)sender {
    DownLoadViewController *down = [DownLoadViewController new];
    [self.navigationController pushViewController:down animated:YES];
}
- (IBAction)mutiDownload:(id)sender {
    
    ShowViewController *show = [ShowViewController new];
    [self.navigationController pushViewController:show animated:YES];

}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
