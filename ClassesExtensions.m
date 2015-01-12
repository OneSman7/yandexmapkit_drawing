//
//  ClassesExtensions.m
//  iRealtor
//
//  Created by Иван Ерасов on 30.10.13.
//  Copyright (c) 2013 iRealtor. All rights reserved.
//

#include <sys/sysctl.h>
#import "ClassesExtensions.h"
#import "Constants.h"
#import <Accelerate/Accelerate.h>
#import <float.h>

NSString* YMKConfigurationUpdatedMapLayers = @"YMKConfigurationUpdatedMapLayers";
NSString* YMKMapChangedMapType = @"YMKMapChangedMapType";

YMKMapRect YMKMapBoundingRectForCoordinate(YMKMapCoordinate coordinate)
{
    YMKMapDegrees radius = 0.0007;
    return YMKMapRectMake(YMKMapCoordinateMake(coordinate.latitude + radius, coordinate.longitude - radius), YMKMapCoordinateMake(coordinate.latitude - radius, coordinate.longitude + radius));
}

@implementation UIApplication (NetworkIndicator)

+ (void)setNetworkActivityIndicatorVisible:(BOOL)setVisible
{
    static NSInteger NumberOfCallsToSetVisible = 0;
    if(setVisible)
        NumberOfCallsToSetVisible++;
    else
        NumberOfCallsToSetVisible--;
    
    // Display the indicator as long as our static counter is > 0.
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(NumberOfCallsToSetVisible > 0)];
}

@end

@implementation NSString (CalculatingSize)

- (CGFloat)widthWithFont:(UIFont*)font
{
    return [self widthWithFont:font constrainToSize:CGSizeMake(INT_MAX, INT_MAX)];
}

- (CGFloat)widthWithFont:(UIFont*)font constrainToSize:(CGSize)constraintSize
{
    return ceil([self boundingRectWithSize:constraintSize options:NSStringDrawingTruncatesLastVisibleLine attributes:@{NSFontAttributeName : font} context:nil].size.width);
}

- (CGFloat)heightWithWidth:(CGFloat)width andFont:(UIFont*)font
{
    return ceil([self boundingRectWithSize:CGSizeMake(width, INT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : font} context:nil].size.height);
}

@end

@implementation NSString (HandyAdditions)

- (NSString*)stringByRemovingHTMLBreaks
{
    return [[NSRegularExpression regularExpressionWithPattern:@"<br\\s?/>" options:0 error:nil] stringByReplacingMatchesInString:self options:0 range:NSMakeRange(0, self.length) withTemplate:@"\n"];
}

- (NSString*)firstLetterCapitalize
{
    if(self.length > 0)
        return [self stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[self substringToIndex:1].capitalizedString];
    else
        return nil;
}

+ (NSString*)pathFromComponents:(NSArray*)components
{
    if(components.count > 0)
    {
        NSString* path = components[0];
        
        if(components.count > 1)
        {
            for(NSUInteger i = 1;i < components.count;i++)
                path = [path stringByAppendingPathComponent:components[i]];
        }
        
        return path;
    }
    else
        return nil;
}

- (NSString*)formattedIntegerString
{
    if(self.integerValue == 0)
        return nil;
    else
    {
        NSMutableString* resultString = [NSMutableString string];
        NSMutableString* priceString = [NSMutableString string];
        
        NSInteger digitIndex = 0;
        
        for(NSInteger i = self.length - 1; i >= 0; i--)
        {
            unichar currentChar = [self characterAtIndex:i];
            if(digitIndex % 3 == 0)
                [priceString appendFormat:@" %C", currentChar];
            else
                [priceString appendFormat:@"%C", currentChar];
            
            digitIndex++;
        }
        
        for(NSInteger i = priceString.length - 1; i >= 0; i--)
        {
            unichar currentChar = [priceString characterAtIndex:i];
            if(currentChar == 46)
                break;
            
            [resultString appendFormat:@"%C", currentChar];
        }
        
        return [resultString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
}

@end

@implementation NSMutableAttributedString (HandyAdditions)

- (void)insertRoubleSymbolWithSize:(CGFloat)size
{
    NSRange rangeOfRouble = [self.string rangeOfString:RoubleSignStringWithSpacePrefix];
    if(rangeOfRouble.length > 0)
        [self addAttribute:NSFontAttributeName value:[UIFont fontWithName:RoubleSignFontName size:size] range:NSMakeRange(rangeOfRouble.location + 1, 1)];
}

@end

@implementation NSArray (Reverse)

- (NSMutableArray*)reversedArray
{
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:[self count]];
    NSEnumerator* enumerator = [self reverseObjectEnumerator];
    for (id element in enumerator)
        [array addObject:element];
    
    return array;
}

@end

@implementation NSNotificationCenter (MainThread)

- (void)postNotificationOnMainThread:(NSNotification*)notification
{
    if([[NSThread currentThread] isMainThread])
        [self postNotification:notification];
    else
        [self performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES];
}

- (void)postNotificationOnMainThreadName:(NSString*)aName object:(id)anObject
{
	NSNotification* notification = [NSNotification notificationWithName:aName object:anObject];
	[self postNotificationOnMainThread:notification];
}

- (void)postNotificationOnMainThreadName:(NSString*)aName object:(id)anObject userInfo:(NSDictionary*)aUserInfo
{
	NSNotification* notification = [NSNotification notificationWithName:aName object:anObject userInfo:aUserInfo];
	[self postNotificationOnMainThread:notification];
}

@end

@implementation UIDevice (Hardware)

- (NSString*)getSysInfoByName:(char*)typeSpecifier
{
    size_t size;
    sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);
    
    char* answer = malloc(size);
    sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
    
    NSString* results = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];
    
    free(answer);
    return results;
}

- (NSString*)platform
{
    return [self getSysInfoByName:"hw.machine"];
}

@end

@implementation UIColor (HexColors)

+ (UIColor*)colorWithHexString:(NSString*)hexString
{
    if(hexString.length != 6)
        return nil;
    
    // Brutal and not-very elegant test for non hex-numeric characters
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"[^a-fA-F|0-9]" options:0 error:NULL];
    NSUInteger match = [regex numberOfMatchesInString:hexString options:NSMatchingReportCompletion range:NSMakeRange(0, hexString.length)];
    
    if(match != 0)
        return nil;
    
    NSRange rRange = NSMakeRange(0, 2);
    NSString* rComponent = [hexString substringWithRange:rRange];
    NSUInteger rVal = 0;
    NSScanner* rScanner = [NSScanner scannerWithString:rComponent];
    [rScanner scanHexInt:&rVal];
    float rRetVal = (float)rVal / 254;
    
    
    NSRange gRange = NSMakeRange(2, 2);
    NSString* gComponent = [hexString substringWithRange:gRange];
    NSUInteger gVal = 0;
    NSScanner* gScanner = [NSScanner scannerWithString:gComponent];
    [gScanner scanHexInt:&gVal];
    float gRetVal = (float)gVal / 254;
    
    NSRange bRange = NSMakeRange(4, 2);
    NSString* bComponent = [hexString substringWithRange:bRange];
    NSUInteger bVal = 0;
    NSScanner* bScanner = [NSScanner scannerWithString:bComponent];
    [bScanner scanHexInt:&bVal];
    float bRetVal = (float)bVal / 254;
    
    return [UIColor colorWithRed:rRetVal green:gRetVal blue:bRetVal alpha:1.0f];
}

+ (NSString*)hexValuesFromUIColor:(UIColor *)color
{
    if(!color)
        return nil;
    
    if(color == [UIColor whiteColor])
    {
        // Special case, as white doesn't fall into the RGB color space
        return @"ffffff";
    }
    
    CGFloat red;
    CGFloat blue;
    CGFloat green;
    CGFloat alpha;
    
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    
    int redDec = (int)(red * 255);
    int greenDec = (int)(green * 255);
    int blueDec = (int)(blue * 255);
    
    return [NSString stringWithFormat:@"%02x%02x%02x", (unsigned int)redDec, (unsigned int)greenDec, (unsigned int)blueDec]; 
}

@end

@implementation UIImage (ImageProcessing)

- (UIImage*)scaledAndRotatedImage
{
	NSInteger kMaxResolution = 1024;
	
	CGImageRef imgRef = self.CGImage;
	CGFloat width = CGImageGetWidth(imgRef);
	CGFloat height = CGImageGetHeight(imgRef);
	
	CGAffineTransform transform = CGAffineTransformIdentity;
	CGRect bounds = CGRectMake(0, 0, width, height);
	
	if(width > kMaxResolution || height > kMaxResolution)
    {
		CGFloat ratio = width / height;
		if(ratio > 1)
        {
			bounds.size.width = kMaxResolution;
			bounds.size.height = bounds.size.width / ratio;
		}
        else
        {
			bounds.size.height = kMaxResolution;
			bounds.size.width = bounds.size.height * ratio;
		}
	}
	
	CGFloat scaleRatio = bounds.size.width / width;
	CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
	CGFloat boundHeight;
	
	UIImageOrientation orient = self.imageOrientation;
    
	switch(orient)
    {
		case UIImageOrientationUp:
			transform = CGAffineTransformIdentity;
			break;
		case UIImageOrientationUpMirrored:
			transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
			transform = CGAffineTransformScale(transform, -1.0, 1.0);
			break;
		case UIImageOrientationDown:
			transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
			transform = CGAffineTransformRotate(transform, M_PI);
			break;
		case UIImageOrientationDownMirrored:
			transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
			transform = CGAffineTransformScale(transform, 1.0, -1.0);
			break;
		case UIImageOrientationLeftMirrored:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
			transform = CGAffineTransformScale(transform, -1.0, 1.0);
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
			break;
		case UIImageOrientationLeft:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
			break;
		case UIImageOrientationRightMirrored:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeScale(-1.0, 1.0);
			transform = CGAffineTransformRotate(transform, M_PI / 2.0);
			break;
		case UIImageOrientationRight:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
			transform = CGAffineTransformRotate(transform, M_PI / 2.0);
			break;
		default:
			[NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
	}
	
	UIGraphicsBeginImageContext(bounds.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
    
	if(orient == UIImageOrientationRight || orient == UIImageOrientationLeft)
    {
		CGContextScaleCTM(context, -scaleRatio, scaleRatio);
		CGContextTranslateCTM(context, -height, 0);
	}
    else
    {
		CGContextScaleCTM(context, scaleRatio, -scaleRatio);
		CGContextTranslateCTM(context, 0, -height);
	}
    
	CGContextConcatCTM(context, transform);
	CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
	UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return imageCopy;
}

- (UIImage*)imageByApplyingAlpha:(CGFloat)alpha
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect area = CGRectMake(0, 0, self.size.width, self.size.height);
    
    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, 0, -area.size.height);
    
    CGContextSetBlendMode(ctx, kCGBlendModeMultiply);
    CGContextSetAlpha(ctx, alpha);
    CGContextDrawImage(ctx, area, self.CGImage);
    
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

+ (UIImage*)emptyImageWithSize:(CGSize)size andBackgroundColor:(UIColor*)color
{
    CGRect frameRect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContext(size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(ctx, color.CGColor); //image frame color
    CGContextFillRect(ctx, frameRect);
    
    UIImage* resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resultImage;
}

- (UIImage *)applyLightEffect
{
    UIColor *tintColor = [UIColor colorWithWhite:1.0 alpha:0.3];
    return [self applyBlurWithRadius:30 tintColor:tintColor saturationDeltaFactor:1.8 maskImage:nil];
}


- (UIImage *)applyExtraLightEffect
{
    UIColor *tintColor = [UIColor colorWithWhite:0.97 alpha:0.82];
    return [self applyBlurWithRadius:20 tintColor:tintColor saturationDeltaFactor:1.8 maskImage:nil];
}


- (UIImage *)applyDarkEffect
{
    UIColor *tintColor = [UIColor colorWithWhite:0.11 alpha:0.73];
    return [self applyBlurWithRadius:20 tintColor:tintColor saturationDeltaFactor:1.8 maskImage:nil];
}


- (UIImage *)applyTintEffectWithColor:(UIColor *)tintColor
{
    const CGFloat EffectColorAlpha = 0.6;
    UIColor *effectColor = tintColor;
    int componentCount = CGColorGetNumberOfComponents(tintColor.CGColor);
    if (componentCount == 2) {
        CGFloat b;
        if ([tintColor getWhite:&b alpha:NULL]) {
            effectColor = [UIColor colorWithWhite:b alpha:EffectColorAlpha];
        }
    }
    else {
        CGFloat r, g, b;
        if ([tintColor getRed:&r green:&g blue:&b alpha:NULL]) {
            effectColor = [UIColor colorWithRed:r green:g blue:b alpha:EffectColorAlpha];
        }
    }
    return [self applyBlurWithRadius:10 tintColor:effectColor saturationDeltaFactor:-1.0 maskImage:nil];
}


- (UIImage *)applyBlurWithRadius:(CGFloat)blurRadius tintColor:(UIColor *)tintColor saturationDeltaFactor:(CGFloat)saturationDeltaFactor maskImage:(UIImage *)maskImage{
    if (self.size.width < 1 || self.size.height < 1) {
        NSLog (@"*** error: invalid size: (%.2f x %.2f). Both dimensions must be >= 1: %@", self.size.width, self.size.height, self);
        return nil;
    }
    if (!self.CGImage) {
        NSLog (@"*** error: image must be backed by a CGImage: %@", self);
        return nil;
    }
    if (maskImage && !maskImage.CGImage) {
        NSLog (@"*** error: maskImage must be backed by a CGImage: %@", maskImage);
        return nil;
    }
    
    CGRect imageRect = { CGPointZero, self.size };
    UIImage *effectImage = self;
    
    BOOL hasBlur = blurRadius > __FLT_EPSILON__;
    BOOL hasSaturationChange = fabs(saturationDeltaFactor - 1.) > __FLT_EPSILON__;
    if (hasBlur || hasSaturationChange) {
        UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectInContext = UIGraphicsGetCurrentContext();
        CGContextScaleCTM(effectInContext, 1.0, -1.0);
        CGContextTranslateCTM(effectInContext, 0, -self.size.height);
        CGContextDrawImage(effectInContext, imageRect, self.CGImage);
        
        vImage_Buffer effectInBuffer;
        effectInBuffer.data     = CGBitmapContextGetData(effectInContext);
        effectInBuffer.width    = CGBitmapContextGetWidth(effectInContext);
        effectInBuffer.height   = CGBitmapContextGetHeight(effectInContext);
        effectInBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectInContext);
        
        UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectOutContext = UIGraphicsGetCurrentContext();
        vImage_Buffer effectOutBuffer;
        effectOutBuffer.data     = CGBitmapContextGetData(effectOutContext);
        effectOutBuffer.width    = CGBitmapContextGetWidth(effectOutContext);
        effectOutBuffer.height   = CGBitmapContextGetHeight(effectOutContext);
        effectOutBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectOutContext);
        
        if (hasBlur) {
            // A description of how to compute the box kernel width from the Gaussian
            // radius (aka standard deviation) appears in the SVG spec:
            // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
            //
            // For larger values of 's' (s >= 2.0), an approximation can be used: Three
            // successive box-blurs build a piece-wise quadratic convolution kernel, which
            // approximates the Gaussian kernel to within roughly 3%.
            //
            // let d = floor(s * 3*sqrt(2*pi)/4 + 0.5)
            //
            // ... if d is odd, use three box-blurs of size 'd', centered on the output pixel.
            //
            CGFloat inputRadius = blurRadius * [[UIScreen mainScreen] scale];
            NSUInteger radius = floor(inputRadius * 3. * sqrt(2 * M_PI) / 4 + 0.5);
            if (radius % 2 != 1) {
                radius += 1; // force radius to be odd so that the three box-blur methodology works.
            }
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
        }
        BOOL effectImageBuffersAreSwapped = NO;
        if (hasSaturationChange) {
            CGFloat s = saturationDeltaFactor;
            CGFloat floatingPointSaturationMatrix[] = {
                0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
                0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
                0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
                0,                    0,                    0,  1,
            };
            const int32_t divisor = 256;
            NSUInteger matrixSize = sizeof(floatingPointSaturationMatrix)/sizeof(floatingPointSaturationMatrix[0]);
            int16_t saturationMatrix[matrixSize];
            for (NSUInteger i = 0; i < matrixSize; ++i) {
                saturationMatrix[i] = (int16_t)roundf(floatingPointSaturationMatrix[i] * divisor);
            }
            if (hasBlur) {
                vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
                effectImageBuffersAreSwapped = YES;
            }
            else {
                vImageMatrixMultiply_ARGB8888(&effectInBuffer, &effectOutBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
            }
        }
        if (!effectImageBuffersAreSwapped)
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        if (effectImageBuffersAreSwapped)
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    // Set up output context.
    UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef outputContext = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(outputContext, 1.0, -1.0);
    CGContextTranslateCTM(outputContext, 0, -self.size.height);
    
    // Draw base image.
    CGContextDrawImage(outputContext, imageRect, self.CGImage);
    
    // Draw effect image.
    if (hasBlur) {
        CGContextSaveGState(outputContext);
        if (maskImage) {
            CGContextClipToMask(outputContext, imageRect, maskImage.CGImage);
        }
        CGContextDrawImage(outputContext, imageRect, effectImage.CGImage);
        CGContextRestoreGState(outputContext);
    }
    
    // Add in color tint.
    if (tintColor) {
        CGContextSaveGState(outputContext);
        CGContextSetFillColorWithColor(outputContext, tintColor.CGColor);
        CGContextFillRect(outputContext, imageRect);
        CGContextRestoreGState(outputContext);
    }
    
    // Output image is ready.
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return outputImage;
}

@end

@implementation NSCoder (MapValuesNSCoding)

- (YMKMapRect)decodeMapRectForKey:(NSString*)key
{
    YMKMapDegrees firstCoordinateLatitude = [self decodeDoubleForKey:[NSString stringWithFormat:@"%@FirstCoordinateLatitude", key]];
    YMKMapDegrees firstCoordinateLongitude = [self decodeDoubleForKey:[NSString stringWithFormat:@"%@FirstCoordinateLongitude", key]];
    YMKMapDegrees secondCoordinateLatitude = [self decodeDoubleForKey:[NSString stringWithFormat:@"%@SecondCoordinateLatitude", key]];
    YMKMapDegrees secondCoordinateLongitude = [self decodeDoubleForKey:[NSString stringWithFormat:@"%@SecondCoordinateLongitude", key]];
    return YMKMapRectMake(YMKMapCoordinateMake(firstCoordinateLatitude, firstCoordinateLongitude), YMKMapCoordinateMake(secondCoordinateLatitude, secondCoordinateLongitude));
}

- (void)encodeMapRect:(YMKMapRect)rect forKey:(NSString*)key
{
    [self encodeDouble:rect.topLeft.latitude forKey:[NSString stringWithFormat:@"%@FirstCoordinateLatitude", key]];
	[self encodeDouble:rect.topLeft.longitude forKey:[NSString stringWithFormat:@"%@FirstCoordinateLongitude", key]];
	[self encodeDouble:rect.bottomRight.latitude forKey:[NSString stringWithFormat:@"%@SecondCoordinateLatitude", key]];
	[self encodeDouble:rect.bottomRight.longitude forKey:[NSString stringWithFormat:@"%@SecondCoordinateLongitude", key]];
}

- (NSArray*)decodeMapPolygonForKey:(NSString*)key
{
    NSArray* polygonWithArrayCoordinates = [self decodeObjectForKey:key];
    NSMutableArray* mapPolygon = [NSMutableArray array];
    for(NSArray* coordinate in polygonWithArrayCoordinates)
        [mapPolygon addObject:[NSValue valueWithYMKMapCoordinate:YMKMapCoordinateMake([coordinate[0] doubleValue], [coordinate[1] doubleValue])]];
    return mapPolygon;
}

- (void)encodeMapPolygon:(NSArray*)polygon forKey:(NSString*)key
{
    NSMutableArray* polygonWithArrayCoordinates = [NSMutableArray array];
    for(NSValue* coordinateValue in polygon)
        [polygonWithArrayCoordinates addObject:@[@(coordinateValue.YMKMapCoordinateValue.latitude), @(coordinateValue.YMKMapCoordinateValue.longitude)]];
    [self encodeObject:polygonWithArrayCoordinates forKey:key];
}

@end

@implementation NSDateFormatter (FormattingAndParsing)

static NSDateFormatter* rfcDateParserPtr = nil;

+ (NSDateFormatter*)rfcDateParser
{
    if(rfcDateParserPtr == nil)
    {
        rfcDateParserPtr = [[NSDateFormatter alloc] init];
        [rfcDateParserPtr setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:4 * 60 * 60]];
        [rfcDateParserPtr setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
    }
    
    return rfcDateParserPtr;
}

static NSDateFormatter* rfcDateWithoutMillisecondsParserPtr = nil;

+ (NSDateFormatter*)rfcDateWithoutMillisecondsParser
{
    if(rfcDateWithoutMillisecondsParserPtr == nil)
    {
        rfcDateWithoutMillisecondsParserPtr = [[NSDateFormatter alloc] init];
        [rfcDateWithoutMillisecondsParserPtr setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:4 * 60 * 60]];
        [rfcDateWithoutMillisecondsParserPtr setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    }
    
    return rfcDateWithoutMillisecondsParserPtr;
}

static NSDateFormatter* shortDateParserPtr = nil;

+ (NSDateFormatter*)shortDateParser
{
    if(shortDateParserPtr == nil)
    {
        shortDateParserPtr = [[NSDateFormatter alloc] init];
        [shortDateParserPtr setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:4 * 60 * 60]];
        [shortDateParserPtr setDateFormat:@"dd.MM.yyyy"];
    }
    
    return shortDateParserPtr;
}

static NSDateFormatter* adviceDateParserPtr = nil;

+ (NSDateFormatter*)adviceDateParser
{
    if(adviceDateParserPtr == nil)
    {
        adviceDateParserPtr = [[NSDateFormatter alloc] init];
        [adviceDateParserPtr setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:4 * 60 * 60]];
        [adviceDateParserPtr setDateFormat:@"dd.MM.yyyy', 'HH:mm"];
    }
    
    return adviceDateParserPtr;
}

+ (NSDate*)tryParseFromAnyFomattedString:(NSString*)string
{
    NSDate* date = nil;
    
    if(date == nil)
        date = [[NSDateFormatter rfcDateParser] dateFromString:string];
    
    if(date == nil)
        date = [[NSDateFormatter rfcDateWithoutMillisecondsParser] dateFromString:string];
    
    if(date == nil)
        date = [[NSDateFormatter shortDateParser] dateFromString:string];
    
    if(date == nil)
        date = [[NSDateFormatter adviceDateParser] dateFromString:string];
    
    return date;
}

static NSDateFormatter* relativeLongStyleDateFormatterPtr = nil;

+ (NSDateFormatter*)relativeLongStyleDateFormatter
{
    if(relativeLongStyleDateFormatterPtr == nil)
    {
        relativeLongStyleDateFormatterPtr = [[NSDateFormatter alloc] init];
        [relativeLongStyleDateFormatterPtr setTimeStyle:NSDateFormatterNoStyle];
        [relativeLongStyleDateFormatterPtr setDateStyle:NSDateFormatterLongStyle];
        [relativeLongStyleDateFormatterPtr setDoesRelativeDateFormatting:YES];
        [relativeLongStyleDateFormatterPtr setTimeZone:[NSTimeZone systemTimeZone]];
        [relativeLongStyleDateFormatterPtr setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ru"]];
    }

    return relativeLongStyleDateFormatterPtr;
}

static NSDateFormatter* relativeLongStyleDateAndTimeFormatterPtr = nil;

+ (NSDateFormatter*)relativeLongStyleDateAndTimeFormatter
{
    if(relativeLongStyleDateAndTimeFormatterPtr == nil)
    {
        relativeLongStyleDateAndTimeFormatterPtr = [[NSDateFormatter alloc] init];
        [relativeLongStyleDateAndTimeFormatterPtr setTimeStyle:NSDateFormatterShortStyle];
        [relativeLongStyleDateAndTimeFormatterPtr setDateStyle:NSDateFormatterLongStyle];
        [relativeLongStyleDateAndTimeFormatterPtr setDoesRelativeDateFormatting:YES];
        [relativeLongStyleDateAndTimeFormatterPtr setTimeZone:[NSTimeZone systemTimeZone]];
        [relativeLongStyleDateAndTimeFormatterPtr setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ru"]];
    }
    
    return relativeLongStyleDateAndTimeFormatterPtr;
}

static NSDateFormatter* relativeShortStyleDateAndTimeFormatterPtr = nil;

+ (NSDateFormatter*)relativeShortStyleDateAndTimeFormatter
{
    if(relativeShortStyleDateAndTimeFormatterPtr == nil)
    {
        relativeShortStyleDateAndTimeFormatterPtr = [[NSDateFormatter alloc] init];
        [relativeShortStyleDateAndTimeFormatterPtr setTimeStyle:NSDateFormatterShortStyle];
        [relativeShortStyleDateAndTimeFormatterPtr setDateStyle:NSDateFormatterShortStyle];
        [relativeShortStyleDateAndTimeFormatterPtr setDoesRelativeDateFormatting:YES];
        [relativeShortStyleDateAndTimeFormatterPtr setTimeZone:[NSTimeZone systemTimeZone]];
        [relativeShortStyleDateAndTimeFormatterPtr setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ru"]];
    }
    
    return relativeShortStyleDateAndTimeFormatterPtr;
}

static NSDateFormatter* shortStyleDateFormatterPtr = nil;

+ (NSDateFormatter*)shortStyleDateFormatter
{
    if(shortStyleDateFormatterPtr == nil)
    {
        shortStyleDateFormatterPtr = [[NSDateFormatter alloc] init];
        [shortStyleDateFormatterPtr setTimeStyle:NSDateFormatterNoStyle];
        [shortStyleDateFormatterPtr setDateStyle:NSDateFormatterShortStyle];
        [shortStyleDateFormatterPtr setDoesRelativeDateFormatting:YES];
        [shortStyleDateFormatterPtr setTimeZone:[NSTimeZone systemTimeZone]];
        [shortStyleDateFormatterPtr setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ru"]];
    }
    
    return shortStyleDateFormatterPtr;
}

static NSDateFormatter* shortStyleWithFullYearDateFormatterPtr = nil;

+ (NSDateFormatter*)shortStyleWithFullYearDateFormatter
{
    if(shortStyleWithFullYearDateFormatterPtr == nil)
    {
        shortStyleWithFullYearDateFormatterPtr = [[NSDateFormatter alloc] init];
        [shortStyleWithFullYearDateFormatterPtr setDateFormat:@"dd.MM.yyyy"];
        [shortStyleWithFullYearDateFormatterPtr setTimeZone:[NSTimeZone systemTimeZone]];
    }
    
    return shortStyleWithFullYearDateFormatterPtr;
}

static NSDateFormatter* shortStyleTimeFormatterPtr = nil;

+ (NSDateFormatter*)shortStyleTimeFormatter
{
    if(shortStyleTimeFormatterPtr == nil)
    {
        shortStyleTimeFormatterPtr = [[NSDateFormatter alloc] init];
        [shortStyleTimeFormatterPtr setTimeStyle:NSDateFormatterShortStyle];
        [shortStyleTimeFormatterPtr setDateStyle:NSDateFormatterNoStyle];
        [shortStyleTimeFormatterPtr setTimeZone:[NSTimeZone systemTimeZone]];
        [shortStyleTimeFormatterPtr setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ru"]];
    }
    
    return shortStyleTimeFormatterPtr;
}

static NSDateFormatter* shortStyleDateAndTimeFormatterPtr = nil;

+ (NSDateFormatter*)shortStyleDateAndTimeFormatter
{
    if(shortStyleDateAndTimeFormatterPtr == nil)
    {
        shortStyleDateAndTimeFormatterPtr = [[NSDateFormatter alloc] init];
        [shortStyleDateAndTimeFormatterPtr setTimeStyle:NSDateFormatterShortStyle];
        [shortStyleDateAndTimeFormatterPtr setDateStyle:NSDateFormatterShortStyle];
        [shortStyleDateAndTimeFormatterPtr setDoesRelativeDateFormatting:YES];
        [shortStyleDateAndTimeFormatterPtr setTimeZone:[NSTimeZone systemTimeZone]];
        [shortStyleDateAndTimeFormatterPtr setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ru"]];
    }
    
    return shortStyleDateAndTimeFormatterPtr;
}

@end

@implementation NSDate (DateFromComponents)

+ (NSDate*)hundredYearsAgo
{
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    NSDate* now = [NSDate date];
    NSCalendar* gregorian = [NSCalendar currentCalendar];
    NSDateComponents* comps = [gregorian components:unitFlags fromDate:now];
    [comps setYear:[comps year] - 100];
    return [gregorian dateFromComponents:comps];
}

+ (NSDate*)dateWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day
{
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents* components = [[NSDateComponents alloc] init];
    [components setYear:year];
    [components setMonth:month];
    [components setDay:day];
    return [calendar dateFromComponents:components];
}

+ (NSDateComponents*)componentsFromDate:(NSDate*)date
{
    if(date == nil)
        return nil;
    
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    return [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:date];
}

- (BOOL)equalsWithDayPrecisionToDate:(NSDate*)date
{
    NSDateComponents* myComponents = [NSDate componentsFromDate:self];
    NSDateComponents* dateComponents = [NSDate componentsFromDate:date];
    return myComponents.year == dateComponents.year && myComponents.month == dateComponents.month && myComponents.day == dateComponents.day;
}

@end

@implementation MRActivityIndicatorView (StartAnimatingWithoutRenderTree)

- (void)didMoveToWindow
{
    if(self.window != nil && self.isAnimating)
    {
        [self stopAnimating];
        [self startAnimating];
    }
}

@end

@implementation YMKConfiguration (MapLayers)

- (uint16_t)mapLayerIdentifierForMapType:(MapType)mapType
{
    if(self.mapLayers.infos.count > 0)
        return ((YMKMapLayerInfo*)self.mapLayers.infos[mapType]).identifier;
    
    return UINT16_MAX;
}

@end

@implementation YMKMapView (YMKMapViewExtended)

- (void)willMoveToSuperview:(UIView*)newSuperview
{
    if([YMKConfiguration sharedInstance].mapLayers == nil)
    {
        if(newSuperview == nil)
            [[NSNotificationCenter defaultCenter] removeObserver:self name:YMKConfigurationUpdatedMapLayers object:nil];
        else if(self.superview == nil)
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configurationUpdatedMapLayers:) name:YMKConfigurationUpdatedMapLayers object:nil];
    }
    
    if(newSuperview == nil)
        [[NSNotificationCenter defaultCenter] removeObserver:self name:YMKMapChangedMapType object:nil];
    else if(self.superview == nil)
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(otherMapChangedMapType:) name:YMKMapChangedMapType object:nil];
    
    if(self.superview == nil)
    {
        UITapGestureRecognizer* doubleTapGestureRecognizer = [[self valueForKey:@"_overlayView"] valueForKey:@"_doubleTapGestureRecognizer"];
        doubleTapGestureRecognizer.delaysTouchesEnded = NO;
    }
}

- (void)configurationUpdatedMapLayers:(NSNotification*)notification
{
    uint16_t mapLayerIdentifier = [[YMKConfiguration sharedInstance] mapLayerIdentifierForMapType:self.mapType];
    if(mapLayerIdentifier != UINT16_MAX)
        self.visibleLayerIdentifier = mapLayerIdentifier;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:YMKConfigurationUpdatedMapLayers object:nil];
}

- (void)otherMapChangedMapType:(NSNotification*)notification
{
    [self setMapType:[notification.object integerValue] andNotifyOtherMaps:NO];
}

- (MapType)mapType
{
    return self.tag;
}

- (void)setMapType:(MapType)mapType
{
    [self setMapType:mapType andNotifyOtherMaps:YES];
}

- (void)setMapType:(MapType)mapType andNotifyOtherMaps:(BOOL)notifyOtherMaps
{
    self.tag = mapType;
    uint16_t mapLayerIdentifier = [[YMKConfiguration sharedInstance] mapLayerIdentifierForMapType:mapType];
    if(mapLayerIdentifier != UINT16_MAX)
        self.visibleLayerIdentifier = mapLayerIdentifier;
    
    if(notifyOtherMaps)
        [[NSNotificationCenter defaultCenter] postNotificationName:YMKMapChangedMapType object:@(mapType)];
}

- (UIPanGestureRecognizer*)panGestureRecognizer
{
    return ((UIScrollView*)[self valueForKey:@"_scrollView"]).panGestureRecognizer;
}

- (UITapGestureRecognizer*)doubleTapGestureRecognizer
{
    return [[self valueForKey:@"_overlayView"] valueForKey:@"_doubleTapGestureRecognizer"];
}

- (UITapGestureRecognizer*)twoFingerTapGestureRecognizer
{
    return [[self valueForKey:@"_overlayView"] valueForKey:@"_twoFingerTapGestureRecognizer"];
}

- (UIScrollView*)internalScrollView
{
    return (UIScrollView*)[self valueForKey:@"_scrollView"];
}

- (void)applyUserLocatingBatterySavingSettings
{
    CLLocationManager* mapLocationManager = (CLLocationManager*)[[[self valueForKey:@"_userLocationController"] valueForKey:@"_locationManager"] valueForKey:@"_locationManager"];
    mapLocationManager.pausesLocationUpdatesAutomatically = YES;
    mapLocationManager.activityType = CLActivityTypeFitness;
    mapLocationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    [mapLocationManager stopMonitoringSignificantLocationChanges];
    [mapLocationManager stopUpdatingHeading];
}

- (void)subscribeDelegateToExtendedEvents
{
    UITapGestureRecognizer* doubleTapGestureRecognizer = [[self valueForKey:@"_overlayView"] valueForKey:@"_doubleTapGestureRecognizer"];
    UITapGestureRecognizer* twoFingerTapGestureRecognizer = [[self valueForKey:@"_overlayView"] valueForKey:@"_twoFingerTapGestureRecognizer"];
    [doubleTapGestureRecognizer addTarget:self action:@selector(handleDoubleTapExtended)];
    [twoFingerTapGestureRecognizer addTarget:self action:@selector(handleTwoFingersTapExtended)];
}

- (void)handleDoubleTapExtended
{
    if(self.delegate != nil && [self.delegate respondsToSelector:@selector(mapViewGotDoubleTap:)])
        [(id<YMKMapViewDelegateExtended>)self.delegate mapViewGotDoubleTap:self];
}

- (void)handleTwoFingersTapExtended
{
    if(self.delegate != nil && [self.delegate respondsToSelector:@selector(mapViewGotTwoFingersTap:)])
        [(id<YMKMapViewDelegateExtended>)self.delegate mapViewGotTwoFingersTap:self];
}

@end

@implementation UIActivityViewController (NoRotation)

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

@end

@implementation UIViewController (CustomSizeFormSheet)

- (void)presentFormSheetController:(UIViewController*)viewControllerToPresent animated:(BOOL)flag withSize:(CGSize)size
{
    viewControllerToPresent.modalPresentationStyle = UIModalPresentationFormSheet;
    viewControllerToPresent.preferredContentSize = size;
    
    [self presentViewController:viewControllerToPresent animated:flag completion:nil];
    
    if(SYSTEM_VERSION_LESS_THAN(@"8"))
    {
        viewControllerToPresent.view.frame = CGRectInset(viewControllerToPresent.view.frame, (viewControllerToPresent.view.frame.size.width - viewControllerToPresent.preferredContentSize.width) / 2, (viewControllerToPresent.view.frame.size.height - viewControllerToPresent.preferredContentSize.height) / 2);
        viewControllerToPresent.view.superview.backgroundColor = [UIColor clearColor];
    }
}

@end

@implementation UIView (BlurBackground)

- (UIToolbar*)addBlurBackgroundWithTintColor:(UIColor*)color
{
    self.backgroundColor = [UIColor clearColor];
    
    //make toolbar width for the whole screen to remove blur effect transparency glitch -
    //toolbars were meant to be of whole screen width, Apple is unlikely to introduce any blur changes here
    //(for iPads make their width as screen height as max available value)
    
    CGFloat toolbarWidth;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        toolbarWidth = [UIScreen mainScreen].bounds.size.width;
    else
        toolbarWidth = [UIScreen mainScreen].bounds.size.height;
    
    UIToolbar* bgBlurToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, toolbarWidth, self.frame.size.height)];
    bgBlurToolbar.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    bgBlurToolbar.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self insertSubview:bgBlurToolbar atIndex:0];
    
    if(color != nil)
    {
        //add color by adding the view with needed alpha above
        //regular view drawing is unlikely to change and toolbars are likely to remain blurred with white
        UIView* colorView = [[UIView alloc] initWithFrame:bgBlurToolbar.bounds];
        colorView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        colorView.backgroundColor = color;
        [bgBlurToolbar addSubview:colorView];
    }
    
    return bgBlurToolbar;
}

@end


@implementation UIView (MotionEffects)

- (void)addMotionEffectWithMotionAmount:(CGFloat)amount isAbove:(BOOL)isAbove
{
    UIInterpolatingMotionEffect* effectX = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                              type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    UIInterpolatingMotionEffect* effectY = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                              type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    
    
    effectX.maximumRelativeValue = @(isAbove ? amount : -amount);
    effectX.minimumRelativeValue = @(isAbove ? -amount: amount);
    effectY.maximumRelativeValue = @(isAbove ? amount: -amount);
    effectY.minimumRelativeValue = @(isAbove ? -amount: amount);
    
    UIMotionEffectGroup* motionGroup = [[UIMotionEffectGroup alloc] init];
    motionGroup.motionEffects = @[effectX, effectY];
    
    [self addMotionEffect:motionGroup];
}

- (void)addAboveMotionEffectWithMotionAmount:(CGFloat)amount
{
    [self addMotionEffectWithMotionAmount:amount isAbove:YES];
}

- (void)addBelowMotionEffectWithMotionAmount:(CGFloat)amount
{
    [self addMotionEffectWithMotionAmount:amount isAbove:NO];
}

@end

@implementation UIView (Genie)

#pragma mark - Constants

/* Animation parameters
 *
 * Genie effect consists of two such subanimations: the curves subanimation and the slide subanimation.
 * There former one moves Bezier curves outlining the effect's shape, while the latter one slides
 * the subject view towards/from the destination/start rect.
 
 * These parameters describe the percentages of progress at which the subanimations should start/end.
 * These values must be in range [0, 1]!
 *
 * Example:
 * Assuming that duration of animation is set to 2 seconds then the curves subanimation will start
 * at 0.0 and will end at 0.8 seconds while the slide subanimation will start at 0.6 seconds and
 * will end at 2.0 seconds.
 */

static const double curvesAnimationStart = 0.0;
static const double curvesAnimationEnd = 0.4;
static const double slideAnimationStart = 0.3;
static const double slideAnimationEnd = 1.0;

/* Performance parameters
 *
 * Because the default linear interpolation of nontrivial CATransform3D causes them to act *wildly*
 * I've decided to use discrete animations, i.e. each frame is distinct and is calculated separately.
 * While this makes sure that animations behave correctly, it *may* cause some performance issues for
 * very long durations and/or large views.
 */

static const CGFloat kSliceSize = 10.0f; // height/width of a single slice
static const NSTimeInterval kFPS = 60.0; // assumed animation's FPS


/* Antialiasing parameter
 *
 * While there is a visible difference between 0.0 and 1.0 values in kRenderMargin constant, larger values
 * do not seem to provide any significant improvement in edges quality and will decrease performance.
 * The default value works great and you should change it only if you manage to convince yourself
 * that it does bring quality improvement.
 */

static const CGFloat kRenderMargin = 2.0;


#pragma mark - Structs & enums boilerplate

#define isEdgeVertical(d) (!((d) & 1))
#define isEdgeNegative(d) (((d) & 2))
#define axisForEdge(d) ((BCAxis)isEdgeVertical(d))
#define perpAxis(d) ((BCAxis)(!(BOOL)d))

typedef NS_ENUM(NSInteger, BCAxis) {
    BCAxisX = 0,
    BCAxisY = 1
};

// It's not an ego issue that I wanted to have my own CGPoints, it's just that it's easier
// to access specific axis by treating point as two element array, therefore I'm using union.
// Moreover, CGFloat is a typedefed float, and floats have much lower precision, causing slices
// to misalign occasionaly. Using doubles completely (?) removed the issue.

typedef union BCPoint
{
    struct { double x, y; };
    double v[2];
}
BCPoint;

static inline BCPoint BCPointMake(double x, double y)
{
    BCPoint p; p.x = x; p.y = y; return p;
}

typedef union BCTrapezoid {
    struct { BCPoint a, b, c, d; };
    BCPoint v[4];
} BCTrapezoid;


typedef struct BCSegment {
    BCPoint a;
    BCPoint b;
} BCSegment;

static inline BCSegment BCSegmentMake(BCPoint a, BCPoint b)
{
    BCSegment s; s.a = a; s.b = b; return s;
}

typedef BCSegment BCBezierCurve;

static const int BCTrapezoidWinding[4][4] = {
    [BCRectEdgeTop]    = {0,1,2,3},
    [BCRectEdgeLeft]   = {2,0,3,1},
    [BCRectEdgeBottom] = {3,2,1,0},
    [BCRectEdgeRight]  = {1,3,0,2},
};

#pragma mark - publics

- (void)genieInTransitionWithDuration:(NSTimeInterval)duration destinationRect:(CGRect)destRect destinationEdge:(BCRectEdge)destEdge completion:(void (^)())completion {
    
    [self genieTransitionWithDuration:duration
                                 edge:destEdge
                      destinationRect:destRect
                              reverse:NO
                           completion:completion];
}

- (void)genieOutTransitionWithDuration:(NSTimeInterval)duration startRect:(CGRect)startRect startEdge:(BCRectEdge)startEdge completion:(void (^)())completion {
    [self genieTransitionWithDuration:duration
                                 edge:startEdge
                      destinationRect:startRect
                              reverse:YES
                           completion:completion];
}

- (UIImage*)renderedViewImage
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);
    if([self isKindOfClass:[UIScrollView class]])
        CGContextTranslateCTM(UIGraphicsGetCurrentContext(), -((UIScrollView*)self).contentOffset.x - ((UIScrollView*)self).contentInset.left, -((UIScrollView*)self).contentOffset.y - ((UIScrollView*)self).contentInset.top);

    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:NO];
    UIImage* render = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return render;
}


#pragma mark - privates


- (void) genieTransitionWithDuration:(NSTimeInterval) duration
                                edge:(BCRectEdge) edge
                     destinationRect:(CGRect)destRect
                             reverse:(BOOL)reverse
                          completion:(void (^)())completion
{
    assert(!CGRectIsNull(destRect));
    
    BCAxis axis = axisForEdge(edge);
    BCAxis pAxis = perpAxis(axis);
    
    self.transform = CGAffineTransformIdentity;
    
    UIImage *snapshot = [self renderSnapshotWithMarginForAxis:axis];
    NSArray *slices = [self sliceImage:snapshot toLayersAlongAxis:axis];
    
    // Bezier calculations
    CGFloat xInset = axis == BCAxisY ? -kRenderMargin : 0.0f;
    CGFloat yInset = axis == BCAxisX ? -kRenderMargin : 0.0f;
    
    CGRect marginedDestRect = CGRectInset(destRect, xInset*destRect.size.width/self.bounds.size.width, yInset*destRect.size.height/self.bounds.size.height);
    CGFloat endRectDepth = isEdgeVertical(edge) ? marginedDestRect.size.height : marginedDestRect.size.width;
    BCSegment aPoints = bezierEndPointsForTransition(edge, [self convertRect:CGRectInset(self.bounds, xInset, yInset) toView:self.superview]);
    
    BCSegment bEndPoints = bezierEndPointsForTransition(edge, marginedDestRect);
    BCSegment bStartPoints = aPoints;
    bStartPoints.a.v[axis] = bEndPoints.a.v[axis];
    bStartPoints.b.v[axis] = bEndPoints.b.v[axis];
    
    BCBezierCurve first = {aPoints.a, bStartPoints.a};
    BCBezierCurve second = {aPoints.b, bStartPoints.b};
    
    // View hierarchy setup
    
    NSString *sumKeyPath = isEdgeVertical(edge) ? @"@sum.bounds.size.height" : @"@sum.bounds.size.width";
    CGFloat totalSize = [[slices valueForKeyPath:sumKeyPath] floatValue];
    
    CGFloat sign = isEdgeNegative(edge) ? -1.0 : 1.0;
    
    if (sign*(aPoints.a.v[axis] - bEndPoints.a.v[axis]) > 0.0f) {
        
        
        NSLog(@"Genie Effect ERROR: The distance between %@ edge of animated view and %@ edge of %@ rect is incorrect. Animation will not be performed!", edgeDescription(edge), edgeDescription(edge), reverse ? @"star" : @"destination");
        if(completion) {
            completion();
        }
        return;
    } else if (sign*(aPoints.a.v[axis] + sign*totalSize - bEndPoints.a.v[axis]) > 0.0f) {
        NSLog(@"Genie Effect Warning: The %@ edge of animated view overlaps %@ edge of %@ rect. Glitches may occur.",edgeDescription((edge + 2) % 4), edgeDescription(edge), reverse ? @"start" : @"destination");
    }
    
    UIView *containerView = [[UIView alloc] initWithFrame:[self.superview bounds]];
    containerView.clipsToBounds = self.superview.clipsToBounds; // if superview does it then we should probably do it as well
    containerView.backgroundColor = [UIColor clearColor];
    [self.superview insertSubview:containerView belowSubview:self];
    
    NSMutableArray *transforms = [NSMutableArray arrayWithCapacity:[slices count]];
    
    for (CALayer *layer in slices) {
        [containerView.layer addSublayer:layer];
        
        // With 'Renders with edge antialiasing' = YES in info.plist the slices are
        // rendered with a border, this disables this making the UIView appear as supposed
        [layer setEdgeAntialiasingMask:0];
        
        [transforms addObject:[NSMutableArray array]];
    }
    
    BOOL previousHiddenState = self.hidden;
    self.hidden = YES; // hide self throught animation, slices will be shown instead
    
    // Animation frames
    
    NSInteger totalIter = duration*kFPS;
    double tSignShift = reverse ? -1.0 : 1.0;
    
    for (int i = 0; i < totalIter; i++) {
        
        double progress = ((double)i)/((double)totalIter - 1.0);
        double t = tSignShift*(progress - 0.5) + 0.5;
        
        double curveP = progressOfSegmentWithinTotalProgress(curvesAnimationStart, curvesAnimationEnd, t);
        
        first.b.v[pAxis] = easeInOutInterpolate(curveP, bStartPoints.a.v[pAxis], bEndPoints.a.v[pAxis]);
        second.b.v[pAxis] = easeInOutInterpolate(curveP, bStartPoints.b.v[pAxis], bEndPoints.b.v[pAxis]);
        
        double slideP = progressOfSegmentWithinTotalProgress(slideAnimationStart, slideAnimationEnd, t);
        
        NSArray *trs = [self transformationsForSlices:slices
                                                 edge:edge
                                        startPosition:easeInOutInterpolate(slideP, first.a.v[axis], first.b.v[axis])
                                            totalSize:totalSize
                                          firstBezier:first
                                         secondBezier:second
                                       finalRectDepth:endRectDepth];
        
        [trs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [(NSMutableArray *)transforms[idx] addObject:obj];
        }];
    }
    
    // Animation firing
    
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        
        [containerView removeFromSuperview];
        
        CGSize startSize = self.frame.size;
        CGSize endSize = destRect.size;
        
        CGPoint startOrigin = self.frame.origin;
        CGPoint endOrigin = destRect.origin;
        
        if (! reverse) {
            CGAffineTransform transform = CGAffineTransformMakeTranslation(endOrigin.x - startOrigin.x, endOrigin.y - startOrigin.y); // move to destination
            transform = CGAffineTransformTranslate(transform, -startSize.width/2.0, -startSize.height/2.0); // move top left corner to origin
            transform = CGAffineTransformScale(transform, endSize.width/startSize.width, endSize.height/startSize.height); // scale
            transform = CGAffineTransformTranslate(transform, startSize.width/2.0, startSize.height/2.0); // move back
            
            self.transform = transform;
        }
        
        self.hidden = previousHiddenState;
        
        if (completion) {
            completion();
        }
    }];
    
    [slices enumerateObjectsUsingBlock:^(CALayer *layer, NSUInteger idx, BOOL *stop) {
        
        CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
        anim.duration = duration;
        anim.values = transforms[idx];
        anim.calculationMode = kCAAnimationDiscrete;
        anim.removedOnCompletion = NO;
        anim.fillMode = kCAFillModeForwards;
        [layer addAnimation:anim forKey:@"transform"];
    }];
    
    [CATransaction commit];
}


- (UIImage *) renderSnapshotWithMarginForAxis:(BCAxis)axis
{
    CGSize contextSize = self.frame.size;
    CGFloat xOffset = 0.0f;
    CGFloat yOffset = 0.0f;
    
    if (axis == BCAxisY) {
        xOffset = kRenderMargin;
        contextSize.width += 2.0*kRenderMargin;
    } else {
        yOffset = kRenderMargin;
        contextSize.height += 2.0*kRenderMargin;
    }
    
    UIGraphicsBeginImageContextWithOptions(contextSize, NO, 0.0); // if you want to see border added for antialiasing pass YES as second param
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, xOffset, yOffset);
    
    [self.layer renderInContext:context];
    
    UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return snapshot;
}


- (NSArray *) sliceImage: (UIImage *) image toLayersAlongAxis: (BCAxis) axis
{
    CGFloat totalSize = axis == BCAxisY ? image.size.height : image.size.width;
    
    BCPoint origin = {0.0, 0.0};
    origin.v[axis] = kSliceSize;
    
    CGFloat scale = image.scale;
    CGSize sliceSize = axis == BCAxisY ? CGSizeMake(image.size.width, kSliceSize) : CGSizeMake(kSliceSize, image.size.height);
    
    NSInteger count = (NSInteger)ceilf(totalSize/kSliceSize);
    NSMutableArray *slices = [NSMutableArray arrayWithCapacity:count];
    
    for (int i = 0; i < count; i++) {
        CGRect rect = {i*origin.x*scale, i*origin.y*scale, sliceSize.width*scale, sliceSize.height*scale};
        CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, rect);
        UIImage *sliceImage = [UIImage imageWithCGImage:imageRef
                                                  scale:image.scale
                                            orientation:image.imageOrientation];
        CGImageRelease(imageRef);
        CALayer *layer = [CALayer layer];
        layer.anchorPoint = CGPointZero;
        layer.bounds = CGRectMake(0.0, 0.0, sliceImage.size.width, sliceImage.size.height);
        layer.contents = (__bridge id)(sliceImage.CGImage);
        layer.contentsScale = image.scale;
        [slices addObject:layer];
    }
    
    return slices;
}


- (NSArray *) transformationsForSlices: (NSArray *) slices
                                  edge: (BCRectEdge) edge
                         startPosition: (CGFloat) startPosition
                             totalSize: (CGFloat) totalSize
                           firstBezier: (BCBezierCurve) first
                          secondBezier: (BCBezierCurve) second
                        finalRectDepth: (CGFloat) rectDepth
{
    NSMutableArray *transformations = [NSMutableArray arrayWithCapacity:[slices count]];
    
    BCAxis axis = axisForEdge(edge);
    
    CGFloat rectPartStart = first.b.v[axis];
    CGFloat sign = isEdgeNegative(edge) ? -1.0 : 1.0;
    
    assert(sign*(startPosition - rectPartStart) <= 0.0);
    
    __block CGFloat position = startPosition;
    __block BCTrapezoid trapezoid = {0};
    trapezoid.v[BCTrapezoidWinding[edge][0]] = bezierAxisIntersection(first, axis, position);
    trapezoid.v[BCTrapezoidWinding[edge][1]] = bezierAxisIntersection(second, axis, position);
    
    NSEnumerationOptions enumerationOptions = isEdgeNegative(edge) ? NSEnumerationReverse : 0;
    
    [slices enumerateObjectsWithOptions:enumerationOptions usingBlock:^(CALayer *layer, NSUInteger idx, BOOL *stop) {
        
        CGFloat size = isEdgeVertical(edge) ? layer.bounds.size.height : layer.bounds.size.width;
        CGFloat endPosition = position + sign*size; // we're not interested in slices' origins since they will be moved around anyway
        
        double overflow = sign*(endPosition - rectPartStart);
        
        if (overflow <= 0.0f) { // slice is still in bezier part
            trapezoid.v[BCTrapezoidWinding[edge][2]] = bezierAxisIntersection(first, axis, endPosition);
            trapezoid.v[BCTrapezoidWinding[edge][3]] = bezierAxisIntersection(second, axis, endPosition);
        }
        else { // final rect part
            CGFloat shrunkSliceDepth = overflow*rectDepth/(double)totalSize; // how deep inside final rect "bottom" part of slice is
            
            trapezoid.v[BCTrapezoidWinding[edge][2]] = first.b;
            trapezoid.v[BCTrapezoidWinding[edge][2]].v[axis] += sign*shrunkSliceDepth;
            
            trapezoid.v[BCTrapezoidWinding[edge][3]] = second.b;
            trapezoid.v[BCTrapezoidWinding[edge][3]].v[axis] += sign*shrunkSliceDepth;
        }
        
        CATransform3D transform = [self transformRect:layer.bounds toTrapezoid:trapezoid];
        [transformations addObject:[NSValue valueWithCATransform3D:transform]];
        
        trapezoid.v[BCTrapezoidWinding[edge][0]] = trapezoid.v[BCTrapezoidWinding[edge][2]]; // next one starts where previous one ends
        trapezoid.v[BCTrapezoidWinding[edge][1]] = trapezoid.v[BCTrapezoidWinding[edge][3]];
        
        position = endPosition;
    }];
    
    if (isEdgeNegative(edge)) {
        return [[transformations reverseObjectEnumerator] allObjects];
    }
    
    return transformations;
}

// based on http://stackoverflow.com/a/12820877/558816
// X and Y is always assumed to be 0, that's why it's been dropped in the calculations
// All calculations are on doubles, to make sure that we get as much precsision as we can
// since even minor errors in transform matrix may cause major glitches
- (CATransform3D) transformRect: (CGRect) rect toTrapezoid: (BCTrapezoid) trapezoid
{
    
    double W = rect.size.width;
    double H = rect.size.height;
    
    double x1a = trapezoid.a.x;
    double y1a = trapezoid.a.y;
    
    double x2a = trapezoid.b.x;
    double y2a = trapezoid.b.y;
    
    double x3a = trapezoid.c.x;
    double y3a = trapezoid.c.y;
    
    double x4a = trapezoid.d.x;
    double y4a = trapezoid.d.y;
    
    double y21 = y2a - y1a,
    y32 = y3a - y2a,
    y43 = y4a - y3a,
    y14 = y1a - y4a,
    y31 = y3a - y1a,
    y42 = y4a - y2a;
    
    
    double a = -H*(x2a*x3a*y14 + x2a*x4a*y31 - x1a*x4a*y32 + x1a*x3a*y42);
    double b = W*(x2a*x3a*y14 + x3a*x4a*y21 + x1a*x4a*y32 + x1a*x2a*y43);
    double c = - H*W*x1a*(x4a*y32 - x3a*y42 + x2a*y43);
    
    double d = H*(-x4a*y21*y3a + x2a*y1a*y43 - x1a*y2a*y43 - x3a*y1a*y4a + x3a*y2a*y4a);
    double e = W*(x4a*y2a*y31 - x3a*y1a*y42 - x2a*y31*y4a + x1a*y3a*y42);
    double f = -(W*(x4a*(H*y1a*y32) - x3a*(H)*y1a*y42 + H*x2a*y1a*y43));
    
    double g = H*(x3a*y21 - x4a*y21 + (-x1a + x2a)*y43);
    double h = W*(-x2a*y31 + x4a*y31 + (x1a - x3a)*y42);
    double i = H*(W*(-(x3a*y2a) + x4a*y2a + x2a*y3a - x4a*y3a - x2a*y4a + x3a*y4a));
    
    const double kEpsilon = 0.0001;
    
    if(fabs(i) < kEpsilon) {
        i = kEpsilon* (i > 0 ? 1.0 : -1.0);
    }
    
    CATransform3D transform = {a/i, d/i, 0, g/i, b/i, e/i, 0, h/i, 0, 0, 1, 0, c/i, f/i, 0, 1.0};
    
    return transform;
}


#pragma mark - C convinience functions

static BCSegment bezierEndPointsForTransition(BCRectEdge edge, CGRect endRect)
{
    switch (edge) {
        case BCRectEdgeTop:
            return BCSegmentMake(BCPointMake(CGRectGetMinX(endRect), CGRectGetMinY(endRect)), BCPointMake(CGRectGetMaxX(endRect), CGRectGetMinY(endRect)));
        case BCRectEdgeBottom:
            return BCSegmentMake(BCPointMake(CGRectGetMaxX(endRect), CGRectGetMaxY(endRect)), BCPointMake(CGRectGetMinX(endRect), CGRectGetMaxY(endRect)));
        case BCRectEdgeRight:
            return BCSegmentMake(BCPointMake(CGRectGetMaxX(endRect), CGRectGetMinY(endRect)), BCPointMake(CGRectGetMaxX(endRect), CGRectGetMaxY(endRect)));
        case BCRectEdgeLeft:
            return BCSegmentMake(BCPointMake(CGRectGetMinX(endRect), CGRectGetMaxY(endRect)), BCPointMake(CGRectGetMinX(endRect), CGRectGetMinY(endRect)));
    }
    
    assert(0); // should never happen
}

static inline CGFloat progressOfSegmentWithinTotalProgress(CGFloat a, CGFloat b, CGFloat t)
{
    assert(b > a);
    
    return MIN(MAX(0.0, (t - a)/(b - a)), 1.0);
}

static inline CGFloat easeInOutInterpolate(float t, CGFloat a, CGFloat b)
{
    assert(t >= 0.0 && t <= 1.0); // we don't want any other values
    
    CGFloat val = a + t*t*(3.0 - 2.0*t)*(b - a);
    
    return b > a ? MAX(a,  MIN(val, b)) : MAX(b,  MIN(val, a)); // clamping, since numeric precision might bite here
}

static BCPoint bezierAxisIntersection(BCBezierCurve curve, BCAxis axis, CGFloat axisPos)
{
    assert((axisPos >= curve.a.v[axis] && axisPos <= curve.b.v[axis]) || (axisPos >= curve.b.v[axis] && axisPos <= curve.a.v[axis]));
    
    BCAxis pAxis = perpAxis(axis);
    
    BCPoint c1, c2;
    c1.v[pAxis] = curve.a.v[pAxis];
    c1.v[axis] = (curve.a.v[axis] + curve.b.v[axis])/2.0;
    
    c2.v[pAxis] = curve.b.v[pAxis];
    c2.v[axis] = (curve.a.v[axis] + curve.b.v[axis])/2.0;
    
    double t = (axisPos - curve.a.v[axis])/(curve.b.v[axis] - curve.a.v[axis]); // first approximation - treating curve as linear segment
    
    const int kIterations = 3; // Newton-Raphson iterations
    
    for (int i = 0; i < kIterations; i++) {
        double nt = 1.0 - t;
        
        double f = nt*nt*nt*curve.a.v[axis] + 3.0*nt*nt*t*c1.v[axis] + 3.0*nt*t*t*c2.v[axis] + t*t*t*curve.b.v[axis] - axisPos;
        double df = -3.0*(curve.a.v[axis]*nt*nt + c1.v[axis]*(-3.0*t*t + 4.0*t - 1.0) + t*(3.0*c2.v[axis]*t - 2.0*c2.v[axis] - curve.b.v[axis]*t));
        
        t -= f/df;
    }
    
    assert(t >= 0 && t <= 1.0);
    
    double nt = 1.0 - t;
    double intersection = nt*nt*nt*curve.a.v[pAxis] + 3.0*nt*nt*t*c1.v[pAxis] + 3.0*nt*t*t*c2.v[pAxis] + t*t*t*curve.b.v[pAxis];
    
    BCPoint ret;
    ret.v[axis] = axisPos;
    ret.v[pAxis] = intersection;
    
    return ret;
}

static inline NSString * edgeDescription(BCRectEdge edge)
{
    NSString *rectEdge[] = {
        [BCRectEdgeBottom] = @"bottom",
        [BCRectEdgeTop] = @"top",
        [BCRectEdgeRight] = @"right",
        [BCRectEdgeLeft] = @"left",
    };
    
    return rectEdge[edge];
}

@end

@implementation UIImage (BlurFromImage)

- (UIImage*)blurWithRadius:(CGFloat)radius
{
    // ***********If you need re-orienting (e.g. trying to blur a photo taken from the device camera front facing camera in portrait mode)
    // theImage = [self reOrientIfNeeded:theImage];
    
    // create our blurred image
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *inputImage = [CIImage imageWithCGImage:self.CGImage];
    
    // setting up Gaussian Blur (we could use one of many filters offered by Core Image)
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:inputImage forKey:kCIInputImageKey];
    [filter setValue:[NSNumber numberWithFloat:radius] forKey:@"inputRadius"];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    
    // CIGaussianBlur has a tendency to shrink the image a little,
    // this ensures it matches up exactly to the bounds of our original image
    CGImageRef cgImage = [context createCGImage:result fromRect:[inputImage extent]];
    
    UIImage *returnImage = [UIImage imageWithCGImage:cgImage];//create a UIImage for this function to "return" so that ARC can manage the memory of the blur... ARC can't manage CGImageRefs so we need to release it before this function "returns" and ends.
    CGImageRelease(cgImage);//release CGImageRef because ARC doesn't manage this on its own.
    
    return returnImage;
    
    // *************** if you need scaling
    // return [[self class] scaleIfNeeded:cgImage];
}

@end

@implementation UITableView (KeepSelection)

- (void)reloadDataAndKeepSelection
{
    NSIndexPath* selectedIndexPath = [self indexPathForSelectedRow];
    NSInteger numberOfSections = 0;
    NSInteger numberOfRows = 0;
    
    [self reloadData];
    
    if(self.dataSource != nil)
    {
        if(selectedIndexPath != nil)
        {
            numberOfSections = [self.dataSource numberOfSectionsInTableView:self];
            numberOfRows = [self.dataSource tableView:self numberOfRowsInSection:selectedIndexPath.section];
            if(selectedIndexPath.section < numberOfSections && selectedIndexPath.row < numberOfRows)
                [self selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }
}

@end
