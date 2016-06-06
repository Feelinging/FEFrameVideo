//
//  FEFrameVideoRecorder.m
//  Pods
//
//  Created by YamatoKira on 16/6/6.
//
//

#import "FEFrameVideoRecorder.h"

typedef (^PropertyChangeBlock) (AVCaptureDevice *device);

@interface FEFrameVideoRecorder ()

// AVCapture
@property (nonatomic, strong) AVCaptureSession *captureSession;

@property (nonatomic, strong) AVCaptureDeviceInput *captureDeviceInput;

@property (nonatomic, strong) AVCaptureStillImageOutput *captureOutput;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;


// screenShot
@property (nonatomic, weak) NSTimer *screenShotTimer;

@property (nonatomic, assign) NSUInteger screenShotTotalFrames;

@property (nonatomic, strong) NSMutableArray *imageDatas;

@property (nonatomic, copy) void (^screenShotCompleteHandler)(FEFrameVideoItem *item, NSError *error);

@end

@implementation FEFrameVideoRecorder

#pragma mark initialize
- (instancetype)initWithCameraPosition:(AVCaptureDevicePosition)position {
    if (self = [super init]) {
        [self baseConfig];
        
        self.cameraPosition = position;
    }
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        [self baseConfig];
        
        self.cameraPosition = AVCaptureDevicePositionBack;
    }
    return self;
}

- (void)baseConfig {
    _captureSession = [[AVCaptureSession alloc] init];
    
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {//设置分辨率
        _captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
    }
    
    _videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
    _videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _videoPreviewLayer.masksToBounds = YES;
    
    _captureOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = @{AVVideoCodecKey:AVVideoCodecJPEG};
    [_captureOutput setOutputSettings:outputSettings];
    
    if ([_captureSession canAddOutput:_captureOutput]) {
        [_captureSession addOutput:_captureOutput];
    }
    else {
        NSLog(@"can't add output");
    }
}

#pragma mark public method
- (void)startRuning {
    [self.captureSession startRunning];
}

- (void)stopRuning {
    [self.captureSession stopRunning];
}

- (void)asyncGetCaputreImagesTotalFrames:(NSUInteger)frames totalTime:(NSTimeInterval)totalTime handler:(void (^)(FEFrameVideoItem *, NSError *))handler {
    
    if (self.screenShotTimer) {
        [self.screenShotTimer invalidate];
    }
    
    self.imageDatas = [NSMutableArray arrayWithCapacity:frames];
    self.screenShotTotalFrames = frames;
    self.screenShotCompleteHandler = handler;
    
    NSTimer *timer = [NSTimer timerWithTimeInterval:totalTime / frames target:self selector:@selector(screenShotTimerInvoke:) userInfo:nil repeats:YES];
    
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    
    [timer fire];
    
    self.screenShotTimer = timer;
}


#pragma mark private method
/**
 *  取得指定位置的摄像头
 *
 *  @param position 摄像头位置
 *
 *  @return 摄像头设备
 */
- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position {
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position]==position) {
            return camera;
        }
    }
    return nil;
}

/**
 *  改变设备属性的统一操作方法
 *
 *  @param propertyChange 属性改变操作
 */
- (void)changeDeviceProperty:(PropertyChangeBlock)propertyChange {
    AVCaptureDevice *captureDevice= [self.captureDeviceInput device];
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }else{
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}

/**
 *  改变视频输入源
 *
 *  @param newInput 新的视频输入源
 */
- (void)changeDeviceInput:(AVCaptureDeviceInput *)newInput {
    //
    [self.captureSession beginConfiguration];
    
    if (self.captureDeviceInput) {
       [self.captureSession removeInput:self.captureDeviceInput];
    }
    
    if ([self.captureSession canAddInput:newInput]) {
        [self.captureSession addInput:newInput];
        self.captureDeviceInput = newInput;
    }
    else {
        NSLog(@"can't add input");
    }

    [self.captureSession commitConfiguration];
}

- (void)screenShotTimerInvoke:(NSTimer *)timer {
    //根据设备输出获得连接
    AVCaptureConnection *captureConnection=[self.captureOutput connectionWithMediaType:AVMediaTypeVideo];
    
    //根据连接取得设备输出的数据
    [self.captureOutput captureStillImageAsynchronouslyFromConnection:captureConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (imageDataSampleBuffer) {
            NSData *imageData=[AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            
            [self.imageDatas addObject:imageData];
            
            if (self.imageDatas.count == self.screenShotTotalFrames) {
                if (self.screenShotCompleteHandler) {
                    self.screenShotCompleteHandler([FEFrameVideoItem itemWithDatas:self.imageDatas.copy], nil);
                    self.screenShotCompleteHandler = nil;
                }
                
                [timer invalidate];
                
                self.screenShotTimer = nil;
            }
        }
    }];
}

#pragma mark getter&&setter
- (void)setCameraPosition:(AVCaptureDevicePosition)cameraPosition {
    if (_cameraPosition != cameraPosition) {
        _cameraPosition = cameraPosition;
        
        AVCaptureDevice *device = [self getCameraDeviceWithPosition:cameraPosition];
        NSError *error;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
        if (!error) {
            [self changeDeviceInput:input];
        }
        else {
            NSLog(@"change input error");
        }
    }
}

@end
