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

    NormalVideoProcessor    * normalVideoProcessor_;
    FastWriteVideoProcessor * fastWriterVideoProcessor_;
    BaseVideoProcessor      * videoProcessor_;
    CALayer * layer_;
}

- (IBAction)rec;
- (IBAction)stop:(id)sender;

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
    [capture_.layer addSublayer:layer_];
}


#pragma mark - --------------------------------------------------------------------------
#pragma mark - Action

- (IBAction)rec
{
    [videoProcessor_ rec];
}

- (IBAction)stop:(id)sender
{
    [videoProcessor_ stop];
}


#pragma mark - --------------------------------------------------------------------------
#pragma mark - life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    layer_ = [CALayer layer];

    if ( [_demo isEqualToString:@"Demo1"] )
    {
        videoProcessor_ = [[NormalVideoProcessor alloc] init];
        [(NormalVideoProcessor *)videoProcessor_ setDelegate:self];
    }
    else if ( [_demo isEqualToString:@"Demo2"] )
    {
        videoProcessor_ = [[FastWriteVideoProcessor alloc] init];
        [(FastWriteVideoProcessor *)videoProcessor_ setDelegate:self];
    }

    if( [videoProcessor_ setup] ) { [videoProcessor_ startRunning]; }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [videoProcessor_ stop];
}

@end
