//
//  UIImage+Resize.m
//
//  Created by hirofumi kaneko on 2013/02/11.
//

#import "UIImage+Resize.h"

@implementation UIImage (Resize)


#pragma mark - --------------------------------------------------------------------------
#pragma mark - resize

+ (UIImage *)resize:(UIImage *)image width:(CGFloat)width
{
    int imageW = image.size.width;
    int imageH = image.size.height;
    
    float s = width / imageW;
    CGRect resizedRect = CGRectMake(0, 0, imageW * s, imageH * s);
    
    return [UIImage resize:image rect:resizedRect];
}

+ (UIImage *)resize:(UIImage *)image height:(CGFloat)height
{
    int imageW = image.size.width;
    int imageH = image.size.height;
    
    float s = height / imageH;
    CGRect resizedRect = CGRectMake(0, 0, imageW * s, imageH * s);
    
    return [UIImage resize:image rect:resizedRect];
}

+ (UIImage *)resize:(UIImage *)image scale:(CGFloat)scale
{
    int imageW = image.size.width;
    int imageH = image.size.height;
    
    float s = scale;
    CGRect resizedRect = CGRectMake(0, 0, imageW * s, imageH * s);
    
    return [UIImage resize:image rect:resizedRect];
}

+ (UIImage *)resize:(UIImage *)image rect:(CGRect)rect
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(rect.size.width, rect.size.height), YES, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    [image drawInRect:rect];
    UIImage * resizeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
   
    return resizeImage;
}



#pragma mark - --------------------------------------------------------------------------
#pragma mark - crop public

+ (UIImage *)crop:(UIImage *)image rect:(CGRect)rect
{
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], rect);
    UIImage * cropImage = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(imageRef);
    
    return cropImage;
}


@end
