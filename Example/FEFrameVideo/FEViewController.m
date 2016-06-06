//
//  FEViewController.m
//  FEFrameVideo
//
//  Created by Kira on 06/06/2016.
//  Copyright (c) 2016 Kira. All rights reserved.
//

#import "FEViewController.h"
#import "FEFrameVideoRecorder.h"

@interface FEViewController ()

@end

@implementation FEViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    FEFrameVideoRecorder *recorder = [[FEFrameVideoRecorder alloc] initWithCameraPosition:AVCaptureDevicePositionBack];
    
    CALayer *layer = recorder.videoPreviewLayer;
    layer.frame = self.view.bounds;
    [self.view.layer addSublayer:layer];
    
    [recorder startRuning];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
