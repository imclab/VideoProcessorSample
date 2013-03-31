//
//  FastWriteVideoProcessor.m
//  VideoProcessorSample
//
//  Created by hirofumi kaneko on 2013/02/07.
//  Copyright (c) 2013年 hirofumi kaneko. All rights reserved.
//

#import "FastWriteVideoProcessor.h"

#define kVideoWidth 960
#define kVideoHeight 540
#define kRate 30

@interface FastWriteVideoProcessor()
{
    AVAssetWriter                        * videoWriter_;
    AVAssetWriterInput                   * writerInput_;
    AVCaptureSession                     * captureSession_;
	AVCaptureConnection                  * videoConnection_;
    AVCaptureDeviceInput                 * videoIn_;
    AVCaptureVideoDataOutput             * videoOut_;
    AVAssetWriterInputPixelBufferAdaptor * adaptor_;

    NSMutableArray * imageList_;
    UIImage        * imageBuffer_;
    NSURL          * url_;
    CGSize size_;
    NSInteger __block frame_;
}

@end


@implementation FastWriteVideoProcessor

- (id)init
{
    self = [super init];
    if (self)
    {
        imageList_ = [[NSMutableArray array] mutableCopy];
    }
    return self;
}


#pragma mark - --------------------------------------------------------------------------
#pragma mark - AVFoundation

- (BOOL)setup
{
    captureSession_ = [[AVCaptureSession alloc] init];
    [captureSession_ setSessionPreset:AVCaptureSessionPresetiFrame960x540];

    videoIn_ = [[AVCaptureDeviceInput alloc] initWithDevice:[self videoDeviceWithPosition:AVCaptureDevicePositionBack] error:nil];
    if ([captureSession_ canAddInput:videoIn_]) [captureSession_ addInput:videoIn_];

	videoOut_ = [[AVCaptureVideoDataOutput alloc] init];
	[videoOut_ setAlwaysDiscardsLateVideoFrames:YES];
	[videoOut_ setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)}];

	dispatch_queue_t videoCaptureQueue = dispatch_queue_create("Video Capture Queue", DISPATCH_QUEUE_SERIAL);
	[videoOut_ setSampleBufferDelegate:self queue:videoCaptureQueue];

    if ([captureSession_ canAddOutput:videoOut_]) [captureSession_ addOutput:videoOut_];
	videoConnection_ = [videoOut_ connectionWithMediaType:AVMediaTypeVideo];
    videoConnection_.videoMinFrameDuration = CMTimeMake(1, kRate);

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

- (void)write
{
    dispatch_queue_t dispatchQueue = dispatch_queue_create("mediaInputQueue", NULL);
    [self stopRunning];
    
    // write AVAssetWriterInputPixelBufferAdaptor
    [writerInput_ requestMediaDataWhenReadyOnQueue:dispatchQueue usingBlock:^{
        while ([writerInput_ isReadyForMoreMediaData])
        {
            if([imageList_ count] <= 1)
            {
                [writerInput_ markAsFinished];
                [videoWriter_ finishWritingWithCompletionHandler:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self save];
                    });
                }];
                return;
            }
            CVPixelBufferRef buffer = (CVPixelBufferRef)[self pixelBufferFromCGImage:[[imageList_ objectAtIndex:frame_] CGImage] size:size_];
            if (buffer)
            {
                if([adaptor_ appendPixelBuffer:buffer withPresentationTime:CMTimeMake(frame_, kRate)])
                {
                    LOG(@"Success : %d", frame_);
                    frame_ ++;
                }
                else
                {
                    [self alert:@"Fail" message:nil btnName:@"OK"];
                }
                CFRelease(buffer);
                buffer = nil;
            }
            [imageList_ removeObjectAtIndex:0];
        }
    }];
}

- (CVPixelBufferRef )pixelBufferFromCGImage:(CGImageRef)localImage size:(CGSize)localSize
{
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferPoolCreatePixelBuffer(NULL, adaptor_.pixelBufferPool, &pxbuffer);
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

- (void)startRunning { if (!self.isRecording) [captureSession_ startRunning]; }
- (void)stopRunning { if (self.isRecording) [captureSession_ stopRunning]; }


#pragma mark - --------------------------------------------------------------------------
#pragma mark - Effect

- (void)effect
{

    //----------------------------------
    // TODO : effect
    //----------------------------------

    // show capture
    [_delegate drawCapture:imageBuffer_];
}


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

        imageBuffer_ = [UIImage imageWithCGImage:cgImage scale:1.0f orientation:UIImageOrientationRight];

        CVPixelBufferUnlockBaseAddress(buffer, 0); // unlock
        CGContextRelease(cgContext);
        CGImageRelease(cgImage);

        [self performSelectorOnMainThread:@selector(effect) withObject:nil waitUntilDone:NO];

        if (!self.isRecording) return;

        [imageList_ addObject:imageBuffer_];

        // write AVAssetWriterInputPixelBufferAdaptor
        if ([writerInput_ isReadyForMoreMediaData])
        {
            CVPixelBufferRef buffer = (CVPixelBufferRef)[self pixelBufferFromCGImage:[[imageList_ objectAtIndex:0] CGImage] size:size_];
            if (buffer)
            {
                if([adaptor_ appendPixelBuffer:buffer withPresentationTime:CMTimeMake(frame_, kRate)])
                {
                    frame_ ++;
                }
                else
                {
                    [self alert:@"Fail" message:nil btnName:@"OK"];
                }
                CFRelease(buffer);
                buffer = nil;
            }

            [imageList_ removeObjectAtIndex:0];
        }
        //LOG(@"count %i", [imageList_ count]);
    }
}


#pragma mark - --------------------------------------------------------------------------
#pragma mark - Action

- (void)rec
{
    if (self.isRecording) return;

    frame_ = 0;
    size_ = CGSizeMake(kVideoWidth, kVideoHeight);
    url_ = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@_%@%@", NSTemporaryDirectory(), @"output", [NSDate date], @".mov"]];

    NSError * error = nil;
    videoWriter_ = [[AVAssetWriter alloc] initWithURL:url_ fileType:AVFileTypeQuickTimeMovie error:&error];
    if(error) NSLog(@"error : %@", [error localizedDescription]);

    NSDictionary * videoSettings = @{AVVideoCodecKey: AVVideoCodecH264,
                                      AVVideoWidthKey: [NSNumber numberWithInt:size_.width],
                                      AVVideoHeightKey: [NSNumber numberWithInt:size_.height]};

    writerInput_ = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    [writerInput_ setExpectsMediaDataInRealTime:YES];

    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, size_.width * 0.5, size_.height * 0.5);
    transform = CGAffineTransformRotate(transform , 90 / 180.0f * M_PI);
    transform = CGAffineTransformScale(transform, 1.0, 1.0);
    writerInput_.transform = transform;

    NSDictionary * sourcePixelBufferAttributesDictionary = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32ARGB)};
    adaptor_ = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput_
                                                                                sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    [videoWriter_ addInput:writerInput_];
    [videoWriter_ startWriting];
    [videoWriter_ startSessionAtSourceTime:kCMTimeZero];
    self.isRecording = YES;
}

- (void)stop
{
    self.isRecording = false;
    [self write];
}

- (void)alert:(NSString *)title message:(NSString *)message btnName:(NSString *)btnName
{
    [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:btnName otherButtonTitles:nil] show];
}

- (void)save
{
	ALAssetsLibrary * library = [[ALAssetsLibrary alloc] init];
	[library writeVideoAtPathToSavedPhotosAlbum:url_
                                 completionBlock:^(NSURL *assetURL, NSError *error){
                                     [self alert:@"Save!" message:nil btnName:@"OK"];
                                 }];
}


@end