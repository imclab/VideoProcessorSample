//
//  CaptureViewController.m
//  VideoProcessorSample
//
//  Created by hirofumi kaneko on 2013/02/07.
//  Copyright (c) 2013年 hirofumi kaneko. All rights reserved.
//

#import "CaptureViewController.h"

@interface CaptureViewController ()
{
    IBOutlet UIView   * _capture;
    IBOutlet UIButton * _recBtn;

    NormalVideoProcessor * _videoProcessor;
    CALayer * _layer;
}

- (IBAction)rec;

@end


@implementation CaptureViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)drawCapture:(UIImage *)image
{
    CATransform3D transform = CATransform3DIdentity;
    transform = CATransform3DMakeRotation(M_PI_2, 0.0f, 0.0f, 1.0f);
    _layer.transform = transform;
    _layer.contents = (id)[image CGImage];
    _layer.frame = CGRectMake(0, 0, 320, 548);
    [_capture.layer addSublayer:_layer ];
}

- (IBAction)rec
{
    [_videoProcessor rec];
}


#pragma mark - --------------------------------------------------------------------------
#pragma mark - life cycle

- (void)viewDidLoad
{
    LOG_METHOD;
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    _layer = [CALayer layer];

    _videoProcessor = [[NormalVideoProcessor alloc] init];
    [_videoProcessor setDelegate:self];

    if( [_videoProcessor setup] )
    {
        [_videoProcessor startRunning];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
