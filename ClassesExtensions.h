//
//  ClassesExtensions.h
//  iRealtor
//
//  Created by Иван Ерасов on 30.10.13.
//  Copyright (c) 2013 iRealtor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YandexMapKit.h"
#import "StyleHelper.h"
#import "Constants.h"
#import <CoreImage/CoreImage.h>
#import <MRActivityIndicatorView.h>

extern NSString* YMKConfigurationUpdatedMapLayers;
extern NSString* YMKMapChangedMapType;

YMKMapRect YMKMapBoundingRectForCoordinate(YMKMapCoordinate coordinate);

@interface UIApplication (NetworkIndicator)

+ (void)setNetworkActivityIndicatorVisible:(BOOL)setVisible;

@end

@interface NSString (CalculatingSize)

- (CGFloat)widthWithFont:(UIFont*)font;
- (CGFloat)widthWithFont:(UIFont*)font constrainToSize:(CGSize)constraintSize;
- (CGFloat)heightWithWidth:(CGFloat)width andFont:(UIFont*)font;

@end

@interface NSString (HandyAdditions)

- (NSString*)stringByRemovingHTMLBreaks;
- (NSString*)firstLetterCapitalize;
+ (NSString*)pathFromComponents:(NSArray*)components;
- (NSString*)formattedIntegerString;

@end

@interface NSMutableAttributedString (HandyAdditions)

- (void)insertRoubleSymbolWithSize:(CGFloat)size;

@end

@interface NSArray (Reverse)

- (NSMutableArray*)reversedArray;

@end

@interface NSNotificationCenter (MainThread)

- (void)postNotificationOnMainThread:(NSNotification*)notification;
- (void)postNotificationOnMainThreadName:(NSString*)aName object:(id)anObject;
- (void)postNotificationOnMainThreadName:(NSString*)aName object:(id)anObject userInfo:(NSDictionary*)aUserInfo;

@end

@interface UIDevice (Hardware)

- (NSString*)platform;

@end

@interface UIColor (HexColors)

+ (UIColor*)colorWithHexString:(NSString*)hexString;
+ (NSString*)hexValuesFromUIColor:(UIColor*)color;

@end

@interface UIImage (ImageProcessing)

- (UIImage*)scaledAndRotatedImage;
- (UIImage*)imageByApplyingAlpha:(CGFloat)alpha;

+ (UIImage*)emptyImageWithSize:(CGSize)size andBackgroundColor:(UIColor*)color;

- (UIImage*)applyLightEffect;
- (UIImage*)applyExtraLightEffect;
- (UIImage*)applyDarkEffect;
- (UIImage*)applyTintEffectWithColor:(UIColor *)tintColor;

- (UIImage*)applyBlurWithRadius:(CGFloat)blurRadius tintColor:(UIColor*)tintColor
          saturationDeltaFactor:(CGFloat)saturationDeltaFactor maskImage:(UIImage*)maskImage;

@end

@interface NSCoder (MapValuesNSCoding)

- (YMKMapRect)decodeMapRectForKey:(NSString*)key;
- (void)encodeMapRect:(YMKMapRect)rect forKey:(NSString*)key;

- (NSArray*)decodeMapPolygonForKey:(NSString*)key;
- (void)encodeMapPolygon:(NSArray*)polygon forKey:(NSString*)key;

@end

@interface NSDateFormatter (FormattingAndParsing)

+ (NSDateFormatter*)rfcDateParser;
+ (NSDate*)tryParseFromAnyFomattedString:(NSString*)string;

+ (NSDateFormatter*)relativeLongStyleDateFormatter;
+ (NSDateFormatter*)relativeLongStyleDateAndTimeFormatter;
+ (NSDateFormatter*)relativeShortStyleDateAndTimeFormatter;
+ (NSDateFormatter*)shortStyleDateFormatter;
+ (NSDateFormatter*)shortStyleWithFullYearDateFormatter;
+ (NSDateFormatter*)shortStyleTimeFormatter;
+ (NSDateFormatter*)shortStyleDateAndTimeFormatter;

@end

@interface NSDate (DateFromComponents)

+ (NSDate*)hundredYearsAgo;
+ (NSDate*)dateWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day;
+ (NSDateComponents*)componentsFromDate:(NSDate*)date;
- (BOOL)equalsWithDayPrecisionToDate:(NSDate*)date;

@end

@interface MRActivityIndicatorView (StartAnimatingWithoutRenderTree)
@end

@interface YMKConfiguration (MapLayers)

- (uint16_t)mapLayerIdentifierForMapType:(MapType)mapType;

@end

@protocol YMKMapViewDelegateExtended <YMKMapViewDelegate>

@optional

- (void)mapViewGotDoubleTap:(YMKMapView*)mapView;
- (void)mapViewGotTwoFingersTap:(YMKMapView*)mapView;

@end

@interface YMKMapView (YMKMapViewExtended)

@property (nonatomic) MapType mapType;
@property (nonatomic, readonly) UIPanGestureRecognizer* panGestureRecognizer;
@property (nonatomic, readonly) UITapGestureRecognizer* doubleTapGestureRecognizer;
@property (nonatomic, readonly) UITapGestureRecognizer* twoFingerTapGestureRecognizer;
@property (nonatomic, readonly) UIScrollView* internalScrollView;

- (void)setMapType:(MapType)mapType andNotifyOtherMaps:(BOOL)notifyOtherMaps;

- (void)applyUserLocatingBatterySavingSettings;
- (void)subscribeDelegateToExtendedEvents;

@end

@interface YMKMapImageBuilder (SharedBuilder)

+ (YMKMapImageBuilder*)sharedInstance;

@end

@interface UIActivityViewController (NoRotation)

- (BOOL)shouldAutorotate;
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation;

@end

@interface UIViewController (CustomSizeFormSheet)

- (void)presentFormSheetController:(UIViewController*)viewControllerToPresent animated:(BOOL)flag withSize:(CGSize)size;

@end

@interface UIView (BlurBackground)

- (UIToolbar*)addBlurBackgroundWithTintColor:(UIColor*)color;

@end

#define MotionEffectsUltraLightEffectAmount 5
#define MotionEffectsLightEffectAmount 10
#define MotionEffectsMediumEffectAmount 15
#define MotionEffectsHighEffectAmount 20
#define MotionEffectsUltraEffectAmount 25

@interface UIView (MotionEffects)

- (void)addMotionEffectWithMotionAmount:(CGFloat)amount isAbove:(BOOL)isAbove;
- (void)addAboveMotionEffectWithMotionAmount:(CGFloat)amount;
- (void)addBelowMotionEffectWithMotionAmount:(CGFloat)amount;

@end

//  BCGenieEffect
//
//  Created by Bartosz Ciechanowski on 23.12.2012.
//  Copyright (c) 2012 Bartosz Ciechanowski. All rights reserved.

typedef NS_ENUM(NSUInteger, BCRectEdge)
{
    BCRectEdgeTop    = 0,
    BCRectEdgeLeft   = 1,
    BCRectEdgeBottom = 2,
    BCRectEdgeRight  = 3
};

@interface UIView (Genie)

/*
 * After the animation has completed the view's transform will be changed to match the destination's rect, i.e.
 * view's transform (and thus the frame) will change, however the bounds and center will *not* change.
 */

- (void)genieInTransitionWithDuration:(NSTimeInterval)duration
                      destinationRect:(CGRect)destRect
                      destinationEdge:(BCRectEdge)destEdge
                           completion:(void (^)())completion;



/*
 * After the animation has completed the view's transform will be changed to CGAffineTransformIdentity.
 */

- (void)genieOutTransitionWithDuration:(NSTimeInterval)duration
                             startRect:(CGRect)startRect
                             startEdge:(BCRectEdge)startEdge
                            completion:(void (^)())completion;

- (UIImage*)renderedViewImage;

@end

@interface UIImage (BlurFromImage)

- (UIImage*)blurWithRadius:(CGFloat)radius;

@end

@interface UITableView (KeepSelection)

- (void)reloadDataAndKeepSelection;

@end

