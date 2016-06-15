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

@interface FEFrameVideoDetailController : UIViewController

@property (nonatomic, readonly) FEFrameVideoItem *item;

+ (instancetype)detailWithItem:(FEFrameVideoItem *)item;

@end

@implementation FEFrameVideoDetailController

#pragma mark initialize
+ (instancetype)detailWithItem:(FEFrameVideoItem *)item {
    return [[self alloc] initWithItem:item];
}

- (instancetype)initWithItem:(FEFrameVideoItem *)item {
    if (self = [super init]) {
        _item = item;
    }
    return self;
}

#pragma mark lifeCycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initUI];
}

#pragma mark private method
- (void)initUI {
    self.view.backgroundColor = [UIColor whiteColor];
    
    if (self.item.reserveAnimatedImage.images.count) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.animationImages = self.item.reserveAnimatedImage.images;
        imageView.image = self.item.reserveAnimatedImage.images[0];
        imageView.animationRepeatCount = 0;
        imageView.animationDuration = self.item.reserveAnimatedImage.duration;
        [imageView startAnimating];
        
        [self.view addSubview:imageView];
    }
    
    UIButton *cancel = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancel setTitle:@"返回" forState:UIControlStateNormal];
    [cancel setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    cancel.backgroundColor = [UIColor colorWithWhite:1 alpha:0.7];
    [cancel addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventTouchUpInside];
    cancel.clipsToBounds = YES;
    cancel.layer.cornerRadius = 5.f;
    
    cancel.frame = CGRectMake(10, 10, 50, 34);
    cancel.titleLabel.font = [UIFont systemFontOfSize:14.f];
    [self.view addSubview:cancel];
    
    UIButton *save = [UIButton buttonWithType:UIButtonTypeCustom];
    [save setTitle:@"Save" forState:UIControlStateNormal];
    [save setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    save.backgroundColor = [UIColor colorWithWhite:1 alpha:0.7];
    [save addTarget:self action:@selector(saveToAlbum:) forControlEvents:UIControlEventTouchUpInside];
    
    save.clipsToBounds = YES;
    save.layer.cornerRadius = 5.f;
    save.titleLabel.font = [UIFont systemFontOfSize:14.f];
    save.frame = CGRectMake(self.view.bounds.size.width - 60, 10, 50, 34);
    [self.view addSubview:save];
}

- (BOOL)prefersStatusBarHidden {
    return  YES;
}

- (void)dismiss:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveToAlbum:(UIBarButtonItem *)sender {
    sender.enabled = NO;
    
    __weak typeof(self) weakSelf = self;
    [self.item saveVideoToAlbumWithCompletion:^(BOOL succeed, NSError *error) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
        label.backgroundColor = [UIColor lightGrayColor];
        label.layer.cornerRadius = 5.f;
        label.clipsToBounds = YES;
        label.text = succeed ? @"保存成功" : @"保存失败";
        label.center = weakSelf.view.center;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:15.f];
        [weakSelf.view addSubview:label];
        
        [UIView animateWithDuration:2 animations:^{
            label.alpha = 0;
        } completion:^(BOOL finished) {
            [label removeFromSuperview];
            
            sender.enabled = YES;
        }];
    }];
}

@end

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
    takeButton.layer.cornerRadius = 30;
    takeButton.backgroundColor = [UIColor lightGrayColor];
    takeButton.frame = CGRectMake(self.view.center.x - 30, self.view.bounds.size.height - 100, 60, 60);
    takeButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    
    [self.view addSubview:takeButton];
    
    [takeButton addTarget:self action:@selector(takeButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    
    // change input
    UIButton *changeInput = [UIButton buttonWithType:UIButtonTypeCustom];
    
    changeInput.titleLabel.font = [UIFont systemFontOfSize:13.f];
    [changeInput setTitle:@"C" forState:UIControlStateNormal];
    [changeInput setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    
    changeInput.frame = CGRectOffset(takeButton.frame, 100, 0);
    [changeInput addTarget:self action:@selector(changeInput:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:changeInput];
}


- (void)takeButtonClick:(UIButton *)sender {
    sender.enabled = NO;
    
    __weak typeof(self) weakSelf = self;
    [self.recorder asyncGetCaputreImagesTotalFrames:10 totalTime:1 handler:^(FEFrameVideoItem *item, NSError *error) {
        if (weakSelf.infoBlock) {
            weakSelf.infoBlock(item, weakSelf);
        }
        sender.enabled = YES;
        
        //
        [weakSelf showDetail:item];
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

- (void)showDetail:(FEFrameVideoItem *)item {
    FEFrameVideoDetailController *detail = [FEFrameVideoDetailController detailWithItem:item];
    
    [self presentViewController:detail animated:YES completion:nil];
}

@end
