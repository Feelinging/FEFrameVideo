//
//  FEFrameVideoItem.h
//  Pods
//
//  Created by YamatoKira on 16/6/6.
//
//

#import <Foundation/Foundation.h>

@class UIImage;

@interface FEFrameVideoItem : NSObject

@property (nonatomic, readonly) UIImage *animatedImage;

@property (nonatomic, readonly) UIImage *reserveAnimatedImage;

@property (nonatomic, readonly) NSArray<NSData *> *imageDatas;

@property (nonatomic, readonly) CGFloat fps;

+ (instancetype)itemWithDatas:(NSArray<NSData *> *)imageDatas fps:(CGFloat)fps;

- (void)saveGifToAlbumWithCompletion:(void (^)(BOOL succeed, NSError *error))compltetion;

- (void)saveVideoToAlbumWithCompletion:(void (^)(BOOL succeed, NSError *error))completion;

@end
