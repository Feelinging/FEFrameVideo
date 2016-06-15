//
//  FEFrameVideoRecorder.m
//  Pods
//
//  Created by YamatoKira on 16/6/6.
//
//

#import "FEFrameVideoRecorder.h"
#import <CoreImage/CoreImage.h>

typedef void (^PropertyChangeBlock) (AVCaptureDevice *device);

@interface FEFrameVideoRecorder ()<AVCaptureVideoDataOutputSampleBufferDelegate>

// AVCapture
@property (nonatomic, strong) AVCaptureSession *captureSession;

@property (nonatomic, strong) AVCaptureDeviceInput *captureDeviceInput;

@property (nonatomic, strong) AVCaptureVideoDataOutput *captureOutput;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;


// screenShot
@property (nonatomic, strong) UIImage *currentBufferImage;

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
    
    _captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_captureOutput setSampleBufferDelegate:self queue:dispatch_queue_create("com.feeling.recorderOutput", DISPATCH_QUEUE_SERIAL)];
    
    _captureOutput.videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey,
                            nil];
    
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
    
    [timer setFireDate:[[NSDate date] dateByAddingTimeInterval:0.1]];
    
    self.screenShotTimer = timer;
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (sampleBuffer && self.screenShotTimer) {
        self.currentBufferImage = [self getImageFromSampleBufferRef:sampleBuffer];
        if (self.cameraPosition == AVCaptureDevicePositionFront) {
            
        }
    }
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
    // do animation
    [self doKirakiraAnimation];
    
    //
    NSData *data = UIImageJPEGRepresentation(self.currentBufferImage, 0.5);
    if (data) {
        [self.imageDatas addObject:data];
        if (self.imageDatas.count >= self.screenShotTotalFrames) {
            if (self.screenShotCompleteHandler) {
                self.screenShotCompleteHandler([FEFrameVideoItem itemWithDatas:self.imageDatas.copy fps:1.0 / self.screenShotTimer.timeInterval], nil);
            }
            [timer invalidate];
            self.screenShotTimer = nil;
        }
    }
}

- (UIImage *)getImageFromSampleBufferRef:(CMSampleBufferRef)sampleBuffer {
    CMSampleBufferRef retainedBuffer = sampleBuffer;
    
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationRight];
    
    // if is front camera flip the image
    if (self.cameraPosition == AVCaptureDevicePositionFront) {
        image = [UIImage imageWithCGImage:image.CGImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationLeftMirrored];
    }
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    // make a image that orientation is UIImageOrientationUp
    CGSize size = CGSizeMake(height/[UIScreen mainScreen].scale, width/[UIScreen mainScreen].scale);
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return (image);
}

- (void)doKirakiraAnimation {
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor whiteColor];
    view.alpha = 0.0;
    view.frame = self.videoPreviewLayer.bounds;
    
    [self.videoPreviewLayer addSublayer:view.layer];
    
    [UIView animateWithDuration:self.screenShotTimer.timeInterval/2.0 animations:^{
        view.alpha = 1.0;
    } completion:^(BOOL finished) {
        [view.layer removeFromSuperlayer];
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
            //
            [self changeDeviceInput:input];
        }
        else {
            NSLog(@"change input error");
        }
    }
}

@end
