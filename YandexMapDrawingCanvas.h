//
//  YandexMapDrawingCanvas.h
//  Cian
//
//  Created by Иван Ерасов on 08.10.14.
//  Copyright (c) 2014 Cian group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YandexMapKit.h>

@class YandexMapDrawingCanvas;

@interface YMKMapView (ZoomingWithPolygon)

- (YandexMapDrawingCanvas*)drawingCanvas;

- (void)removeOriginalZoomGesturesHandlers;
- (void)increaseZoom;
- (void)decreaseZoom;

@end

@protocol YandexMapDrawingCanvasDelegate <NSObject>

@optional

- (void)canvasFinishedDrawingPolygon:(YandexMapDrawingCanvas*)canvas;
- (void)canvasFailedDrawingPolygon:(YandexMapDrawingCanvas*)canvas;

@end

@interface YandexMapDrawingCanvas : UIView
{
    NSMutableArray* polygons;
    __weak YMKMapView* mapView;
    BOOL subscribedToContentOffsetChanges;
    
    BOOL isDrawingPolygon;
    NSMutableArray* drawnPolygonScreenPoints;
    CGPoint lastSavedPoint;
}

@property (nonatomic, readonly) YMKMapView* mapView;
@property (nonatomic, strong) UIColor* polygonStrokeColor;
@property (nonatomic, strong) UIColor* polygonFillColor;
@property (nonatomic, weak) id<YandexMapDrawingCanvasDelegate> delegate;

- (void)addToMapView:(YMKMapView*)someMapView;

- (void)refreshCanvas;

- (void)beginDrawingPolygon;
- (void)finishDrawingPolygon; //also called automatically when user lifts finger from the screen
- (void)cancelDrawingPolygon;
- (void)retryDrawingPolygon; //deletes all polygons, screen points, adds 1 new polygon and refreshes canvas

- (void)addPolygon:(NSArray*)polygon;
- (void)removePolygonAtIndex:(NSInteger)index;
- (void)removePolygon:(NSArray*)polygon;
- (void)removeAllPolygons;
- (NSArray*)polygonAtIndex:(NSInteger)index;

@end
