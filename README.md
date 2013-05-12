VideoProcessorSample
====================

AVFoundation test in iOS App. (use AVAssetWriterInputPixelBufferAdaptor)

![VideoProcessorSample](http://azzip-azzip.com/assets/img/2013/vps_3.jpg "VideoProcessorSample")

## Usage


### setup
```
videoProcessor_ = [VideoProcessor new];
[videoProcessor_ setDelegate:self];
if ([videoProcessor_ setup])
{
   [videoProcessor_ startRunning];
}
```

### use
```
[videoProcessor_ rec]; // start recording
[videoProcessor_ stop]; // end recording

[videoProcessor_ isRecording] // check
```

### delegate

exsample  
```
// CALayer * layer_ = [CALayer layer];

- (void)drawCapture:(UIImage *)image
{
    CATransform3D transform = CATransform3DIdentity;
    transform = CATransform3DMakeRotation(M_PI_2, 0.0f, 0.0f, 1.0f);
    layer_.transform = transform;
    layer_.contents = (id)[image CGImage];
    layer_.frame = CGRectMake(0, 0, 320, 548);
    [capture_.layer addSublayer:layer_];
}
```


## Blog
http://blog.azzip-azzip.com/2013/04/avassetwriterinputpixelbufferadaptor_avfoundation/
