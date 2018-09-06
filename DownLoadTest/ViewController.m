//
//  ViewController.m
//  DownLoadTest
//
//  Created by Mike on 2017/12/5.
//  Copyright © 2017年 Quarkdata. All rights reserved.
//

#import "ViewController.h"
#import "QDNetServerDownLoadTool.h"
@interface ViewController ()
{
    NSString  *downLoadUrl;
    NSURL *fileUrl;
    NSURLSessionDownloadTask *task;
    BOOL downLoadIng;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.Progress.progress = 0;
    downLoadUrl = @"https://www.apple.com/105/media/cn/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-cn-20170912_1280x720h.mp4";
    //上面的资源不确定一直都在 自己找一个能下载的资源使用  
    NSString *localPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    // 要检查的文件目录
    NSString *filePath = [localPath  stringByAppendingPathComponent:@"Tiger_Trade_latest.dmg"];
    fileUrl = [NSURL fileURLWithPath:filePath isDirectory:NO];
}
- (IBAction)startNew:(id)sender {
    
    if (downLoadIng) {
        return;
    }
    downLoadIng = YES;
    NSURLSessionDownloadTask *tempTask = [[QDNetServerDownLoadTool sharedTool]AFDownLoadFileWithUrl:downLoadUrl progress:^(CGFloat progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.Progress.progress = progress;
        });
    } fileLocalUrl:fileUrl success:^(NSURL *fileUrlPath, NSURLResponse *response) {
        NSLog(@"下载成功 下载的文档路径是 %@, ",fileUrlPath);
    } failure:^(NSError *error, NSInteger statusCode) {
        NSLog(@"下载失败,下载的data被downLoad工具处理了 ");

    }];
    task = tempTask;
}

- (IBAction)pause:(id)sender {
    //可以在这里存储resumeData ,也可以去QDNetServerDownLoadTool 里面 根据那个通知去处理 都有回调的
    if (downLoadIng) {
        [task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            
        }];
    }
    downLoadIng = NO;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
