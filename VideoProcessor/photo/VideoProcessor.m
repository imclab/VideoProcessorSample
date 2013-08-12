//
//  VideoProcessor.m
//
//  Created by hirofumi kaneko on 2013/02/07.
//  Copyright (c) 2013 hirofumi kaneko. All rights reserved.
//

#import "VideoProcessor.h"

#define kRate 30

@interface VideoProcessor()
{
    AVAssetWriter             * videoWriter_;
    AVAssetWriterInput        * writerInput_;
    AVCaptureSession          * captureSession_;
	AVCaptureConnection       * videoConnection_;
    AVCaptureDeviceInput      * videoIn_;
    AVCaptureVideoDataOutput  * videoOut_;
    AVCaptureDevice           * videoDevice_;

    UIImage * imageBuffer_;
    CGSize size_;
    NSInteger __block frame_;
    BOOL isCameraBack_;
    BOOL isStartRunning_;
    BOOL isTorchOn_;
}
@end

@implementation VideoProcessor

- (id)init
{
    self = [super init];
    if (self)
    {
        isCameraBack_ = YES;
        isStartRunning_ = NO;
        isTorchOn_ = NO;
    }
    return self;
}


#pragma mark - AVFoundation

- (BOOL)setup
{
    captureSession_ = [[AVCaptureSession alloc] init];
    [captureSession_ setSessionPreset:AVCaptureSessionPreset640x480];

    if (isCameraBack_) videoDevice_ = [self videoDeviceWithPosition:AVCaptureDevicePositionBack];
    else videoDevice_ = [self videoDeviceWithPosition:AVCaptureDevicePositionFront];
    videoIn_ = [[AVCaptureDeviceInput alloc] initWithDevice:videoDevice_ error:nil];

    if ([captureSession_ canAddInput:videoIn_]) [captureSession_ addInput:videoIn_];

	videoOut_ = [[AVCaptureVideoDataOutput alloc] init];
	[videoOut_ setAlwaysDiscardsLateVideoFrames:YES];
	[videoOut_ setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)}];

	dispatch_queue_t videoCaptureQueue = dispatch_queue_create("Video Capture Queue", DISPATCH_QUEUE_SERIAL);
	[videoOut_ setSampleBufferDelegate:self queue:videoCaptureQueue];

    if ([captureSession_ canAddOutput:videoOut_]) [captureSession_ addOutput:videoOut_];
	videoConnection_ = [videoOut_ connectionWithMediaType:AVMediaTypeVideo];
    videoConnection_.videoMinFrameDuration = CMTimeMake(1, kRate);

    return YES;}

- (AVCaptureDevice *)videoDeviceWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) if ([device position] == position) return device;
    return nil;
}

- (void)startRunning
{
    if (!isStartRunning_)
    {
        [captureSession_ startRunning];
        isStartRunning_ = YES;
    }
}

- (void)stopRunning
{
    if (isStartRunning_)
    {
        [captureSession_ stopRunning];
        isStartRunning_ = NO;
    }
}



#pragma mark - AVFoundation Delegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CGImageRef cgImage;
    CVImageBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer);

    if(CVPixelBufferLockBaseAddress(buffer, 0) == kCVReturnSuccess) // lock
    {
        uint8_t * base;
        size_t bytesPerRow, w, h;
        w = CVPixelBufferGetWidth(buffer);
        h = CVPixelBufferGetHeight(buffer);
        base = CVPixelBufferGetBaseAddress(buffer);
        bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);

        CGColorSpaceRef colorSpace;
        colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef cgContext = CGBitmapContextCreate(base, w, h, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGContextSetInterpolationQuality(cgContext, kCGInterpolationLow);
        CGColorSpaceRelease(colorSpace);
        cgImage = CGBitmapContextCreateImage(cgContext);

        imageBuffer_ = [UIImage imageWithCGImage:cgImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationRight];

        CVPixelBufferUnlockBaseAddress(buffer, 0); // unlock
        CGContextRelease(cgContext);
        CGImageRelease(cgImage);

        [self performSelectorOnMainThread:@selector(draw:) withObject:imageBuffer_ waitUntilDone:NO];

        if (!_isRecording) return;

        [self stopRunning];
        [writerInput_ markAsFinished];
        [self performSelectorOnMainThread:@selector(take:) withObject:imageBuffer_ waitUntilDone:NO];
    }
}

- (void)draw:(UIImage * )image
{
    [_delegate videoProcessorDrawCapture:image];
}

- (void)take:(UIImage * )image
{
    [_delegate videoProcessorTakeCapture:image];
}



#pragma mark - Action

- (void)take
{
    _isRecording = YES;
}

- (void)cameraMode:(VideoProcessorCameraMode)type
{
    switch (type)
    {
        case 0: isCameraBack_ = YES; break;
        case 1: isCameraBack_ = NO; break;
        case 2: isCameraBack_ =! isCameraBack_; break;
    }
    [self stopRunning];
    [self setup];
    [self startRunning];
}

- (void)setFocusWithSize:(CGSize)drawViewSize focusPoint:(CGPoint)point
{
    CGPoint p = CGPointMake(point.y / drawViewSize.height, 1.0 - point.x / drawViewSize.width);
    if ([videoDevice_ isFocusPointOfInterestSupported] && [videoDevice_ isFocusModeSupported:AVCaptureFocusModeAutoFocus])
    {
        [videoDevice_ lockForConfiguration:nil];
        videoDevice_.focusPointOfInterest = p;
        videoDevice_.focusMode = AVCaptureFocusModeAutoFocus;
        [videoDevice_ unlockForConfiguration];
    }
}

- (void)torchMode:(VideoProcessorTorchMode)type
{
    if (videoDevice_.position == AVCaptureDevicePositionFront) return;
    [videoDevice_ lockForConfiguration:nil];
    switch (type)
    {
        case 0:
            videoDevice_.torchMode = AVCaptureTorchModeOff;
            isTorchOn_ = NO;
            break;
        case 1:
            videoDevice_.torchMode = AVCaptureTorchModeOn;
            isTorchOn_ = YES;
            break;
        case 2:
            if(isTorchOn_) videoDevice_.torchMode = AVCaptureTorchModeOff;
            else videoDevice_.torchMode = AVCaptureTorchModeOn;
            isTorchOn_ =! isTorchOn_;
            break;
    }
    [videoDevice_ unlockForConfiguration];
}

@end