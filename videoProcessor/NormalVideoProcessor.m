//
//  NormalVideoProcessor.m
//  VideoProcessorSample
//
//  Created by hirofumi kaneko on 2013/02/07.
//  Copyright (c) 2013年 hirofumi kaneko. All rights reserved.
//

#import "NormalVideoProcessor.h"


@interface NormalVideoProcessor()
{
    AVAssetWriter                        * _videoWriter;
    AVAssetWriterInput                   * _writerInput;
    AVCaptureSession                     * _captureSession;
	AVCaptureConnection                  * _audioConnection;
	AVCaptureConnection                  * _videoConnection;
    AVCaptureDeviceInput                 * _videoIn;
    AVCaptureVideoDataOutput             * _videoOut;
    AVAssetWriterInputPixelBufferAdaptor * _adaptor;
	AVCaptureVideoOrientation              _videoOrientation;
    
    dispatch_queue_t _movieWritingQueue;
    dispatch_queue_t _dispatchQueue;
    
    BOOL _isRecording;
    
    NSMutableArray * _imageList;
    
    void * bitmap;
    UIImage * imageBuffer;
    
//	size_t _outputW;
//	size_t _outputH;
	size_t width;
	size_t height;
    
}

@end


@implementation NormalVideoProcessor

- (id)init
{
    self = [super init];
    if (self)
    {
        _imageList = [[NSMutableArray alloc] init];
        width = 640;
        height = 480;
    }
    return self;
}


#pragma mark - --------------------------------------------------------------------------
#pragma mark - AVFoundation


- (BOOL)setup
{    
	_movieWritingQueue = dispatch_queue_create("Movie Writing Queue", DISPATCH_QUEUE_SERIAL);
    
    _captureSession = [[AVCaptureSession alloc] init];
    [_captureSession setSessionPreset:AVCaptureSessionPreset640x480];
    
    _videoIn = [[AVCaptureDeviceInput alloc] initWithDevice:[self videoDeviceWithPosition:AVCaptureDevicePositionBack] error:nil];
    if ([_captureSession canAddInput:_videoIn]) [_captureSession addInput:_videoIn];
    
	_videoOut = [[AVCaptureVideoDataOutput alloc] init];
	[_videoOut setAlwaysDiscardsLateVideoFrames:YES];
	[_videoOut setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)}];
    
    
	dispatch_queue_t videoCaptureQueue = dispatch_queue_create("Video Capture Queue", DISPATCH_QUEUE_SERIAL);
	[_videoOut setSampleBufferDelegate:self queue:videoCaptureQueue];
    
    if ([_captureSession canAddOutput:_videoOut]) [_captureSession addOutput:_videoOut];
	_videoConnection = [_videoOut connectionWithMediaType:AVMediaTypeVideo];
    _videoConnection.videoMinFrameDuration = CMTimeMake(1, 24);
    
//	_videoOrientation = [_videoConnection videoOrientation];
    
    return YES;
}

- (AVCaptureDevice *)videoDeviceWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == position) return device;
    }
    return nil;
}

- (void)startRunning
{
    if (!_isRecording) [_captureSession startRunning];
}

- (void)stopRunning
{
    if (_isRecording) [_captureSession stopRunning];
}




#pragma mark - --------------------------------------------------------------------------
#pragma mark - AVFoundation Delegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CGImageRef cgImage;
    CVImageBufferRef _buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    if(CVPixelBufferLockBaseAddress(_buffer, 0) == kCVReturnSuccess)
    {
        uint8_t *base;
        size_t    bytesPerRow;
        base = CVPixelBufferGetBaseAddress(_buffer);
        bytesPerRow = CVPixelBufferGetBytesPerRow(_buffer);
        
        CGColorSpaceRef colorSpace;
        colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef cgContext = CGBitmapContextCreate(
                                                       base, width, height, 8, bytesPerRow, colorSpace,
                                                       kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGContextSetInterpolationQuality(cgContext, kCGInterpolationLow);
        CGColorSpaceRelease(colorSpace);
        cgImage = CGBitmapContextCreateImage(cgContext);
        imageBuffer = [UIImage imageWithCGImage:cgImage];
        
        CVPixelBufferUnlockBaseAddress(_buffer, 0);
        
        
        CGContextRelease(cgContext);
        CGImageRelease(cgImage);
        
        [self performSelectorOnMainThread:@selector(effect) withObject:nil waitUntilDone:NO];
    }
}

- (void)effect
{
    [_imageList addObject:imageBuffer];
    
    if ([_imageList count] > 135)
    {
        [_imageList removeObjectAtIndex:0];
    }
    
    [_delegate drawCapture:imageBuffer];
}




#pragma mark - --------------------------------------------------------------------------
#pragma mark - Action

- (void)rec
{
    LOG_METHOD;
    
    CGSize _size = CGSizeMake(width, height);
    NSURL * _url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@_%@%@", NSTemporaryDirectory(), @"output", [NSDate date], @".mov"]];
    
    NSError *error = nil;
    _videoWriter = [[AVAssetWriter alloc] initWithURL:_url
                                            fileType:AVFileTypeQuickTimeMovie
                                               error:&error];
    if(error) NSLog(@"error = %@", [error localizedDescription]);
    
    NSDictionary *videoSettings = @{AVVideoCodecKey: AVVideoCodecH264,
                                    AVVideoWidthKey: [NSNumber numberWithInt:_size.width],
                                    AVVideoHeightKey: [NSNumber numberWithInt:_size.height]};
    _writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    NSDictionary *sourcePixelBufferAttributesDictionary = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32ARGB)};
    
    _adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_writerInput
                                                                               sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
    [_videoWriter addInput:_writerInput];
    [_videoWriter startWriting];
    [_videoWriter startSessionAtSourceTime:kCMTimeZero];
    _dispatchQueue = dispatch_queue_create("mediaInputQueue", NULL);
    
    // レコーディング開始
    _isRecording = YES;
}

- (void)stop
{
    
}


@end