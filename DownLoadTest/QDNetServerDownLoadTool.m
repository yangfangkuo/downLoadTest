//
//  QDNetServerDownLoadTool.m
//  QuarkData
//
//  Created by Apple on 2017/7/20.
//  Copyright © 2017年 Thunder Software Technology. All rights reserved.
//

#import "QDNetServerDownLoadTool.h"
#import <AFNetworking/AFNetworking.h>
@interface QDNetServerDownLoadTool ()
@property (nonatomic,strong) NSString  *fileHistoryPath;

@end

@implementation QDNetServerDownLoadTool
static QDNetServerDownLoadTool *tool = nil;
+ (instancetype)sharedTool{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tool =  [[self alloc] init];
    });
    return tool;
}
- (instancetype)init{
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.quarkdata.emm"];
        configuration.HTTPMaximumConnectionsPerHost = 8;
        
//        //设置请求超时为10秒钟
//
//        configuration.timeoutIntervalForRequest = 30;
//        //在蜂窝网络情况下是否继续请求（上传或下载）
//        configuration.allowsCellularAccess = YES;
        
        self.manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
        __weak typeof(self)weakSelf = self;
        [self.manager setTaskDidCompleteBlock:^(NSURLSession * _Nonnull session, NSURLSessionTask * _Nonnull task, NSError * _Nullable error) {
            NSLog(@"manager 重启收到通知了 %@",task);
            NSString *urlHost = [task.currentRequest.URL absoluteString];
            if (error) {
                if (error.code == -1001) {
                    NSLog(@"下载出错,看一下网络是否正常");
                }
                NSData *resumeData = [error.userInfo objectForKey:@"NSURLSessionDownloadTaskResumeData"];
                [weakSelf saveHistoryWithKey:urlHost DownloadTaskResumeData:resumeData];
                //这个是因为 用户比如强退程序之后 ,再次进来的时候 存进去这个继续的data  需要用户去刷新列表
            }else{
                if ([weakSelf.downLoadHistoryDictionary valueForKey:urlHost]) {
                    [weakSelf.downLoadHistoryDictionary removeObjectForKey:urlHost];
                    [weakSelf saveDownLoadHistoryDirectory];
                }
            }

        }];
        
        //这个代码和上面的setTaskDidCompleteBlock功能是一样的 使用上面的API更友好 通知同步会阻塞线程
//        NSURLSessionDownloadTask *task;
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(downLoadData:)
//                                                     name:AFNetworkingTaskDidCompleteNotification
//                                                   object:task];

        
        //网络变化的通知
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(networkChanged:)
//                                                     name:kRealReachabilityChangedNotification
//                                                   object:nil];
        
        
        NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
        NSString *path=[paths     objectAtIndex:0];
        self.fileHistoryPath=[path stringByAppendingPathComponent:@"fileDownLoadHistory.plist"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.fileHistoryPath]) {
            self.downLoadHistoryDictionary =[NSMutableDictionary dictionaryWithContentsOfFile:self.fileHistoryPath];
        }else{
            self.downLoadHistoryDictionary =[NSMutableDictionary dictionary];
            //将dictionary中的数据写入plist文件中
            [self.downLoadHistoryDictionary writeToFile:self.fileHistoryPath atomically:YES];
        }
        NSLog(@"%s   self.test.session = %@ ",__func__,self.manager.session);
        
    }
    return  self;
}

- (void)saveHistoryWithKey:(NSString *)key DownloadTaskResumeData:(NSData *)data{
    if (!data) {
        NSString *emptyData = [NSString stringWithFormat:@""];
        [self.downLoadHistoryDictionary setObject:emptyData forKey:key];

    }else{
        [self.downLoadHistoryDictionary setObject:data forKey:key];
    }
    
  [self.downLoadHistoryDictionary writeToFile:self.fileHistoryPath atomically:NO];
}
- (void)saveDownLoadHistoryDirectory{
    [self.downLoadHistoryDictionary writeToFile:self.fileHistoryPath atomically:YES];
}
- (NSURLSessionDownloadTask *)AFDownLoadFileWithUrl:(NSString*)urlHost
                                           progress:(DowningProgress)progress
                                       fileLocalUrl:(NSURL *)localUrl
                                            success:(DonwLoadSuccessBlock)success
                                            failure:(DownLoadfailBlock)failure{
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlHost]];
    NSURLSessionDownloadTask   *downloadTask = nil;
    NSData *downLoadHistoryData = [self.downLoadHistoryDictionary   objectForKey:urlHost];
//    NSLog(@"本地是否存储需要续传的数据长度为 %ld",downLoadHistoryData.length);
    if (downLoadHistoryData.length > 0 ) {
        NSLog(@"使用旧任务");
        downloadTask = [self.manager downloadTaskWithResumeData:downLoadHistoryData progress:^(NSProgress * _Nonnull downloadProgress) {
            if (progress) {
                progress(1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
            }
            
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return localUrl;
            
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
            if ([httpResponse statusCode] == 404) {
                [[NSFileManager defaultManager] removeItemAtURL:filePath error:nil];
            }

            if (error) {
                if (failure) {
                    failure(error,[httpResponse statusCode]);
                //将下载失败存储起来  提交到下面的 的网络监管类里面
                }
            }else{
                if (success) {
                    success(filePath,response);
                }
                //将下载成功存储起来  提交到下面的 的网络监管类里面
            }
            
        }];
    }else{
//        NSLog(@"开辟 新任务");
        downloadTask = [self.manager    downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
            if (progress) {
                progress(1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
//                NSLog(@"%F",(1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount));
            }
            
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return localUrl;
            
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            NSLog(@"完成");
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
            if ([httpResponse statusCode] == 404) {
                [[NSFileManager defaultManager] removeItemAtURL:filePath error:nil];
            }
            if (error) {
                if (failure) {
                    failure(error,[httpResponse statusCode]);
                }
            //将下载失败存储起来  提交到了appDelegate 的网络监管类里面
            }else{
                if (success) {
                    success(filePath,response);
                }
                //将下载成功存储起来  提交到了appDelegate 的网络监管类里面
            }
            
        }];
    }
    [downloadTask resume];
    return downloadTask;
}
/***************************************下载模块的关键的代码 包括强退闪退都会有***************************************/
- (void)downLoadData:(NSNotification *)notification{
    
    if ([notification.object isKindOfClass:[ NSURLSessionDownloadTask class]]) {
        NSURLSessionDownloadTask *task = notification.object;
        NSString *urlHost = [task.currentRequest.URL absoluteString];
        NSError *error  = [notification.userInfo objectForKey:AFNetworkingTaskDidCompleteErrorKey] ;
        NSLog(@"重启收到通知了 %@",notification.object);

        if (error) {
            if (error.code == -1001) {
                NSLog(@"下载出错,看一下网络是否正常");
            }
            NSData *resumeData = [error.userInfo objectForKey:@"NSURLSessionDownloadTaskResumeData"];
            [self saveHistoryWithKey:urlHost DownloadTaskResumeData:resumeData];
            //这个是因为 用户比如强退程序之后 ,再次进来的时候 存进去这个继续的data  需要用户去刷新列表
        }else{
            if ([self.downLoadHistoryDictionary valueForKey:urlHost]) {
                [self.downLoadHistoryDictionary removeObjectForKey:urlHost];
                [self saveDownLoadHistoryDirectory];
            }
        }
    }
    
}
- (void)stopAllDownLoadTasks{
    //停止所有的下载
    if ([[self.manager downloadTasks] count]  == 0) {
        return;
    }
    for (NSURLSessionDownloadTask *task in  [self.manager downloadTasks]) {
        if (task.state == NSURLSessionTaskStateRunning) {
            [task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                
            }];
        }
    }
}


- (void)dealloc{
    
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}
//- (void)URLSession:(NSURLSession *)session
//              task:(NSURLSessionTask *)task
//didCompleteWithError:(NSError *)error{
//    
//}

@end
