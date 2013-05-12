//
//  VideoProcessor.h
//
//  Created by hirofumi kaneko on 2013/02/07.
//  Copyright (c) 2013 hirofumi kaneko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreFoundation/CFDictionary.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>

@protocol VideoProcessorDelegate;

@interface VideoProcessor : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (weak, nonatomic) id<VideoProcessorDelegate> delegate;

@property BOOL isRecording;
- (BOOL)setup;
- (void)rec;
- (void)stop;
- (void)startRunning;
- (void)stopRunning;



@end

@protocol VideoProcessorDelegate <NSObject>

- (void)drawCapture:(UIImage *)image;

@end