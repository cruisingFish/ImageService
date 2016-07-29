

#import <Foundation/Foundation.h>


@interface ImageService : NSObject {
    
}

CGAffineTransform orientationTransformForImage(UIImage *image, CGSize *newSize);

UIImage *straightenAndScaleImage(UIImage *image, int maxDimension);

+(UIImage*)straightenAndScaleImage:(UIImage *)image maxDimension:(int) maxDimension;

+(UIImage*)editedImageFromMediaWithInfo:(NSDictionary*)info;

+(UIImage *)cropImage:(UIImage *)image to:(CGRect)cropRect andScaleTo:(CGSize)size;

+(UIImage*)scaleImage:(UIImage*)anImage withEditingInfo:(NSDictionary*)editInfo;

+ (UIImage *)createRoundedRectImage:(UIImage*)image size:(CGSize)size cornerRadius:(CGFloat)radius;
/*
 *合成图片指定圆角的接口
 * @param size图片的大小
 * @param cornerRadius 圆角的大小
 * @param corners 指定位置的圆角
 * @return 划定圆角的图片
 */
+ (UIImage *)createRoundedRectImage:(UIImage*)image size:(CGSize)size cornerRadius:(CGFloat)radius inCorners:(UIRectCorner)corners;
+ (UIImage *)createDesaturateImage:(UIImage *)image desaturation:(CGFloat)desaturation;
//将图像和文字合成一张图片
//@param    inImage    传入的图像
//@param    str        传入的文字
//@param    font       文字字体
//@param    color      文字颜色
//@param    spacting   图片和文字间的间隙
//@return   UIImage    合并后的图片
+ (UIImage *)creatImage:(UIImage *)inImage 
             withString:(NSString *)str 
                andFont:(UIFont *)font 
               andColor:(UIColor *)color 
             andSpacing:(CGFloat)spacting;

+ (UIImage*)getGrayImage:(UIImage*)sourceImage;
/**
 *  系统图片灰度处理接口
 *
 *  @param image 需要被处理的图片
 *
 *  @return 处理后的图片
 */
+ (UIImage *)modifyImageToGray:(UIImage *)image;

/*生成水印图片
 *@param   size   图片尺寸
 *
 */
+(UIImage *)createWaterMark:(CGSize)size;

+ (UIImage *)blurImage:(UIImage *)image;

+ (UIImage *)blurImage:(UIImage *)image withRadius:(CGFloat)radius maskColor:(UIColor *)color;

+ (UIImage *)blurryImage:(UIImage *)image withBlurLevel:(CGFloat)blur;

//压缩到size最高1024x1024，流畅渲染的最高尺寸
+ (UIImage *)scaleImageTo1024:(UIImage *)image;

@end
