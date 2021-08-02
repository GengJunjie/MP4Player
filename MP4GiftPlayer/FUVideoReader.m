//
//  FUVideoReader.m
//  AVAssetReader2
//
//  Created by L on 2018/6/13.
//  Copyright © 2018年 千山暮雪. All rights reserved.
//

#import "FUVideoReader.h"
#import <UIKit/UIKit.h>

# define ONE_FRAME_DURATION 0.03

@interface FUVideoReader ()
{
    CMSampleBufferRef firstFrame ;
    
    CVPixelBufferRef renderTarget ;
}

/// 播放器
@property(nonatomic , strong) AVPlayer *player;
/// video 输出对象
@property(nonatomic , strong) AVPlayerItemVideoOutput *videoOutput;

// 视频朝向
@property (nonatomic, assign, readwrite) FUVideoReaderOrientation videoOrientation ;
// 定时器
@property (nonatomic, strong) CADisplayLink *displayLink;

@end

@implementation FUVideoReader

-(instancetype)initWithVideoURL:(NSURL *)videoRUL {
    self = [super init];
    if (self) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkCallback:)];
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        _displayLink.paused = YES;
        _videoURL = videoRUL ;
        [self configAssetReader];
    }
    return self ;
}

-(void)configAssetReader {
    _player = [[AVPlayer alloc] init];
    NSDictionary *pixBufferAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]};
    _videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixBufferAttributes];
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:_videoURL];
    [item addOutput:_videoOutput];
    [_player replaceCurrentItemWithPlayerItem:item];
    [_videoOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:ONE_FRAME_DURATION];
    //给AVPlayerItem添加播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished) name:AVPlayerItemDidPlayToEndTimeNotification object:item];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFailed:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:item];
}

// 开始读
- (void)startRead {
    if (!_videoURL) {
        [self readVideoFinished];
        return;
    }
    _displayLink.paused = NO;
    [_player play];
}

- (void)reStartPlay {
    if (!_videoURL) {
        [self readVideoFinished];
        return;
    }
    [_player seekToTime:kCMTimeZero];

    _displayLink.paused = NO;
    [_player play];
}

- (void)destroyPlay {
    _player = nil;
    self.displayLink.paused = YES ;
    [_displayLink invalidate];
    _displayLink = nil ;
}

- (void)playbackFinished{
    NSLog(@"播放结束");
    [self readVideoFinished];
}

- (void)playbackFailed:(NSNotification *)noti {
//    [Toast show:MyLocal(@"Failed")];
    [self readVideoFinished];
    if ([noti respondsToSelector:@selector(userInfo)]) {
//        [LPLogService addlogContent:[NSString stringWithFormat:@"%@", noti.userInfo] topic:@"MP4" source:@"MP4礼物player 失败" isError:YES];
    }
}



- (void)displayLinkCallback:(CADisplayLink *)displatLink {
    CMTime outputItemTime = kCMTimeInvalid;
    /// 计算下一次同步时间，当屏幕下次刷新
    CFTimeInterval nextVSync = ([displatLink timestamp]+[displatLink duration]);
    outputItemTime = [[self videoOutput] itemTimeForHostTime:nextVSync];
    if ([self.videoOutput hasNewPixelBufferForItemTime:outputItemTime]) {
        CVPixelBufferRef pixelBuffer = NULL;
        pixelBuffer = [_videoOutput copyPixelBufferForItemTime:outputItemTime itemTimeForDisplay:NULL];
        [self readVideoBuffer:pixelBuffer];
    }
}

static BOOL isVideoFirst = YES ;
- (void)readVideoBuffer:(CVPixelBufferRef )pixelBuffer {
    if (self.player.rate == 1) {
        if (isVideoFirst) {
            isVideoFirst = NO;
            return ;
        }
        if (pixelBuffer) {
            // 数据保存到 renderTarget
            CVPixelBufferLockBaseAddress(pixelBuffer, 0) ;
            
            int w0 = (int)CVPixelBufferGetWidth(pixelBuffer) ;
            int h0 = (int)CVPixelBufferGetHeight(pixelBuffer) ;
            if ([self.delegate respondsToSelector:@selector(videoGetWidth:height:)]) {
                [self.delegate videoGetWidth:w0 height:h0];
            }
            void *byte0 = CVPixelBufferGetBaseAddress(pixelBuffer) ;
            
            if (!renderTarget) {
                [self createPixelBufferWithSize:CGSizeMake(w0, h0)];
            }
            CVPixelBufferLockBaseAddress(renderTarget, 0) ;
            int w1 = (int)CVPixelBufferGetWidth(renderTarget) ;
            int h1 = (int)CVPixelBufferGetHeight(renderTarget) ;
            if (w0 != w1 || h0 != h1) {
                [self createPixelBufferWithSize:CGSizeMake(w0, h0)];
            }
            void *byte1 = CVPixelBufferGetBaseAddress(renderTarget) ;
            memcpy(byte1, byte0, w0 * h0 * 4) ;
            CVPixelBufferUnlockBaseAddress(renderTarget, 0);
            CVPixelBufferUnlockBaseAddress(pixelBuffer, 0) ;
            if (self.delegate && [self.delegate respondsToSelector:@selector(videoReaderDidReadVideoBuffer:)] && !self.displayLink.paused) {
                [self.delegate videoReaderDidReadVideoBuffer:pixelBuffer];
            }
            CFRelease(pixelBuffer);
        }
    }
}

- (void)readVideoFinished {
    if (_cyclePlay && self.delegate) {
        [self reStartPlay];
    }
    else {
        _player = nil;
        self.displayLink.paused = YES ;
        if (self.delegate && [self.delegate respondsToSelector:@selector(videoReaderDidFinishReadSuccess:)]) {
            [self.delegate videoReaderDidFinishReadSuccess:true];
        }
        [_displayLink invalidate];
        _displayLink = nil ;
    }
    
}

- (void)createPixelBufferWithSize:(CGSize)size  {

    if (!renderTarget) {
        NSDictionary* pixelBufferOptions = @{ (NSString*) kCVPixelBufferPixelFormatTypeKey :
                                                  @(kCVPixelFormatType_32BGRA),
                                              (NSString*) kCVPixelBufferWidthKey : @(size.width),
                                              (NSString*) kCVPixelBufferHeightKey : @(size.height),
                                              (NSString*) kCVPixelBufferOpenGLESCompatibilityKey : @YES,
                                              (NSString*) kCVPixelBufferIOSurfacePropertiesKey : @{}};

        CVPixelBufferCreate(kCFAllocatorDefault,
                            size.width, size.height,
                            kCVPixelFormatType_32BGRA,
                            (__bridge CFDictionaryRef)pixelBufferOptions,
                            &renderTarget);
    }
}

- (void)dealloc{
    NSLog(@"FUVideoReader dealloc");
    if (renderTarget) {
        CVPixelBufferRelease(renderTarget);
    }
    if (firstFrame) {
        CFRelease(firstFrame);
    }
}

@end
