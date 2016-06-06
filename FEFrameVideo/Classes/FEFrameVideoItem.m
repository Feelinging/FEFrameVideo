//
//  FEFrameVideoItem.m
//  Pods
//
//  Created by YamatoKira on 16/6/6.
//
//

#import "FEFrameVideoItem.h"
#import <UIKit/UIKit.h>

@implementation FEFrameVideoItem

@synthesize animatedImage = _animatedImage, reserveAnimatedImage = _reserveAnimatedImage;

#pragma mark initialize
+ (instancetype)itemWithDatas:(NSArray<NSData *> *)imageDatas {
    return [[self alloc] initWithDatas:imageDatas];
}

- (instancetype)initWithDatas:(NSArray<NSData *> *)imageDatas {
    if (self = [super init]) {
        _imageDatas = imageDatas;
    }
    return self;
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
            _animatedImage = [UIImage animatedImageWithImages:tmp.copy duration:tmp.count * 0.1];
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
            
            _reserveAnimatedImage = [UIImage animatedImageWithImages:tmp.copy duration:tmp.count * 0.05];
        }
    }
    return _reserveAnimatedImage;
}

- (void)saveGifToAlbum {
    
}

- (void)saveVideoToAlbum {
    
}

@end
