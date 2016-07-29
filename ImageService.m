
#import "ImageService.h"
#import "UIImage+ImageEffects.h"

@implementation ImageService

static inline double radians (double degrees) {return degrees * M_PI/180;}

static void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth,
                                 float ovalHeight)
{
    float fw, fh;
    if (ovalWidth == 0 || ovalHeight == 0) {
        CGContextAddRect(context, rect);
        return;
    }
    
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextScaleCTM(context, ovalWidth, ovalHeight);
    fw = CGRectGetWidth(rect) / ovalWidth;
    fh = CGRectGetHeight(rect) / ovalHeight;
    
    CGContextMoveToPoint(context, fw, fh/2);  // Start at lower right corner
    CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);  // Top right corner
    CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1); // Top left corner
    CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1); // Lower left corner
    CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1); // Back to lower right
    
    CGContextClosePath(context);
    CGContextRestoreGState(context);
}

+ (UIImage *) createRoundedRectImage:(UIImage*)image size:(CGSize)size cornerRadius:(CGFloat)radius
{
    // the size of CGContextRef
    int w = size.width;
    int h = size.height;
    
    UIImage *img = image;
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect rect = CGRectMake(0, 0, w, h);
    
    CGContextBeginPath(context);
    addRoundedRectToPath(context, rect, radius, radius);
    CGContextClosePath(context);
    CGContextClip(context);
    [img drawInRect:rect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
+ (UIImage *)createRoundedRectImage:(UIImage*)image size:(CGSize)size cornerRadius:(CGFloat)radius inCorners:(UIRectCorner)corners{
    // Get your image somehow
    // Begin a new image that will be the new image with the rounded corners
    // (here with the size of an UIImageView)
    UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
    
    // Add a clip before drawing anything, in the shape of an rounded rect
//    [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, size.width, size.height)
//                                cornerRadius:10.0] addClip];
    [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, size.width, size.height)
                          byRoundingCorners:corners
                                cornerRadii:CGSizeMake(radius, radius)];
    // Draw your image
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    // Get the image, here setting the UIImageView image
    UIImage *outImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // Lets forget about that we were drawing
    UIGraphicsEndImageContext();
//    int w = size.width;
//    int h = size.height;
//    
//    UIImage *img = image;
//    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    CGRect rect = CGRectMake(0, 0, w, h);
//    
//    CGContextBeginPath(context);
//    addRoundedRectToPath(context, rect, radius, radius);
//    CGContextClosePath(context);
//    CGContextClip(context);
//    [img drawInRect:rect];
//    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
    return outImage;

}
+ (UIImage *)createDesaturateImage:(UIImage *)image desaturation:(CGFloat)desaturation
{
    int w = image.size.width;
    int h = image.size.height;
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect rect = CGRectMake(0, 0, w, h);
    
    CGContextTranslateCTM(context, 0.0, h); // flip image right side up
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextDrawImage(context, rect, image.CGImage);
    CGContextSetBlendMode(context, kCGBlendModeSaturation);
    CGContextClipToMask(context, rect, image.CGImage); // restricts drawing to within alpha channel
    CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, desaturation);
    CGContextFillRect(context, rect);
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+(UIImage*)editedImageFromMediaWithInfo:(NSDictionary*)info{
    if(![info   objectForKey:UIImagePickerControllerCropRect])return nil;
    if(![info   objectForKey:UIImagePickerControllerOriginalImage])return nil;
    
    UIImage *originalImage=[info objectForKey:UIImagePickerControllerOriginalImage];
    CGRect rect=[[info objectForKey:UIImagePickerControllerCropRect] CGRectValue];
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([originalImage CGImage], rect);
    
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    CGColorSpaceRef colorSpaceInfo = CGImageGetColorSpace(imageRef);
    CGContextRef bitmap = CGBitmapContextCreate(NULL, rect.size.width, rect.size.height, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, bitmapInfo);
    
    if (originalImage.imageOrientation == UIImageOrientationLeft) {
        CGContextRotateCTM (bitmap, radians(90));
        CGContextTranslateCTM (bitmap, 0, -rect.size.height);
        
    } else if (originalImage.imageOrientation == UIImageOrientationRight) {
        CGContextRotateCTM (bitmap, radians(-90));
        CGContextTranslateCTM (bitmap, -rect.size.width, 0);
        
    } else if (originalImage.imageOrientation == UIImageOrientationUp) {
        // NOTHING
    } else if (originalImage.imageOrientation == UIImageOrientationDown) {
        CGContextTranslateCTM (bitmap, rect.size.width, rect.size.height);
        CGContextRotateCTM (bitmap, radians(-180.));
    }
    
    CGContextDrawImage(bitmap, CGRectMake(0, 0, rect.size.width, rect.size.height), imageRef);
    CGImageRef ref = CGBitmapContextCreateImage(bitmap);
    
    UIImage *resultImage=[UIImage imageWithCGImage:ref];
    CGImageRelease(imageRef);
    CGContextRelease(bitmap);
    CGImageRelease(ref);
    
    return resultImage;
}

FOUNDATION_STATIC_INLINE NSUInteger YJCacheCostForImage(UIImage *image) {
    return image.size.height * image.size.width * image.scale * image.scale;
}

+ (UIImage *)scaleImageTo1024:(UIImage *)image {
    if (image) {
        if (image.size.width>1280 || image.size.height>1280) {
            
//            CGFloat nWiddth = [UIScreen mainScreen].bounds.size.width;
//            CGFloat edge = (image.size.height>960 && nWiddth > 320)?960:640;
            return straightenAndScaleImage(image,1280);
        }
    }
    return image;
}

+(UIImage*)straightenAndScaleImage:(UIImage *)image maxDimension:(int) maxDimension
{
    /*CGImageRef img = [image CGImage];
    CGFloat width = CGImageGetWidth(img);
    CGFloat height = CGImageGetHeight(img);
    CGRect bounds = CGRectMake(0, 0, width, height);
    CGSize size = bounds.size;
    if (width > maxDimension || height > maxDimension) {
        CGFloat ratio = width/height;
        if (ratio > 1.0f) {
            size.width = maxDimension;
            size.height = size.width / ratio;
        }
        else {
            size.height = maxDimension;
            size.width = size.height * ratio;
        }
    } 
    
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, bounds, img);
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();*/
    return straightenAndScaleImage(image,maxDimension);
}

UIImage *straightenAndScaleImage(UIImage *theFullImage, int maxDimension) {
    
    CGImageRef img = [theFullImage CGImage];
	CGFloat width = CGImageGetWidth(img);
	CGFloat height = CGImageGetHeight(img);
	CGRect bounds = CGRectMake(0, 0, width, height);
	CGSize size = bounds.size;
	if (width > maxDimension || height > maxDimension) {
        CGFloat ratio = width/height;
        if(ratio >2.0f || ratio < 0.5){
            NSData *imageData = UIImageJPEGRepresentation(theFullImage,0.7);
            return [[[UIImage alloc] initWithData:imageData] autorelease];
        }
        if (ratio > 1.0f) {
			size.width = maxDimension;
			size.height = size.width / ratio;
        }
        else {
			size.height = maxDimension;
			size.width = size.height * ratio;
        }
	}
    
//    UIGraphicsBeginImageContext(size);
//    [theFullImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
//    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
    
    
	CGFloat scale = size.width/width;

	CGAffineTransform transform = orientationTransformForImage(theFullImage, &size);
    size = CGSizeMake((int)(size.width*scale), (int)(size.height*scale));
	UIGraphicsBeginImageContext(size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	// Flip 
	UIImageOrientation orientation = [theFullImage imageOrientation];
	if (orientation == UIImageOrientationRight || orientation == UIImageOrientationLeft) {
        
        CGContextScaleCTM(context, -scale, scale);
        CGContextTranslateCTM(context, -height, 0);
	}else {
        CGContextScaleCTM(context, scale, -scale);
        CGContextTranslateCTM(context, 0, -height);
	}
	CGContextConcatCTM(context, transform);
	CGContextDrawImage(context, bounds, img);
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
    
	return newImage;
}

CGAffineTransform orientationTransformForImage(UIImage *image, CGSize *newSize) {
	CGImageRef img = [image CGImage];
	CGFloat width = CGImageGetWidth(img);
	CGFloat height = CGImageGetHeight(img);
	CGSize size = CGSizeMake(width, height);
	CGAffineTransform transform = CGAffineTransformIdentity;
	CGFloat origHeight = size.height;
	UIImageOrientation orient = image.imageOrientation;
	switch(orient) { /* EXIF 1 to 8 */
		case UIImageOrientationUp:
			break;
		case UIImageOrientationUpMirrored:
			transform = CGAffineTransformMakeTranslation(width, 0.0f);
			transform = CGAffineTransformScale(transform, -1.0f, 1.0f);
			break;
		case UIImageOrientationDown:
			transform = CGAffineTransformMakeTranslation(width, height);
			transform = CGAffineTransformRotate(transform, M_PI);
			break;
		case UIImageOrientationDownMirrored:
			transform = CGAffineTransformMakeTranslation(0.0f, height);
			transform = CGAffineTransformScale(transform, 1.0f, -1.0f);
			break;
		case UIImageOrientationLeftMirrored:
			size.height = size.width;
			size.width = origHeight;
			transform = CGAffineTransformMakeTranslation(height, width);
			transform = CGAffineTransformScale(transform, -1.0f, 1.0f);
			transform = CGAffineTransformRotate(transform, 3.0f * M_PI / 2.0f);
			break;
		case UIImageOrientationLeft:
			size.height = size.width;
			size.width = origHeight;
			transform = CGAffineTransformMakeTranslation(0.0f, width);
			transform = CGAffineTransformRotate(transform, 3.0f * M_PI / 2.0f);
			break;
		case UIImageOrientationRightMirrored:
			size.height = size.width;
			size.width = origHeight;
			transform = CGAffineTransformMakeScale(-1.0f, 1.0f);
			transform = CGAffineTransformRotate(transform, M_PI / 2.0f);
			break;
		case UIImageOrientationRight:
			size.height = size.width;
			size.width = origHeight;
			transform = CGAffineTransformMakeTranslation(height, 0.0f);
			transform = CGAffineTransformRotate(transform, M_PI / 2.0f);
			break;
		default:
			;
	}
	*newSize = size;
	return transform;
}

+ (UIImage *)cropImage:(UIImage *)image to:(CGRect)cropRect andScaleTo:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGImageRef subImage = CGImageCreateWithImageInRect([image CGImage], cropRect);
    CGRect myRect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    CGContextScaleCTM(context, 1.0f, -1.0f);
    CGContextTranslateCTM(context, 0.0f, -size.height);
    CGContextDrawImage(context, myRect, subImage);
    UIImage* croppedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CGImageRelease(subImage);
    return croppedImage;
}

+ (UIImage*)scaleImage:(UIImage*)anImage withEditingInfo:(NSDictionary*)editInfo{
    
    UIImage *newImage;
    
    UIImage *originalImage = [editInfo valueForKey:@"UIImagePickerControllerOriginalImage"];
    CGSize originalSize = CGSizeMake(originalImage.size.width, originalImage.size.height);
    CGRect originalFrame;
    originalFrame.origin = CGPointMake(0,0);
    originalFrame.size = originalSize;
    
    CGRect croppingRect = [[editInfo valueForKey:@"UIImagePickerControllerCropRect"] CGRectValue];
    CGSize croppingRectSize = CGSizeMake(croppingRect.size.width, croppingRect.size.height);
    
    CGSize croppedScaledImageSize = anImage.size;
    
    float scaledBarClipHeight = 80;
    
    CGSize scaledImageSize;
    float scale;
    
    if(!CGSizeEqualToSize(croppedScaledImageSize, originalSize)){
        
        scale = croppedScaledImageSize.width/croppingRectSize.width;
        float barClipHeight = scaledBarClipHeight/scale;
        
        croppingRect.origin.y -= barClipHeight;
        croppingRect.size.height += (2*barClipHeight);
        
        if(croppingRect.origin.y<=0){
            croppingRect.size.height += croppingRect.origin.y;
            croppingRect.origin.y=0;
        }
        
        if(croppingRect.size.height > (originalSize.height - croppingRect.origin.y)){
            croppingRect.size.height = (originalSize.height - croppingRect.origin.y);
        }
        
        
        scaledImageSize = croppingRect.size;
        scaledImageSize.width *= scale;
        scaledImageSize.height *= scale;
        
        newImage =  [self cropImage:originalImage to:croppingRect andScaleTo:scaledImageSize];
        
    }else{
        
        newImage = originalImage;
        
    }
    
    return newImage;
}

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
             andSpacing:(CGFloat)spacting
{
    UIImage *newImage;
    CGSize strSize=[str sizeWithFont:font 
                   constrainedToSize:CGSizeMake(MAXFLOAT, MAXFLOAT)];
    if (strSize.width<inImage.size.width) {
        CGSize size=CGSizeMake(inImage.size.width, inImage.size.height+strSize.height+spacting);
        UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        [inImage drawInRect:CGRectMake(0, 0, inImage.size.width, inImage.size.height)];
        CGContextSetFillColorWithColor(context, [color CGColor]);
        [str drawAtPoint:CGPointMake((inImage.size.width-strSize.width)/2.0, inImage.size.height+spacting) withFont:font];
        newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    else
    {
        CGSize size=CGSizeMake(strSize.width, inImage.size.height+strSize.height+spacting);
        UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        [inImage drawInRect:CGRectMake((strSize.width-inImage.size.width)/2.0, 0, inImage.size.width, inImage.size.height)];
        CGContextSetFillColorWithColor(context, [color CGColor]);
        [str drawAtPoint:CGPointMake(0, inImage.size.height+spacting) withFont:font];
        newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return newImage;
    
}

//+(UIImage*)getGrayImage:(UIImage*)sourceImage
//{
//    if (!sourceImage) {
//        return nil;
//    }
//    //    CIContext *context = [CIContext contextWithOptions:nil];
//    CIImage *ciimage = [CIImage imageWithCGImage:[sourceImage CGImage]];
//    CIFilter *filter = [CIFilter filterWithName:@"CIColorControls"];
//    [filter setValue:ciimage forKey:@"inputImage"];
//    [filter setValue:[NSNumber numberWithFloat:0.0f] forKey:@"inputSaturation"];
//    CIImage *result = [filter valueForKey:kCIOutputImageKey];
//    //    CGImageRef cgImage = [context createCGImage:result fromRect:[result extent]];
//    UIImage *img=[UIImage imageWithCIImage:result scale:[[UIScreen mainScreen] scale] orientation:UIImageOrientationUp];
//    //    CGImageRelease(cgImage);
//    return img;
//}

/*生成水印图片
 *@param   size   图片尺寸
 *
 */
+(UIImage *)createWaterMark:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    CGFloat rate = MAX(size.width, size.height)/640;
    CGFloat marginTop = 15.0*rate;
    CGFloat drawLeft = 15.0*rate;
//    CGFloat iconWidth = 30.0*rate;
//    
//    UIFont *strFont = YJNormalFontSize(20*rate);//[UIFont systemFontOfSize:20*rate];
//    NSNumber* selfUserID = (NSNumber*)[APPDelegate.logicCore.cacheData getSelfUserId];
//    NSString *str = [NSString stringWithFormat:@"%@%@",YJLocalizedString(@"profile userid", nil),selfUserID];
//    CGSize strSize = [str sizeWithFont:strFont];
    
    UIImage *logo = [UIImage imageNamed:@"img_TV_video.png"];
    [logo drawInRect:CGRectMake(drawLeft, marginTop, 85*rate, 20*rate)];
    
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 0.7);
//    CGContextSetShadow(context, CGSizeMake(2.0f*rate, 2.0f*rate), 2.0f*rate);
//    [str drawAtPoint:CGPointMake(size.width-strSize.width-drawRight, size.height-strSize.height-marginBottom-3*rate) withFont:strFont];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}
//+ (UIImage*)getGrayImage:(UIImage*)sourceImage
//{
//    int width = sourceImage.size.width;
//    int height = sourceImage.size.height;
//    
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
//    CGContextRef context = CGBitmapContextCreate (nil,width,height,8,0,colorSpace,kCGImageAlphaNone);
//    CGColorSpaceRelease(colorSpace);
//    
//    if (context == NULL) {
//        return nil;
//    }
//    
//    CGContextDrawImage(context,CGRectMake(0, 0, width, height), sourceImage.CGImage);
//    CGImageRef grayImageRef = CGBitmapContextCreateImage(context);
//    UIImage *grayImage = [UIImage imageWithCGImage:grayImageRef];
//    CGContextRelease(context);
//    CGImageRelease(grayImageRef);
//    
//    return grayImage;
//}

+ (UIImage*)getGrayImage:(UIImage*)sourceImage
{
    CGImageRef imageRef = sourceImage.CGImage;
    size_t width  = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    size_t bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    bool shouldInterpolate = CGImageGetShouldInterpolate(imageRef);
    CGColorRenderingIntent intent = CGImageGetRenderingIntent(imageRef);
    CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
    
    CFDataRef   data = CGDataProviderCopyData(dataProvider);
    UInt8* buffer = (UInt8*)CFDataGetBytePtr(data);
    
    NSUInteger  x, y;
    for (y = 0; y < height; y++) {  //将图片的每个像素点转化成灰度图
        for (x = 0; x < width; x++) {
            UInt8*  tmp;
            tmp = buffer + y * bytesPerRow + x * 4;
            
            // RGB值
            UInt8 red,green,blue;
            red = *(tmp + 0);
            green = *(tmp + 1);
            blue = *(tmp + 2);
            
            UInt8 brightness;
            
            //brightness = (77 * red + 28 * green + 151 * blue) / 256;
            brightness = (red + green +  blue) / 3.0;
            *(tmp + 0) = brightness;
            *(tmp + 1) = brightness;
            *(tmp + 2) = brightness;
        }
    }
    
    CFDataRef effectedData = CFDataCreate(NULL, buffer, CFDataGetLength(data));
    CGDataProviderRef effectedDataProvider = CGDataProviderCreateWithCFData(effectedData);
    CGImageRef effectedCgImage = CGImageCreate(
                                    width, height,
                                    bitsPerComponent, bitsPerPixel, bytesPerRow,
                                    colorSpace, bitmapInfo, effectedDataProvider,
                                    NULL, shouldInterpolate, intent);
    UIImage* grayImage = [[UIImage alloc] initWithCGImage:effectedCgImage];
    
    CGImageRelease(effectedCgImage);
    CFRelease(effectedDataProvider);
    CFRelease(effectedData);
    CFRelease(data);
    
    return [grayImage autorelease];
}
+ (UIImage *)modifyImageToGray:(UIImage *)image{
    CGSize size = image.size;
    CGRect rect = CGRectMake(0.0f, 0.0f, image.size.width,
                             image.size.height);
    // Create a mono/gray color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef context = CGBitmapContextCreate(nil, size.width,
                                                 size.height, 8, 0, colorSpace, kCGBitmapByteOrderDefault);
    CGColorSpaceRelease(colorSpace);
    // Draw the image into the grayscale context
    CGContextDrawImage(context, rect, [image CGImage]);
    CGImageRef grayscale = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    // Recover the image
    UIImage *img = [UIImage imageWithCGImage:grayscale];
    CFRelease(grayscale);
    return img;
}
+ (UIImage *)blurImage:(UIImage *)image
{
    return [image applyBlurWithRadius:5 tintColor:[UIColor colorWithWhite:0 alpha:0.5] saturationDeltaFactor:1.0 maskImage:nil];
}

+ (UIImage *)blurImage:(UIImage *)image withRadius:(CGFloat)radius maskColor:(UIColor *)color
{
    return [image applyBlurWithRadius:radius tintColor:color saturationDeltaFactor:1.0 maskImage:nil];
}

//加模糊效果，image是图片，blur是模糊度
+ (UIImage *)blurryImage:(UIImage *)image withBlurLevel:(CGFloat)blur
{
    //模糊度,
    if ((blur < 0.01f) || (blur > 2.0f)) {
        blur = 0.5f;
    }
    
    //boxSize必须大于0
    int boxSize = (int)(blur * 100);
    boxSize -= (boxSize % 2) + 1;
    //图像处理
    CGImageRef img = image.CGImage;
    
    //图像缓存,输入缓存，输出缓存
    vImage_Buffer inBuffer, outBuffer;
    //像素缓存
    void *pixelBuffer;
    
    //数据源提供者，Defines an opaque type that supplies Quartz with data.
    CGDataProviderRef inProvider = CGImageGetDataProvider(img);
    // provider’s data.
    CFDataRef inBitmapData = CGDataProviderCopyData(inProvider);
    
    //宽，高，字节/行，data
    inBuffer.width = CGImageGetWidth(img);
    inBuffer.height = CGImageGetHeight(img);
    inBuffer.rowBytes = CGImageGetBytesPerRow(img);
    inBuffer.data = (void*)CFDataGetBytePtr(inBitmapData);
    
    //像数缓存，字节行*图片高
    pixelBuffer = malloc(CGImageGetBytesPerRow(img) * CGImageGetHeight(img));
    
    outBuffer.data = pixelBuffer;
    outBuffer.width = CGImageGetWidth(img);
    outBuffer.height = CGImageGetHeight(img);
    outBuffer.rowBytes = CGImageGetBytesPerRow(img);
    
    
    // 第三个中间的缓存区,抗锯齿的效果
    void *pixelBuffer2 = malloc(CGImageGetBytesPerRow(img) * CGImageGetHeight(img));
    vImage_Buffer outBuffer2;
    outBuffer2.data = pixelBuffer2;
    outBuffer2.width = CGImageGetWidth(img);
    outBuffer2.height = CGImageGetHeight(img);
    outBuffer2.rowBytes = CGImageGetBytesPerRow(img);
    
    //Convolves a region of interest within an ARGB8888 source image by an implicit M x N kernel that has the effect of a box filter.
    vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer2, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    vImageBoxConvolve_ARGB8888(&outBuffer2, &inBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    
    //    NSLog(@"字节组成部分：%zu",CGImageGetBitsPerComponent(img));
    //颜色空间DeviceRGB
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    //用图片创建上下文,CGImageGetBitsPerComponent(img),7,8
    CGContextRef ctx = CGBitmapContextCreate(
                                             outBuffer.data,
                                             outBuffer.width,
                                             outBuffer.height,
                                             8,
                                             outBuffer.rowBytes,
                                             colorSpace,
                                             CGImageGetBitmapInfo(image.CGImage));
    
    //根据上下文，处理过的图片，重新组件
    CGImageRef imageRef = CGBitmapContextCreateImage (ctx);
    UIImage *returnImage = [UIImage imageWithCGImage:imageRef];
    
    //clean up
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    
    free(pixelBuffer);
    free(pixelBuffer2);
    CFRelease(inBitmapData);
    CGImageRelease(imageRef);
    
    return returnImage;
}

@end
