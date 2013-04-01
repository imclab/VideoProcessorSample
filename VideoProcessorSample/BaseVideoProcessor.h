//
//  BaseVideoProcessor.h
//  VideoProcessorSample
//
//  Created by hirofumi kaneko on 2013/02/17.
//  Copyright (c) 2013年 hirofumi kaneko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface BaseVideoProcessor : NSObject

@property BOOL isRecording;

- (BOOL)setup;
- (void)rec;
- (void)stop;
- (void)startRunning;
- (void)stopRunning;
- (void)remove;

@end
