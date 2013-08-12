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

typedef NS_ENUM(NSInteger, VideoProcessorCameraMode)
{
    VideoProcessorCameraModeBack = 0,
    VideoProcessorCameraModeFront,
    VideoProcessorCameraModeReverse
};

typedef NS_ENUM(NSInteger, VideoProcessorTorchMode)
{
    VideoProcessorTorchModeOff = 0,
    VideoProcessorTorchModeOn,
    VideoProcessorTorchModeReverse
};

@protocol VideoProcessorDelegate;

@interface VideoProcessor : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (weak, nonatomic) id<VideoProcessorDelegate> delegate;

@property BOOL isRecording;
- (BOOL)setup;
- (void)startRunning;
- (void)stopRunning;

- (void)rec;
- (void)stop;
- (void)cameraMode:(VideoProcessorCameraMode)type;
- (void)setFocusWithSize:(CGSize)drawViewSize focusPoint:(CGPoint)point;
- (void)torch:(VideoProcessorTorchMode)type;

@end

@protocol VideoProcessorDelegate <NSObject>

- (void)videoProcessorDrawCapture:(UIImage *)image;

@end