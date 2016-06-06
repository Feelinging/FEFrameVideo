//
//  FEFrameVideoPickerController.h
//  Pods
//
//  Created by YamatoKira on 16/6/6.
//
//

#import <UIKit/UIKit.h>
#import "FEFrameVideoRecorder.h"
#import "FEFrameVideoItem.h"
#import "FEFrameVideoConstant.h"

@class FEFrameVideoPickerController;

typedef void (^FEFrameVideoInfoBlock)(FEFrameVideoItem *item, FEFrameVideoPickerController *controller);

@interface FEFrameVideoPickerController : UIViewController

+ (instancetype)pickerWithInfoBlock:(FEFrameVideoInfoBlock)block;

@end
