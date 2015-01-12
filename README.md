# yandexmapkit_drawing

Support for drawing on yandex maps for https://github.com/yandexmobile/yandexmapkit-ios. 
Based on disassembling map internal structure. 

Tested with version 1.0.5.

Usage:

```
YandexMapDrawingCanvas* canvas = [[YandexMapDrawingCanvas alloc] initWithFrame:CGRectZero];
canvas.delegate = self;
[canvas addToMapView:self.mapView];
[canvas beginDrawingPolygon];
```

And implement YandexMapDrawingCanvasDelegate to know when the drawing is finished.

You can also add polygons using methods and set polygon fill and stroke color.

**This class is provided as is and I will not fix issues. It works good in my project.
It is a proof of concept and can be easily extended to draw circles and other shapes.**
