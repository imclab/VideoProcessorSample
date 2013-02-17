//
//  ViewController.m
//  VideoProcessorSample
//
//  Created by hirofumi kaneko on 2013/02/07.
//  Copyright (c) 2013年 hirofumi kaneko. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    CaptureViewController * _vc = (CaptureViewController *)[segue destinationViewController];
    _vc.demo = [segue identifier];
}


#pragma mark - --------------------------------------------------------------------------
#pragma mark - life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
