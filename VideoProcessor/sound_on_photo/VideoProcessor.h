//
//  VideoProcessor.h
//
//  Created by hirofumi kaneko on 2013/02/07.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <QuartzCore/QuartzCore.h>

// カメラモードを変更するときに選択
typedef NS_ENUM(NSInteger, VideoProcessorCameraMode)
{
    VideoProcessorCameraModeBack = 0,
    VideoProcessorCameraModeFront,
    VideoProcessorCameraModeReverse
};

// カメラのトーチを変更するときに選ぶ
typedef NS_ENUM(NSInteger, VideoProcessorTorchMode)
{
    VideoProcessorTorchModeOff = 0,
    VideoProcessorTorchModeOn,
    VideoProcessorTorchModeReverse
};


@protocol VideoProcessorDelegate;

@interface VideoProcessor : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>

@property BOOL isRecording;

// フロントカメラ or バックカメラ
@property BOOL isCameraBack;

// デリゲート
@property (weak, nonatomic) id<VideoProcessorDelegate> delegate;

// AVFoundationのセットアップ 表示するクラスのViewを渡す
- (BOOL)setupWithView:(UIView *)view;

// キャプチャースタートさせる
- (void)startRunning;

// キャプチャーストップさせる
- (void)stopRunning;

// キャプチャーから撮影する
- (void)take;

// キャプチャーの再開をさせる
- (void)resume;

// カメラのフロントバック切り替え
- (void)cameraMode:(VideoProcessorCameraMode)type;

// タップした位置にフォーカスをセット
- (void)setFocusWithSize:(CGSize)drawViewSize focusPoint:(CGPoint)point;

// トーチのオンオフ切り替え
- (void)torchMode:(VideoProcessorTorchMode)type;

// キャプチャー表示レイヤーの生成
- (void)addPreviewLayer;

// キャプチャー表示レイヤーの削除
- (void)removePreviewLayer;

// フラッシュをサポートしているかどうか
- (BOOL)isTorchModeSupported;


@end


/**
 * デリゲート
 */
@protocol VideoProcessorDelegate <NSObject>

// 撮影時に実行される
- (void)videoProcessorTakeCapture:(UIImage *)image;

@end