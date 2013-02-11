//
//  UIImage+Resize.h
//
//  Created by hirofumi kaneko on 2013/02/11.
//

#import <UIKit/UIKit.h>

@interface UIImage (Resize)

#pragma mark - --------------------------------------------------------------------------
#pragma mark - resize

+ (UIImage *)resize:(UIImage *)image width:(CGFloat)width;
+ (UIImage *)resize:(UIImage *)image height:(CGFloat)height;
+ (UIImage *)resize:(UIImage *)image scale:(CGFloat)scale;

+ (UIImage *)resize:(UIImage *)image rect:(CGRect)rect;


#pragma mark - --------------------------------------------------------------------------
#pragma mark - crop

+ (UIImage *)crop:(UIImage *)image rect:(CGRect)rect;

@end
