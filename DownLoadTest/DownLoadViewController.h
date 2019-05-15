//
//  DownLoadViewController.h
//  DownLoadTest
//
//  Created by Mike on 2019/5/15.
//  Copyright © 2019 Quarkdata. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DownLoadViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIProgressView *Progress;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;

@end

NS_ASSUME_NONNULL_END
