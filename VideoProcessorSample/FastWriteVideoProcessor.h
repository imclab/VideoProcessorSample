//
//  FastWriteVideoProcessor.h
//  VideoProcessorSample
//
//  Created by hirofumi kaneko on 2013/02/07.
//  Copyright (c) 2013年 hirofumi kaneko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreFoundation/CFDictionary.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import "BaseVideoProcessor.h"

@protocol FastWriteVideoProcessorDelegate;

@interface FastWriteVideoProcessor : BaseVideoProcessor <AVCaptureVideoDataOutputSampleBufferDelegate>
{
}

@property (weak, nonatomic) id<FastWriteVideoProcessorDelegate> delegate;

- (BOOL)setup;
- (void)rec;
- (void)stop;

- (void)startRunning;
- (void)stopRunning;

@end

@protocol FastWriteVideoProcessorDelegate <NSObject>

- (void)drawCapture:(UIImage *)image;

@end