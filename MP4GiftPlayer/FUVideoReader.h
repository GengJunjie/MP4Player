//
//  FUVideoReader.h
//  AVAssetReader2
//
//  Created by L on 2018/6/13.
//  Copyright © 2018年 千山暮雪. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, FUVideoReaderOrientation) {
        FUVideoReaderOrientationPortrait           = 0,
        FUVideoReaderOrientationLandscapeRight     = 1,
        FUVideoReaderOrientationUpsideDown         = 2,
        FUVideoReaderOrientationLandscapeLeft      = 3,
};

@protocol FUVideoReaderDelegate <NSObject>

@optional
/// 获取视频的宽高
- (void)videoGetWidth:(CGFloat)width height:(CGFloat )height;
// 每一帧视频数据
- (void)videoReaderDidReadVideoBuffer:(CVPixelBufferRef)pixelBuffer;
// 读视频完成
- (void)videoReaderDidFinishReadSuccess:(BOOL)success ;
@end

@interface FUVideoReader : NSObject

@property (nonatomic, weak) id<FUVideoReaderDelegate>delegate ;

@property (nonatomic, strong) NSURL *videoURL ;
/// 每秒多少帧  
@property (nonatomic, assign) NSInteger perSecond;
// 视频朝向
@property (nonatomic, assign, readonly) FUVideoReaderOrientation videoOrientation ;

@property (nonatomic, assign) BOOL cyclePlay;

- (instancetype)initWithVideoURL:(NSURL *)videoRUL;

// 读写整个视频
- (void)startRead;
- (void)playbackFinished;

- (void)reStartPlay;
- (void)destroyPlay;

@end
