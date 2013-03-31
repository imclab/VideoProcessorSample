//
//  CaptureViewController.h
//  VideoProcessorSample
//
//  Created by hirofumi kaneko on 2013/02/07.
//  Copyright (c) 2013年 hirofumi kaneko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NormalVideoProcessor.h"
#import "FastWriteVideoProcessor.h"

@interface CaptureViewController : UIViewController <NormalVideoProcessorDelegate, FastWriteVideoProcessorDelegate>

@property NSString * demo;

@end
