//
//  DownLoadViewController.m
//  DownLoadTest
//
//  Created by Mike on 2019/5/15.
//  Copyright © 2019 Quarkdata. All rights reserved.
//

#import "DownLoadViewController.h"
#import "QDNetServerDownLoadTool.h"

@interface DownLoadViewController ()
{
    NSString  *downLoadUrl;
    NSURL *fileUrl;
    NSURLSessionDownloadTask *task;
    BOOL downLoadIng;
}

@end

@implementation DownLoadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"断点续传";
    
    
    self.Progress.progress = 0;
    downLoadUrl = @"https://www.apple.com/105/media/cn/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-cn-20170912_1280x720h.mp4";
    //上面的资源不确定一直都在 自己找一个能下载的资源使用
    NSString *localPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    // 要检查的文件目录
    NSString *filePath = [localPath  stringByAppendingPathComponent:@"iphoneX.mp4"];
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
            NSLog(@"当前的进度 = %f",progress);
            self.progressLabel.text = [NSString stringWithFormat:@"进度:%.3f",progress];
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
            //            NSLog(@"续传的data = %@",resumeData);
            NSLog(@"info = %@",[[NSString alloc]initWithData:resumeData encoding:NSUTF8StringEncoding]);
        }];
    }
    downLoadIng = NO;
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
