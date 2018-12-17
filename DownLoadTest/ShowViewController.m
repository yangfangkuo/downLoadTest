//
//  ShowViewController.m
//  DownLoadTest
//
//  Created by Mike on 2018/12/17.
//  Copyright © 2018 Quarkdata. All rights reserved.
//

#import "ShowViewController.h"
#import "Test.h"
#import "QDNetServerDownLoadTool.h"
@interface ShowViewController ()
{
    NSString  *downLoadUrl;
    NSURL *fileUrl;
    NSURLSessionDownloadTask *task;
    BOOL downLoadIng;
    NSArray *urlArr ;
    NSMutableArray *localArray ;
    
}

@end

@implementation ShowViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //NSURLSession高并发测试
    self.view.backgroundColor = [UIColor whiteColor];
    downLoadUrl = @"https://www.apple.com/105/media/cn/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-cn-20170912_1280x720h.mp4";

    urlArr = [NSMutableArray arrayWithObjects:downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,downLoadUrl,nil];
    NSString *localPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    // 要检查的文件目录
    for (int i = 0; i < urlArr.count; i++) {
        NSString *filePath = [localPath  stringByAppendingPathComponent:[NSString stringWithFormat:@"%d11123.mp4",i]];
        NSURL *url = [NSURL fileURLWithPath:filePath isDirectory:NO];
//        [self testdownLoadWithTask:urlArr[i] FileUrl:url];
        [self downLoadWithTask:urlArr[i] FileUrl:url];
        
    }
    
    // Do any additional setup after loading the view.
}
- (void)testdownLoadWithTask:(NSString *)url FileUrl:(NSURL *)fileuUrl{
    
    
    __block  NSURLSessionDownloadTask *tempTask;
    
    tempTask= [[Test sharedTool]AFDownLoadFileWithUrl:url progress:^(CGFloat progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
        
            NSString *str = [NSString stringWithFormat:@"%lu",(unsigned long)tempTask.taskIdentifier];
            if (![localArray containsObject:str]) {
                [localArray addObject:str];
                NSLog(@"增加一个并发 taskIdentifier = %@ 总数 %lu %s",str,(unsigned long)localArray.count,__func__);
            }
        });
    } fileLocalUrl:fileuUrl success:^(NSURL *fileUrlPath, NSURLResponse *response) {
        NSLog(@"下载成功 下载的文档路径是 %@, ",fileUrlPath);
        NSString *str = [NSString stringWithFormat:@"%lu",(unsigned long)tempTask.taskIdentifier];
        
        if ([localArray containsObject:str]) {
            [localArray removeObject:str];
            NSLog(@"下载成功移除一个 并发 taskIdentifier = %@",str);
        }
        
    } failure:^(NSError *error, NSInteger statusCode) {
        NSLog(@"下载失败,下载的data被downLoad工具处理了 ");
        NSString *str = [NSString stringWithFormat:@"%lu",(unsigned long)tempTask.taskIdentifier];
        
        if ([localArray containsObject:str]) {
            [localArray removeObject:str];
            NSLog(@"下载失败 移除一个 并发 taskIdentifier = %@",str);
        }
        
    }];
}

- (void)downLoadWithTask:(NSString *)url FileUrl:(NSURL *)fileuUrl{
    __block  NSURLSessionDownloadTask *tempTask;
    tempTask= [[QDNetServerDownLoadTool sharedTool]AFDownLoadFileWithUrl:url progress:^(CGFloat progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            //            self.Progress.progress = progress;
            NSString *str = [NSString stringWithFormat:@"%lu",(unsigned long)tempTask.taskIdentifier];
            if (![localArray containsObject:str]) {
                [localArray addObject:str];
                NSLog(@"增加一个并发 taskIdentifier = %@ 总数 %lu %s",str,(unsigned long)localArray.count,__func__);
            }
        });
    } fileLocalUrl:fileuUrl success:^(NSURL *fileUrlPath, NSURLResponse *response) {
    
        NSString *str = [NSString stringWithFormat:@"%lu",(unsigned long)tempTask.taskIdentifier];
        
        if ([localArray containsObject:str]) {
            [localArray removeObject:str];
            NSLog(@"下载成功移除一个 并发 taskIdentifier = %@",str);
        }
        
    } failure:^(NSError *error, NSInteger statusCode) {
        NSLog(@"下载失败,下载的data被downLoad工具处理了 ");
        NSString *str = [NSString stringWithFormat:@"%lu",(unsigned long)tempTask.taskIdentifier];
        
        if ([localArray containsObject:str]) {
            [localArray removeObject:str];
            NSLog(@"下载失败 移除一个 并发 taskIdentifier = %@",str);
        }
        
    }];
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
