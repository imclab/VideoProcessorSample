//
//  NormalVideoProcessor.m
//  VideoProcessorSample
//
//  Created by hirofumi kaneko on 2013/02/07.
//  Copyright (c) 2013年 hirofumi kaneko. All rights reserved.
//

#import "NormalVideoProcessor.h"

#define kVideoWidth 960
#define kVideoHeight 540
#define kRate 20
#define kMaxCount 200


@interface NormalVideoProcessor()
{
    AVAssetWriter                        * _videoWriter;
    AVAssetWriterInput                   * _writerInput;
    AVCaptureSession                     * _captureSession;
	AVCaptureConnection                  * _videoConnection;
    AVCaptureDeviceInput                 * _videoIn;
    AVCaptureVideoDataOutput             * _videoOut;
    AVAssetWriterInputPixelBufferAdaptor * _adaptor;

    NSMutableArray * _imageList;
    UIImage        * _imageBuffer;
    NSURL          * _url;

    CGSize _size;
    BOOL   _isRecording;
}

@end


@implementation NormalVideoProcessor

- (id)init
{
    self = [super init];
    if (self)
    {
        _imageList = [[NSMutableArray alloc] init];
    }
    return self;
}


#pragma mark - --------------------------------------------------------------------------
#pragma mark - AVFoundation

- (BOOL)setup
{
    _captureSession = [[AVCaptureSession alloc] init];
    [_captureSession setSessionPreset:AVCaptureSessionPresetiFrame960x540];

    _videoIn = [[AVCaptureDeviceInput alloc] initWithDevice:[self videoDeviceWithPosition:AVCaptureDevicePositionBack] error:nil];
    if ([_captureSession canAddInput:_videoIn]) [_captureSession addInput:_videoIn];

	_videoOut = [[AVCaptureVideoDataOutput alloc] init];
	[_videoOut setAlwaysDiscardsLateVideoFrames:YES];
	[_videoOut setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)}];

	dispatch_queue_t videoCaptureQueue = dispatch_queue_create("Video Capture Queue", DISPATCH_QUEUE_SERIAL);
	[_videoOut setSampleBufferDelegate:self queue:videoCaptureQueue];

    if ([_captureSession canAddOutput:_videoOut]) [_captureSession addOutput:_videoOut];
	_videoConnection = [_videoOut connectionWithMediaType:AVMediaTypeVideo];
    _videoConnection.videoMinFrameDuration = CMTimeMake(1, kRate);

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

- (void)effect
{
    if (_isRecording)
    {
        [_imageList addObject:_imageBuffer];
        if ([_imageList count] > kMaxCount)
        {
            _isRecording = false;
            [self write];
        }
        LOG(@"image count : %d", [_imageList count]);
    }
    [_delegate drawCapture:_imageBuffer];
}


- (void)write
{
    dispatch_queue_t dispatchQueue = dispatch_queue_create("mediaInputQueue", NULL);
    int __block i = 0;

    [_writerInput requestMediaDataWhenReadyOnQueue:dispatchQueue usingBlock:^{
        while ([_writerInput isReadyForMoreMediaData])
        {
            if(++i >= [_imageList count])
            {
                [_writerInput markAsFinished];
                [_videoWriter finishWritingWithCompletionHandler:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self save];
                    });
                }];
                return;
            }
            CVPixelBufferRef buffer = (CVPixelBufferRef)[self pixelBufferFromCGImage:[[_imageList objectAtIndex:i] CGImage] size:_size];
            if (buffer)
            {
                if([_adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake(i, kRate)]) LOG(@"Success : %d", i);
                else
                {
                    [self alert:@"Fail" message:nil btnName:@"OK"];
                }
                CFRelease(buffer);
            }
        }
    }];
}

- (CVPixelBufferRef )pixelBufferFromCGImage:(CGImageRef)localImage size:(CGSize)localSize
{
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferPoolCreatePixelBuffer(NULL, _adaptor.pixelBufferPool, &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);

    CVPixelBufferLockBaseAddress(pxbuffer, 0);

    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);

    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();

    CGContextRef context = CGBitmapContextCreate(pxdata, localSize.width, localSize.height, 8, 4 * localSize.width, rgbColorSpace, kCGImageAlphaPremultipliedFirst);
    NSParameterAssert(context);

    CGContextSetInterpolationQuality(context, kCGInterpolationLow);
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(localImage), CGImageGetHeight(localImage)), localImage);

    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);

    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    return pxbuffer;
}

- (void)startRunning { if (!_isRecording) [_captureSession startRunning]; }
- (void)stopRunning { if (_isRecording) [_captureSession stopRunning]; }


#pragma mark - --------------------------------------------------------------------------
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

        _imageBuffer = [UIImage imageWithCGImage:cgImage scale:1.0f orientation:UIImageOrientationRight];

        CVPixelBufferUnlockBaseAddress(buffer, 0); // unlock

        CGContextRelease(cgContext);
        CGImageRelease(cgImage);

        [self performSelectorOnMainThread:@selector(effect) withObject:nil waitUntilDone:NO];
    }
}


#pragma mark - --------------------------------------------------------------------------
#pragma mark - Action

- (void)rec
{
    if (_isRecording) return;

    _size = CGSizeMake(kVideoWidth, kVideoHeight);
    _url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@_%@%@", NSTemporaryDirectory(), @"output", [NSDate date], @".mov"]];

    NSError * error = nil;
    _videoWriter = [[AVAssetWriter alloc] initWithURL:_url fileType:AVFileTypeQuickTimeMovie error:&error];
    if(error) NSLog(@"error : %@", [error localizedDescription]);

    NSDictionary * videoSettings = @{AVVideoCodecKey: AVVideoCodecH264,
                                      AVVideoWidthKey: [NSNumber numberWithInt:_size.width],
                                      AVVideoHeightKey: [NSNumber numberWithInt:_size.height]};

    _writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    [_writerInput setExpectsMediaDataInRealTime:YES];

    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, _size.width * 0.5, _size.height * 0.5);
    transform = CGAffineTransformRotate(transform , 90 / 180.0f * M_PI);
    transform = CGAffineTransformScale(transform, 1.0, 1.0);
    _writerInput.transform = transform;

    NSDictionary * sourcePixelBufferAttributesDictionary = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32ARGB)};
    _adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_writerInput
                                                                                sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    [_videoWriter addInput:_writerInput];
    [_videoWriter startWriting];
    [_videoWriter startSessionAtSourceTime:kCMTimeZero];
    _isRecording = YES;
}

- (void)stop
{
    _isRecording = false;
    [self write];
}


#pragma mark - --------------------------------------------------------------------------
#pragma mark - utils

- (void)alert:(NSString *)title message:(NSString *)message btnName:(NSString *)btnName
{
    [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:btnName otherButtonTitles:nil] show];
}

- (void)save
{
	ALAssetsLibrary * library = [[ALAssetsLibrary alloc] init];
	[library writeVideoAtPathToSavedPhotosAlbum:_url
                                 completionBlock:^(NSURL *assetURL, NSError *error){
                                     [self alert:@"Save!" message:nil btnName:@"OK"];
                                 }];
}



@end