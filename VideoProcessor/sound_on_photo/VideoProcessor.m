//
//  VideoProcessor.m
//
//  Created by hirofumi kaneko on 2013/02/07.
//

#import "VideoProcessor.h"

@interface VideoProcessor()
{
    // AVFoundationクラス
    AVCaptureSession           * captureSession_;
    AVCaptureDeviceInput       * videoIn_;
    AVCaptureVideoDataOutput   * videoOut_;
    AVCaptureDevice            * videoDevice_;
    AVCaptureConnection        * videoConnection_;
    AVCaptureVideoPreviewLayer * previewLayer_;
    AVCaptureStillImageOutput  * imageOutput_; // サウンド音をならすためにこの出力を利用

    UIView  * view_; // 各表示用クラスのViewを格納
    UIImage * imageBuffer_; // キャプチャした画像
    SystemSoundID SoundID_; // 撮影時のサウンド

    BOOL isTorchOn_; // カメラのトーチオンオフの判別
    BOOL isStartRunning_; // キャプチャ中かどうかの判別
}
@end

@implementation VideoProcessor

- (id)init
{
    self = [super init];
    if (self)
    {
        _isCameraBack = YES;
        isStartRunning_ = NO;
        isTorchOn_ = NO;
    }
    return self;
}


#pragma mark - AVFoundation


// AVFoundationの設定
- (BOOL)setupWithView:(UIView *)view
{
    view_ = view; //各キャプチャー表示クラスのView

    captureSession_ = [[AVCaptureSession alloc] init];
    [captureSession_ beginConfiguration];
    [captureSession_ setSessionPreset:AVCaptureSessionPresetiFrame960x540]; // キャプチャーサイズの設定
    [captureSession_ commitConfiguration];

    // フロント、バックのカメラ
    if (_isCameraBack) videoDevice_ = [self videoDeviceWithPosition:AVCaptureDevicePositionBack];
    else videoDevice_ = [self videoDeviceWithPosition:AVCaptureDevicePositionFront];

    videoIn_ = [[AVCaptureDeviceInput alloc] initWithDevice:videoDevice_ error:nil];
    if ([captureSession_ canAddInput:videoIn_]) [captureSession_ addInput:videoIn_];

    [self addPreviewLayer]; //キャプチャーレイヤーの追加

    imageOutput_ = [[AVCaptureStillImageOutput alloc] init];
    if ([captureSession_ canAddOutput:imageOutput_]) [captureSession_ addOutput:imageOutput_];

    if ([videoDevice_ isFocusPointOfInterestSupported] && [videoDevice_ isFocusModeSupported:AVCaptureFocusModeAutoFocus])
    {
        [videoDevice_ lockForConfiguration:nil];
        videoDevice_.focusMode = AVCaptureFocusModeAutoFocus;
        [videoDevice_ unlockForConfiguration];
    }
    return YES;
}

- (AVCaptureDevice *)videoDeviceWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) if ([device position] == position) return device;
    return nil;
}

// キャプチャー表示レイヤーの生成
- (void)addPreviewLayer
{
    if (previewLayer_)
    {
        [previewLayer_ removeFromSuperlayer];
        previewLayer_ = nil;
    }
    previewLayer_ = [AVCaptureVideoPreviewLayer layerWithSession:captureSession_];
    previewLayer_.videoGravity = AVLayerVideoGravityResize;
    previewLayer_.frame = view_.bounds;
    [view_.layer addSublayer:previewLayer_];
}

// キャプチャー表示レイヤーの削除
- (void)removePreviewLayer
{
    [previewLayer_ removeFromSuperlayer];
    previewLayer_ = nil;
}

//  キャプチャのスタート
- (void)startRunning
{
    if (!isStartRunning_)
    {
        [captureSession_ startRunning];
        isStartRunning_ = YES;
    }
}

// キャプチャのストップ
- (void)stopRunning
{
    if (isStartRunning_)
    {
        [captureSession_ stopRunning];
        isStartRunning_ = NO;
    }
}


#pragma mark - AVFoundation

// 静止画のキャプチャ
- (void)capture
{
    __weak VideoProcessor * weakSelf = self;
    AVCaptureConnection * connection = [[imageOutput_ connections] lastObject];
    [imageOutput_ captureStillImageAsynchronouslyFromConnection:connection
                                              completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                                                  
                                                  NSData * data = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                                                  UIImage * image = [UIImage imageWithData:data];
                                                  
                                                  [weakSelf take:image]; // デリゲートの実行メソッドを呼ぶ
                                              }];
}


#pragma mark - VideoProcessor Delegate

- (void)take:(UIImage * )image
{
    [_delegate videoProcessorTakeCapture:image];
}


#pragma mark - Action


// キャプチャーから撮影
- (void)take
{
    [self capture];
}

// キャプチャーの再開
- (void)resume
{
    [self startRunning];
}

// カメラのフロントバック切り替え
- (void)cameraMode:(VideoProcessorCameraMode)type
{
    switch (type)
    {
        case 0: _isCameraBack = YES; break;
        case 1: _isCameraBack = NO; break;
        case 2: _isCameraBack =! _isCameraBack; break;
    }
    [self stopRunning];
    [self setupWithView:view_]; // 再セットアップ
    [self startRunning];
}

// タップした位置にフォーカスをセット
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

    if ([videoDevice_ isExposurePointOfInterestSupported] && [videoDevice_ isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
    {
        [videoDevice_ lockForConfiguration:nil];
        videoDevice_.exposurePointOfInterest = p;
        videoDevice_.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
        [videoDevice_ unlockForConfiguration];
    }
}

// トーチのオンオフ
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

// トーチが付いているか判別
- (BOOL)isTorchModeSupported
{
    return [videoDevice_ isTorchModeSupported:AVCaptureTorchModeOn];
}

@end