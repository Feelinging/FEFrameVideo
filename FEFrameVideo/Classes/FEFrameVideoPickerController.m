//
//  FEFrameVideoPickerController.m
//  Pods
//
//  Created by YamatoKira on 16/6/6.
//
//

#import "FEFrameVideoPickerController.h"
#import "FEFrameVideoRecorder.h"
#import <MediaPlayer/MediaPlayer.h>

@interface FEFrameVideoPickerController ()

@property (nonatomic, copy) FEFrameVideoInfoBlock infoBlock;

@property (nonatomic, strong) FEFrameVideoRecorder *recorder;

@end

@implementation FEFrameVideoPickerController

#pragma mark initialize
+ (instancetype)pickerWithInfoBlock:(FEFrameVideoInfoBlock)block {
    return [[self alloc] initWithInfoBlock:block];
}

- (instancetype)initWithInfoBlock:(FEFrameVideoInfoBlock)block {
    if (self = [super init]) {
        _infoBlock = block;
    }
    return self;
}

#pragma mark lifeCycle
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.recorder startRuning];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self.recorder stopRuning];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.recorder = [[FEFrameVideoRecorder alloc] initWithCameraPosition:AVCaptureDevicePositionBack];
    
    [self initUI];
}

#pragma mark override method
- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark private method
- (void)initUI {
    //
    CALayer *videoPreviewLayer = self.recorder.videoPreviewLayer;
    videoPreviewLayer.frame = self.view.bounds;
    videoPreviewLayer.cornerRadius = 5.f;
    [self.view.layer addSublayer:videoPreviewLayer];
    
    
    UIButton *takeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    takeButton.backgroundColor = [UIColor redColor];
    
    takeButton.frame = CGRectMake(100, self.view.bounds.size.height - 200, 60, 60);
    
    [self.view addSubview:takeButton];
    
    [takeButton addTarget:self action:@selector(takeButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    
    // change input
    UIButton *changeInput = [UIButton buttonWithType:UIButtonTypeCustom];
    changeInput.backgroundColor = [UIColor yellowColor];
    changeInput.frame = CGRectOffset(takeButton.frame, 100, 0);
    [changeInput addTarget:self action:@selector(changeInput:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:changeInput];
}


- (void)takeButtonClick:(UIButton *)sender {
    sender.enabled = NO;
    
    __weak typeof(self) weakSelf = self;
    [self.recorder asyncGetCaputreImagesTotalFrames:5 totalTime:1 handler:^(FEFrameVideoItem *item, NSError *error) {
        if (weakSelf.infoBlock) {
            weakSelf.infoBlock(item, weakSelf);
        }
        sender.enabled = YES;
    }];
}

- (void)changeInput:(UIButton *)button {
    AVCaptureDevicePosition current = self.recorder.cameraPosition;
    
    AVCaptureDevicePosition toPosition = AVCaptureDevicePositionBack;
    if (current == AVCaptureDevicePositionBack) {
        toPosition = AVCaptureDevicePositionFront;
    }
    
    self.recorder.cameraPosition = toPosition;
}

@end
