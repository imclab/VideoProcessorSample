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
    IBOutlet UIView   * capture_;
    IBOutlet UIButton * recBtn_;

    NormalVideoProcessor * videoProcessor_;
    CALayer * layer_;
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
    layer_.transform = transform;
    layer_.contents = (id)[image CGImage];
    layer_.frame = CGRectMake(0, 0, 320, 548);
    [capture_.layer addSublayer:layer_ ];
}

- (IBAction)rec
{
    [videoProcessor_ rec];
}


#pragma mark - --------------------------------------------------------------------------
#pragma mark - life cycle

- (void)viewDidLoad
{
    LOG_METHOD;
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    layer_ = [CALayer layer];

    videoProcessor_ = [[NormalVideoProcessor alloc] init];
    [videoProcessor_ setDelegate:self];

    if( [videoProcessor_ setup] )
    {
        [videoProcessor_ startRunning];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
