//
//  FEFrameVideoRecorder.h
//  Pods
//
//  Created by YamatoKira on 16/6/6.
//
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "FEFrameVideoItem.h"

/**
 *  视频录制工具类，负责打开摄像头获取视频数据流，以及拍照获取到输出数据
 */

@interface FEFrameVideoRecorder : NSObject

/**
 *  视频输入设备的类型，前置摄像头还是后置摄像头, 默认为后置摄像头
 */
@property (nonatomic, assign) AVCaptureDevicePosition cameraPosition;

- (instancetype)initWithCameraPosition:(AVCaptureDevicePosition)position;

- (AVCaptureVideoPreviewLayer *)videoPreviewLayer;

- (void)startRuning;

- (void)stopRuning;

- (void)asyncGetCaputreImagesTotalFrames:(NSUInteger)frames
                               totalTime:(NSTimeInterval)totalTime
                                 handler:(void (^)(FEFrameVideoItem *item, NSError *error))handler;

@end
