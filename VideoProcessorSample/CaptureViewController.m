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
    NormalVideoProcessor * _videoProcessor;
}

@property IBOutlet UIImageView * imageView;
@property IBOutlet UIButton * recBtn;

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
    _imageView.image = image;
//    self.view.layer.contents = (id)image.CGImage;
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
