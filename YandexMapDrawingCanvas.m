//
//  YandexMapDrawingCanvas.m
//  Cian
//
//  Created by Иван Ерасов on 08.10.14.
//  Copyright (c) 2014 Cian group. All rights reserved.
//

#import "YandexMapDrawingCanvas.h"
#import "ClassesExtensions.h"

#define ContentOffsetPropertyKey @"contentOffset"
#define MaximumPointsInDrawnPolygon 100
#define ApproximationLength 25

static NSMutableSet* zoomingMapViews;

@implementation YMKMapView (ZoomingWithPolygon)

- (YandexMapDrawingCanvas*)drawingCanvas
{
    UIView* someView = self.internalScrollView.subviews[1];
    if([someView isKindOfClass:[YandexMapDrawingCanvas class]])
        return (YandexMapDrawingCanvas*)someView;
    else
        return nil;
}

- (void)removeOriginalZoomGesturesHandlers
{
    [self.doubleTapGestureRecognizer removeTarget:nil action:NULL];
    [self.twoFingerTapGestureRecognizer removeTarget:nil action:NULL];
    [self subscribeDelegateToExtendedEvents];
    [self.doubleTapGestureRecognizer addTarget:self action:@selector(doubleTap:)];
    [self.twoFingerTapGestureRecognizer addTarget:self action:@selector(twoFingersTap)];
}

- (void)increaseZoom
{
    [self increaseZoomAndCenterOnCoordinate:YMKMapCoordinateInvalid];
}

- (void)increaseZoomAndCenterOnCoordinate:(YMKMapCoordinate)coordinate
{
    if(self.zoomLevel < 17)
    {
        YMKMapCoordinate newCenter = self.centerCoordinate;
        if(!YMKMapCoordinateEqualToMapCoordinate(coordinate, YMKMapCoordinateInvalid))
            newCenter = coordinate;
        [self setCenterCoordinate:newCenter atZoomLevel:self.zoomLevel + 1 animated:YES];
    }
}

- (void)decreaseZoom
{
    if(self.zoomLevel > 1)
        [self setCenterCoordinate:self.centerCoordinate atZoomLevel:self.zoomLevel - 1 animated:YES];
}

- (void)doubleTap:(UITapGestureRecognizer*)recognizer
{
    YMKMapCoordinate newCenter = [self convertMapViewPointToLL:[recognizer locationInView:self]];
    [self increaseZoomAndCenterOnCoordinate:newCenter];
}

- (void)twoFingersTap
{
    [self decreaseZoom];
}

@end

@implementation YandexMapDrawingCanvas

@synthesize mapView;

- (id)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame])
        [self controlInit];
    return self;
}

- (id)initWithCoder:(NSCoder*)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
        [self controlInit];
    return self;
}

- (void)controlInit
{
    polygons = [NSMutableArray array];
    [self setBackgroundColor:[UIColor clearColor]];
    [self setUserInteractionEnabled:NO];
}

- (void)dealloc
{
    if(subscribedToContentOffsetChanges)
        [mapView.internalScrollView removeObserver:self forKeyPath:ContentOffsetPropertyKey];
}

#pragma mark - Inserting functions

- (void)addToMapView:(YMKMapView*)someMapView
{
    mapView = someMapView;
    self.frame = (CGRect){0, 0, mapView.frame.size};
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [mapView.internalScrollView insertSubview:self atIndex:1];
    [self updateLayouts];
    
    [mapView removeOriginalZoomGesturesHandlers];
    subscribedToContentOffsetChanges = YES;
    [mapView.internalScrollView addObserver:self forKeyPath:ContentOffsetPropertyKey options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if([keyPath isEqualToString:ContentOffsetPropertyKey])
        [self updateLayouts];
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)removeFromSuperview
{
    if(subscribedToContentOffsetChanges)
    {
        subscribedToContentOffsetChanges = NO;
        [mapView.internalScrollView removeObserver:self forKeyPath:ContentOffsetPropertyKey];
    }
    [super removeFromSuperview];
}

#pragma mark - Drawing polygon functions

- (void)beginDrawingPolygon
{
    if(mapView != nil)
    {
        isDrawingPolygon = YES;
        [self setUserInteractionEnabled:YES];
        
        drawnPolygonScreenPoints = [NSMutableArray array];
        [polygons removeAllObjects];
        [polygons addObject:[NSMutableArray array]];
        lastSavedPoint = CGPointZero;
        [self refreshCanvas];
        
        mapView.userInteractionEnabled = NO;
        self.frame = mapView.frame;
        [mapView.superview insertSubview:self aboveSubview:mapView];
        if(subscribedToContentOffsetChanges)
        {
            subscribedToContentOffsetChanges = NO;
            [mapView.internalScrollView removeObserver:self forKeyPath:ContentOffsetPropertyKey];
        }
    }
}

- (void)finishDrawingPolygon
{
    if(mapView != nil && isDrawingPolygon)
    {
        if([polygons[0] count] > MaximumPointsInDrawnPolygon)
        {
            if(self.delegate != nil && [self.delegate respondsToSelector:@selector(canvasFailedDrawingPolygon:)])
                [self.delegate canvasFailedDrawingPolygon:self];
        }
        else
        {
            [drawnPolygonScreenPoints removeAllObjects];
            drawnPolygonScreenPoints = nil;
            [self cancelDrawingPolygon];
            if(self.delegate != nil && [self.delegate respondsToSelector:@selector(canvasFinishedDrawingPolygon:)])
                [self.delegate canvasFinishedDrawingPolygon:self];
        }
    }
}

- (void)cancelDrawingPolygon
{
    if(mapView != nil && isDrawingPolygon)
    {
        drawnPolygonScreenPoints = nil;
        
        [self setUserInteractionEnabled:NO];
        mapView.userInteractionEnabled = YES;
        self.frame = (CGRect){0, 0, mapView.frame.size};
        [mapView.internalScrollView insertSubview:self atIndex:1];
        
        isDrawingPolygon = NO;
        [self updateLayouts];
        subscribedToContentOffsetChanges = YES;
        [mapView.internalScrollView addObserver:self forKeyPath:ContentOffsetPropertyKey options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    }
}

- (void)retryDrawingPolygon
{
    [self removeAllPolygons];
    [self addPolygon:[NSMutableArray array]];
    [drawnPolygonScreenPoints removeAllObjects];
    [self refreshCanvas];
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    if(isDrawingPolygon)
    {
        lastSavedPoint = [[touches anyObject] locationInView:self];
        [polygons[0] addObject:[NSValue valueWithYMKMapCoordinate:[mapView convertMapViewPointToLL:lastSavedPoint]]];
    }
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
    if(isDrawingPolygon)
    {
        CGPoint currentPoint = [[touches anyObject] locationInView:self];
        if(!CGRectContainsPoint(CGRectMake(lastSavedPoint.x - ApproximationLength, lastSavedPoint.y - ApproximationLength, ApproximationLength * 2, ApproximationLength * 2), currentPoint))
        {
            lastSavedPoint = currentPoint;
            [polygons[0] addObject:[NSValue valueWithYMKMapCoordinate:[mapView convertMapViewPointToLL:lastSavedPoint]]];
        }
        
        [drawnPolygonScreenPoints addObject:[NSValue valueWithCGPoint:currentPoint]];
        [self refreshCanvas];
    }
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    if(isDrawingPolygon)
    {
        CGPoint currentPoint = [[touches anyObject] locationInView:self];
        if(!CGRectContainsPoint(CGRectMake(lastSavedPoint.x - ApproximationLength, lastSavedPoint.y - ApproximationLength, ApproximationLength * 2, ApproximationLength * 2), currentPoint))
        {
            lastSavedPoint = currentPoint;
            [polygons[0] addObject:[NSValue valueWithYMKMapCoordinate:[mapView convertMapViewPointToLL:lastSavedPoint]]];
        }
        
        NSUInteger pointsCount = [polygons[0] count];
        
        if(pointsCount < 4)
        {
            if(pointsCount > 1)
                [polygons[0] removeObjectsInRange:NSMakeRange(1, pointsCount - 1)];
            
            for(NSInteger i = 0;i < 3;i++)
            {
                if(i == 0)
                lastSavedPoint = CGPointMake(lastSavedPoint.x + ApproximationLength, lastSavedPoint.y);
                else if(i == 1)
                    lastSavedPoint = CGPointMake(lastSavedPoint.x, lastSavedPoint.y - ApproximationLength);
                else
                    lastSavedPoint = CGPointMake(lastSavedPoint.x - ApproximationLength, lastSavedPoint.y);
                [polygons[0] addObject:[NSValue valueWithYMKMapCoordinate:[mapView convertMapViewPointToLL:lastSavedPoint]]];
            }
        }
        
        [self finishDrawingPolygon];
    }
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event
{
    [self touchesEnded:touches withEvent:event];
}

#pragma mark - Drawing functions

+ (Class)layerClass
{
    return [CAShapeLayer class];
}

- (void)updateLayouts
{
    CGRect frame = self.frame;
    frame.origin = mapView.internalScrollView.contentOffset;
    self.frame = frame;
    [self refreshCanvas];
}

- (void)refreshCanvas
{
    UIColor* strokeColor = self.polygonStrokeColor;
    if(strokeColor == nil)
        strokeColor = [UIColor colorWithRed:14.0/256.0 green:199.0/256.0 blue:220.0/256.0 alpha:0.6];
    UIColor* fillColor = self.polygonFillColor;
    if(fillColor == nil)
        fillColor = [UIColor colorWithRed:14.0/256.0 green:199.0/256.0 blue:220.0/256.0 alpha:0.15];
    
    ((CAShapeLayer*)self.layer).strokeColor = strokeColor.CGColor;
    ((CAShapeLayer*)self.layer).lineWidth = 4;
    ((CAShapeLayer*)self.layer).lineJoin = kCALineJoinRound;
    
    UIBezierPath* path = [UIBezierPath bezierPath];
    
    if(drawnPolygonScreenPoints.count > 0)
    {
        ((CAShapeLayer*)self.layer).fillColor = isDrawingPolygon ? NULL : fillColor.CGColor;
        
        [path moveToPoint:[drawnPolygonScreenPoints[0] CGPointValue]];
        
        for(NSValue* pointValue in drawnPolygonScreenPoints)
            [path addLineToPoint:pointValue.CGPointValue];
    }
    else
    {
        ((CAShapeLayer*)self.layer).fillColor = fillColor.CGColor;
        NSArray* currentPolygons = [NSArray arrayWithArray:polygons];
        
        for(NSArray* polygon in currentPolygons)
            if(polygon.count > 1)
            {
                CGPoint startPoint = [mapView convertLLToMapView:[polygon[0] YMKMapCoordinateValue]];
                [path moveToPoint:startPoint];
                
                for(NSValue* coordinateValue in polygon)
                {
                    CGPoint point = [mapView convertLLToMapView:coordinateValue.YMKMapCoordinateValue];
                    [path addLineToPoint:point];
                }
                
                [path addLineToPoint:startPoint];
            }
    }
    
    ((CAShapeLayer*)self.layer).path = path.CGPath;
    
    [self.layer setNeedsDisplay];
}

#pragma mark - Polygon functions

- (void)addPolygon:(NSArray*)polygon
{
    [polygons addObject:polygon];
}

- (void)removePolygonAtIndex:(NSInteger)index
{
    [polygons removeObjectAtIndex:index];
}

- (void)removePolygon:(NSArray*)polygon
{
    [polygons removeObject:polygon];
}

- (void)removeAllPolygons
{
    [polygons removeAllObjects];
}

- (NSArray*)polygonAtIndex:(NSInteger)index
{
    return polygons[index];
}

@end
