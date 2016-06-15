//
//  FEFrameVideoItem.m
//  Pods
//
//  Created by YamatoKira on 16/6/6.
//
//

#import "FEFrameVideoItem.h"
#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>

/**
 *  把UIImage转换为NSData，对animatedImage做特殊处理
 *
 *  @param image 源数据
 *  @param error
 *
 *  @return 转换后大data
 */

static inline NSData *ff_convertImageToData(UIImage *image, NSError **error) {
    if (!image) {
        return nil;
    }
    
    NSData *data;
    
    if (image.images.count <= 1) {
        data = UIImageJPEGRepresentation(image, 0.9);
    }
    else {
        size_t frameCount = image.images.count;
        
        NSMutableData *mutableData = [NSMutableData data];
        CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)mutableData, kUTTypeGIF, frameCount, NULL);
        
        NSDictionary *imageProperties = @{ (__bridge NSString *)kCGImagePropertyGIFDictionary: @{
                                                   (__bridge NSString *)kCGImagePropertyGIFLoopCount: @(0)
                                                   }
                                           };
        CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)imageProperties);
        
        for (size_t idx = 0; idx < image.images.count; idx++) {
            CGFloat duration = [image.images[idx] duration];
            NSDictionary *frameProperties = @{
                                              (__bridge NSString *)kCGImagePropertyGIFDictionary: @{
                                                      (__bridge NSString *)kCGImagePropertyGIFDelayTime: @(duration)
                                                      }
                                              };
            
            CGImageDestinationAddImage(destination, [[image.images objectAtIndex:idx] CGImage], (__bridge CFDictionaryRef)frameProperties);
        }
        
        BOOL success = CGImageDestinationFinalize(destination);
        CFRelease(destination);
        
        if (!success) {
            *error = [[NSError alloc] initWithDomain:@"com.FEFrameVideo.errorDomain" code:1 userInfo:@{@"description":@"convert into data failed"}];
            
            NSLog(@"convertIntoData failed");
        }
        data = [NSData dataWithData:mutableData];
    }
    
    return data;
}

/**
 *  把CGImageRef转为CVPixelBufferRef
 *
 *  @param image 源CGImageRef
 *  @param size  目标size
 *
 *  @return 转换后的buffer
 */
static inline CVPixelBufferRef ff_convertUIImageToBuffer(CGImageRef image , CGSize size, CGFloat scale) {
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width * (scale > 0 ? scale : [UIScreen mainScreen].scale),
                                          size.height * (scale > 0 ? scale : [UIScreen mainScreen].scale), kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    if (status != kCVReturnSuccess || pxbuffer == NULL) return NULL;
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    if (pxdata == NULL) return NULL;
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width * (scale > 0 ? scale : [UIScreen mainScreen].scale),
                                                 size.height * (scale > 0 ? scale : [UIScreen mainScreen].scale), 8, 4*size.width * (scale > 0 ? scale : [UIScreen mainScreen].scale), rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    if (context == NULL) return NULL;
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

@implementation FEFrameVideoItem

@synthesize animatedImage = _animatedImage, reserveAnimatedImage = _reserveAnimatedImage;

#pragma mark initialize
+ (instancetype)itemWithDatas:(NSArray<NSData *> *)imageDatas fps:(CGFloat)fps {
    return [[self alloc] initWithDatas:imageDatas fps:fps];
}

- (instancetype)initWithDatas:(NSArray<NSData *> *)imageDatas fps:(CGFloat)fps {
    if (self = [super init]) {
        _imageDatas = imageDatas;
        _fps = fps;
    }
    return self;
}

#pragma mark public method
- (void)saveGifToAlbumWithCompletion:(void (^)(BOOL, NSError *))compltetion {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSData *data = ff_convertImageToData(self.reserveAnimatedImage, nil);
        
        __weak typeof(self) weakSelf = self;
        [[[ALAssetsLibrary alloc] init] writeImageDataToSavedPhotosAlbum:data metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
            if (compltetion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    compltetion(!error, error);
                });
            }
        }];
    });
}

- (void)saveVideoToAlbumWithCompletion:(void (^)(BOOL, NSError *))completion {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @autoreleasepool {
            NSError *error = nil;
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:[self videoPath]]) {
                [[NSFileManager defaultManager] removeItemAtPath:[self videoPath] error:nil];
            }
            
            NSURL *url = [NSURL fileURLWithPath:[self videoPath]];
            
            
            
            AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:
                                          url fileType:AVFileTypeQuickTimeMovie
                                                                      error:&error];
            
            
            if (error) {
                if (completion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(NO, error);;
                    });
                }
                return;
            }
            
            UIImage *sample = self.reserveAnimatedImage.images[0];
            
            CGFloat width = sample.size.width * sample.scale;
            CGFloat height = sample.size.height * sample.scale;
            
            NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                           AVVideoCodecH264, AVVideoCodecKey,
                                           [NSNumber numberWithInt:width], AVVideoWidthKey,
                                           [NSNumber numberWithInt:height], AVVideoHeightKey,
                                           nil];
            
            AVAssetWriterInput* writerInput = [AVAssetWriterInput
                                               assetWriterInputWithMediaType:AVMediaTypeVideo
                                               outputSettings:videoSettings];
            
            
            AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                             assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                             sourcePixelBufferAttributes:nil];
            
            
            if (!writerInput || ![videoWriter canAddInput:writerInput]) {
                if (completion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(NO, nil);
                    });
                }
                return;
            }
            
            // add input
            [videoWriter addInput:writerInput];
            
            
            //Start a session:
            [videoWriter startWriting];
            [videoWriter startSessionAtSourceTime:kCMTimeZero];
            
            //convert uiimage to CGImage.
            CGFloat fps = 2 * self.fps;
            NSInteger frameCount = 0;
            
            for (int j = 0; j < 4; j ++) {
                for (UIImage *image in self.reserveAnimatedImage.images) {
                    BOOL appendOK = NO;
                    NSInteger tryCount = 0;
                    while (!appendOK && tryCount < 5) {
                        if (adaptor.assetWriterInput.isReadyForMoreMediaData) {
                            CVPixelBufferRef buffer = ff_convertUIImageToBuffer(image.CGImage, [UIScreen mainScreen].bounds.size, 0);
                            
                            
                            CMTime time = CMTimeMake(frameCount, fps);
                            
                            appendOK = [adaptor appendPixelBuffer:buffer withPresentationTime:time];
                            
                            if (appendOK) {
                                frameCount ++;
                            }
                            else {
                                NSError *error = videoWriter.error;
                                if(error!=nil) {
                                    NSLog(@"Unresolved error %@,%@.", error, [error userInfo]);
                                }
                            }
                            
                            CVPixelBufferRelease(buffer);
                        }
                        else {
                            [NSThread sleepForTimeInterval:0.1];
                        }
                        
                        tryCount ++;
                    }
                }
            }
            
            //Finish the session:
            [writerInput markAsFinished];
            
            [videoWriter finishWritingWithCompletionHandler:^{
                
                CVPixelBufferPoolRelease(adaptor.pixelBufferPool);
                
                // wirte to album
                [[[ALAssetsLibrary alloc] init] writeVideoAtPathToSavedPhotosAlbum:url completionBlock:^(NSURL *assetURL, NSError *error) {
                    
                    // remove tmp cache
                    [[NSFileManager defaultManager] removeItemAtPath:[self videoPath] error:nil];
                    
                    if (completion) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(assetURL != nil, error);
                        });
                    }
                }];
            }];
        }
    });
}

#pragma mark private method
- (NSString *)videoPath {
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"ff_frameVideoOutPut.mov"];
}

#pragma mark getter&&setter
- (UIImage *)animatedImage {
    if (!_animatedImage) {
        if (self.imageDatas.count) {
            NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:self.imageDatas.count];
            for (NSData *data in self.imageDatas) {
                UIImage *image = [UIImage imageWithData:data];
                if (image) {
                    [tmp addObject:image];
                }
            }
            _animatedImage = [UIImage animatedImageWithImages:tmp.copy duration:tmp.count / self.fps];
        }
    }
    return _animatedImage;
}

- (UIImage *)reserveAnimatedImage {
    if (!_reserveAnimatedImage) {
        if (self.imageDatas.count) {
            NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:2 * self.imageDatas.count];
            for (NSData *data in self.imageDatas) {
                UIImage *image = [UIImage imageWithData:data];
                if (image) {
                    [tmp addObject:image];
                }
            }
            
            for (NSData *data in self.imageDatas.reverseObjectEnumerator.allObjects) {
                UIImage *image = [UIImage imageWithData:data];
                if (image) {
                    [tmp addObject:image];
                }
            }
            
            _reserveAnimatedImage = [UIImage animatedImageWithImages:tmp.copy duration:tmp.count / self.fps];
        }
    }
    return _reserveAnimatedImage;
}

@end
