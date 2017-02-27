//
//  RCTBDMapManager.m
//  RCTBDMap
//
//  Created by DengYun on 4/27/16.
//  Copyright © 2016 DengYun. All rights reserved.
//

#import "RCTBDMapManager.h"
#import "RCTBDMap.h"
#import "RCTCovert+BDMap.h"
#import "RCTEventDispatcher.h"
#import "RCTBDMapMarker.h"
#import "UIView+React.h"
#import "RCTImageLoader.h"


@interface RCTBMKMapView : BMKMapView<BMKRouteSearchDelegate>

@property (nonatomic, copy) RCTDirectEventBlock onLoad;
@property (nonatomic, copy) RCTDirectEventBlock onRegionChange;
@property (nonatomic, copy) RCTDirectEventBlock onRegionChangeComplete;
@property (nonatomic) BOOL showZoomControls;
@end

@implementation RCTBMKMapView{
    NSMutableArray<RCTBDMapMarker*> *_markers;
    BMKPolyline* trace;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _markers = [NSMutableArray new];
        self.ChangeWithTouchPointCenterEnabled = YES;
    }
    return self;
}

- (void)setTraceData:(NSArray*) data
{
    if (self->trace != nil){
        [self removeOverlay: self->trace];
        self->trace = nil;
    }
    if (data != nil) {
        const int count = [data count];
        CLLocationCoordinate2D coords[count];
        for (int i = 0; i < count; i++) {
            coords[i].longitude = [data[i][0] doubleValue];
            coords[i].latitude = [data[i][1] doubleValue];
        }
        self->trace = [BMKPolyline polylineWithCoordinates:coords count:count];
        [self addOverlay:self->trace];
    }
}

- (void) setAnnotations:(NSArray*)data withImageLoader:(RCTImageLoader*) loader
{
    NSMutableDictionary* oldMarkers = [[NSMutableDictionary alloc] init];
    NSMutableDictionary* newMarkers = [[NSMutableDictionary alloc] init];

    NSArray* oldAnnos = [self annotations];
    for (int i = [oldAnnos count] - 1; i>=0; i--) {
        RCTBDMapMarker* anno = oldAnnos[i];
        [oldMarkers setObject:anno forKey:anno.key];
    }

    for (int i = [data count] - 1; i >=0; i--) {
        NSDictionary* dict = data[i];
        NSString* key = dict[@"id"];

        [newMarkers setObject:dict forKey:key];
        RCTBDMapMarker* marker = oldMarkers[key];
        if (marker == nil) {
            // Create new marker;
            marker = [[RCTBDMapMarker alloc] init];
            marker.key = key;
            [self addAnnotation:marker];
        }
        marker.coordinate = [RCTConvert CLLocationCoordinate2D:dict];

        NSString* imageUrl = dict[@"iconUrl"];

        if (imageUrl) {
            if (![marker.imageUrl isEqualToString:imageUrl]) {
              marker.imageUrl = imageUrl;
              [loader loadImageWithURLRequest:[RCTConvert NSURLRequest:imageUrl] callback:^(NSError *error, UIImage *image) {
                  dispatch_async(dispatch_get_main_queue(), ^(void) {
                      if ([marker.imageUrl isEqualToString:imageUrl]) {
                          marker.image = image;
                      }
                  });
              }];
            }
        } else if (marker.imageUrl) {
            marker.imageUrl = nil;
            marker.image = nil;
        }
    }

    NSMutableArray* removedMarkers = [[NSMutableArray alloc] init];
    for (int i = [oldAnnos count] - 1; i>=0; i--) {
        RCTBDMapMarker* anno = oldAnnos[i];
        if (newMarkers[anno.key] == nil) {
            [removedMarkers addObject:anno];
        }
    }
    if (removedMarkers.count > 0) {
        [self removeAnnotations:removedMarkers];
    }
}
-(void)setShowZoomControls:(BOOL)showZoomControls{
    NSLog(@"showZoomControls");
}

@end

@implementation RCTBDMapManager

RCT_EXPORT_MODULE(RCTBDMapViewManager)

- (UIView *)view
{
    RCTBMKMapView* ret = [[RCTBMKMapView alloc] init];
    ret.delegate = self;
    return ret;
}

RCT_EXPORT_VIEW_PROPERTY(onLoad, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onRegionChange, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onRegionChangeComplete, RCTDirectEventBlock)
//比例尺
RCT_EXPORT_VIEW_PROPERTY(showMapScaleBar, BOOL)
//仰角
RCT_EXPORT_VIEW_PROPERTY(overlookEnabled, BOOL)
//放大缩小按钮
RCT_EXPORT_VIEW_PROPERTY(showZoomControls, BOOL)

//logo位置
RCT_CUSTOM_VIEW_PROPERTY(logoPosition,NSString*,RCTBMKMapView)
{
    if (json) {
        BMKLogoPosition position ;
        if([json isEqualToString:@"leftTop"]){
            position = BMKLogoPositionLeftTop;
        }else if ([json isEqualToString:@"centerBottom"]){
            position = BMKLogoPositionCenterBottom;
        }else if ([json isEqualToString:@"centerTop"]){
            position = BMKLogoPositionCenterTop;
        }else if ([json isEqualToString:@"rightBottom"]){
            position = BMKLogoPositionRightBottom;
        }else if ([json isEqualToString:@"rightTop"]){
            position = BMKLogoPositionRightTop;
        }else{
            position = BMKLogoPositionLeftBottom;
        }
        [view setLogoPosition:position];
    }
}
RCT_CUSTOM_VIEW_PROPERTY(mapPadding,NSDictionary*,RCTBMKMapView)
{
    if (json) {
//        NSLog(@"json===%@",json);
        UIEdgeInsets edge ;
//        top, left, bottom, right;
        if ([json valueForKey: @"paddingTop"] != nil ) {
            edge.top = [[json valueForKey: @"paddingTop"] floatValue];
        }
        if ([json valueForKey: @"paddingLeft"] != nil ) {
            edge.left = [[json valueForKey: @"paddingLeft"] floatValue];
        }
        if ([json valueForKey: @"paddingBottom"] != nil ) {
            edge.bottom = [[json valueForKey: @"paddingBottom"] floatValue];

        }
        if ([json valueForKey: @"paddingRight"] != nil ) {
            edge.right = [[json valueForKey: @"paddingRight"] floatValue];
        }
//        NSLog(@"%f-%f-%f-%f",edge.top,edge.left,edge.bottom,edge.right);
//        [view setMapPadding:edge];
//        TODO
    }
}


RCT_CUSTOM_VIEW_PROPERTY(region, BMKCoordinateRegion, RCTBMKMapView)
{
    if (json) {
        [view setRegion: [RCTConvert BMKCoordinateRegion:json] animated:YES];
    }
}

RCT_CUSTOM_VIEW_PROPERTY(traceData, NSArray*, RCTBMKMapView)
{
    if (json) {
        [view setTraceData: json];
    }
}

RCT_CUSTOM_VIEW_PROPERTY(annotations, NSArray*, RCTBMKMapView)
{
    if (json) {
        [view setAnnotations: json withImageLoader: self.bridge.imageLoader];
    }
}

- (void)mapView:(RCTBMKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    if (mapView.onRegionChange) {
        mapView.onRegionChange([RCTBDMap _convertRegion:mapView.region]);
    }
}

- (void)mapStatusDidChanged:(RCTBMKMapView *)mapView{
    if (mapView.onRegionChangeComplete) {
        mapView.onRegionChangeComplete([RCTBDMap _convertRegion:mapView.region]);
    }
}

- (void)mapViewDidFinishLoading:(RCTBMKMapView *)mapView
{
    if ((mapView).onLoad) {
        (mapView).onLoad(@{});
    }
}

// Override
- (BMKOverlayView *)mapView:(BMKMapView *)mapView viewForOverlay:(id <BMKOverlay>)overlay{
    if ([overlay isKindOfClass:[BMKPolyline class]]){
        BMKPolylineView* polylineView = [[BMKPolylineView alloc] initWithOverlay:overlay];
        polylineView.strokeColor = [[UIColor purpleColor] colorWithAlphaComponent:1];
        polylineView.lineWidth = 5.0;

        return polylineView;
    }
    return nil;
}

- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id <BMKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[RCTBDMapMarker class]]) {
        BMKAnnotationView* ret = [[BMKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];
        ret.image = ((RCTBDMapMarker*)annotation).image;
        ret.canShowCallout = NO;
        ((RCTBDMapMarker*)annotation).annoView = ret;
        return ret;
    }
    return nil;
}

- (void)mapView:(BMKMapView *)mapView didSelectAnnotationView:(BMKAnnotationView *)view{
}

@end
