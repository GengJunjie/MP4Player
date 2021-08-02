//
//  ViewController.m
//  MP4GiftPlayer
//
//  Created by 耿俊杰 on 2021/8/2.
//

#import "ViewController.h"
#import "FUVideoReader.h"
#import "FUOpenGLView.h"


@interface ViewController ()<FUVideoReaderDelegate>

@property (nonatomic, strong) FUOpenGLView *glView;
@property (nonatomic, strong) FUVideoReader *videoReader ;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _glView = [[FUOpenGLView alloc] initWithFrame:self.view.bounds];
    _glView.contentMode = FUOpenGLViewContentModeScaleAspectFill;
    [self.view addSubview:_glView];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"blindbox_puzzle_anim" ofType:@"mp4"];
    self.videoReader = [[FUVideoReader alloc] initWithVideoURL:[NSURL fileURLWithPath:filePath]];
//    self.videoReader.cyclePlay = YES;
    self.videoReader.delegate = self;
    [self.videoReader startRead];
}

#pragma mark - FUVideoReaderDelegate

/// 获取视频的宽高
- (void)videoGetWidth:(CGFloat)width height:(CGFloat )height {
    
}
// 每一帧视频数据
- (void)videoReaderDidReadVideoBuffer:(CVPixelBufferRef)pixelBuffer {
    @autoreleasepool {
        [self.glView displayPixelBuffer:pixelBuffer];
    }
}
// 读视频完成
- (void)videoReaderDidFinishReadSuccess:(BOOL)success {
//    [self.videoReader reStartPlay];
}


@end
