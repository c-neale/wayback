//
//  MapLocationViewController.m
//  carfinder
//
//  Created by Cory Neale on 29/05/2014.
//  Copyright (c) 2014 Cory Neale. All rights reserved.
//

#import "MapLocationViewController.h"

#import "MapMarker.h"

// for debugging...
#import <AddressBookUI/ABAddressFormatting.h>

@interface MapLocationViewController ()
{
    BOOL colSwitch;
}

- (void) calculateRouteFrom:(MapMarker *)source to:(MapMarker *)dest;
- (MKMapItem *)createMapItemFromMarker:(MapMarker *)marker;

@end

@implementation MapLocationViewController

#pragma mark - Properties

@synthesize locations;

#pragma mark - Init/lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        colSwitch = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    mapView.showsUserLocation = YES;
    
    MKUserLocation *userLocation = mapView.userLocation;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.location.coordinate, 50, 50);
    [mapView setRegion:region animated:NO];
    
    [mapView setCenterCoordinate:userLocation.coordinate animated:NO];

    [self addAnnotations];
    
    [self showDirections];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark helper functions

- (void) addAnnotations
{
    [self removeAnnotations];
    if (locations != nil)
    {
        [mapView addAnnotations:locations];
    }
}

// maybe move this to a category class?
- (void)removeAnnotations
{
    id userLocation = [mapView userLocation];
    NSMutableArray * pins = [[NSMutableArray alloc] initWithArray:[mapView annotations]];
    if ( userLocation != nil ) {
        [pins removeObject:userLocation]; // avoid removing user location off the map
    }
    
    [mapView removeAnnotations:pins];
    pins = nil;
}

- (void) showDirections
{
    for(int i = 0; i < locations.count; ++i)
    {
        MapMarker * source = (i == (locations.count - 1)) ? nil : [locations objectAtIndex:i+1];
        MapMarker * destination = [locations objectAtIndex:i];
        
        [self calculateRouteFrom:source to:destination];
    }
}

- (void) calculateRouteFrom:(MapMarker *)source to:(MapMarker *)dest
{
    if([dest routeCalcRequired] == YES)
    {
        [dest setRouteCalcRequired:NO];
        
        MKDirectionsRequest * dirRequest = [[MKDirectionsRequest alloc] init];
        [dirRequest setTransportType:MKDirectionsTransportTypeWalking];

        [dirRequest setSource:[self createMapItemFromMarker:source]];
        [dirRequest setDestination:[self createMapItemFromMarker:dest]];
    
        MKDirections * dirs = [[MKDirections alloc] initWithRequest:dirRequest];
    
        [dirs calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
            if(error != nil)
            {
                // TODO: handle this error better
                NSLog(@"error occurred calculating directions");
                NSLog(@"error info: %@", error);
                
                [dest setRouteCalcRequired:YES]; // error happened, wo reset this flag so it will get processed again next time.
            }
            else
            {
                // remove the current overlay, if it exists
                if(dest.route != nil)
                {
                    [mapView removeOverlay:dest.route.polyline];
                }
                
                // get the route from the response object
                MKRoute * route = response.routes.lastObject;
                
                // apply the new route overlay to the map.
                [mapView addOverlay:route.polyline level:MKOverlayLevelAboveRoads];
                
                // store the route on the destination for future reference.
                [dest setRoute:route];
            }
        }];
    }
}

- (MKMapItem *)createMapItemFromMarker:(MapMarker *)marker
{
    if(marker == nil)
    {
        return [MKMapItem mapItemForCurrentLocation];
    }
    
    MKPlacemark * markerPm = [[MKPlacemark alloc] initWithPlacemark:marker.placemark];
    return [[MKMapItem alloc] initWithPlacemark:markerPm];
}

#pragma mark - IBActions

- (IBAction)changeMapType:(UISegmentedControl *)sender
{
    switch(sender.selectedSegmentIndex)
    {
        case 0:
            mapView.mapType = MKMapTypeStandard;
            break;
        case 1:
            mapView.mapType = MKMapTypeSatellite;
            break;
        case 2:
            mapView.mapType = MKMapTypeHybrid;
            break;
    }
}

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mv didUpdateUserLocation:(MKUserLocation *)userLocation
{
    [mapView setCenterCoordinate:userLocation.coordinate animated:NO];
    
    MapMarker * marker = [locations lastObject];

    [marker setRouteCalcRequired:YES];
    [self calculateRouteFrom:nil to:marker];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    MKPolylineRenderer * routeLineRenderer = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
    
    if(colSwitch == NO) // alternate between red and blue paths (this is for debugging purposes)
    {
        routeLineRenderer.strokeColor = [UIColor redColor];
        routeLineRenderer.lineDashPhase = 5.0f;
    }
    else
    {
        routeLineRenderer.strokeColor = [UIColor blueColor];
        routeLineRenderer.lineDashPhase = 10.0f;
    }
    
    colSwitch = !colSwitch;
    
    routeLineRenderer.lineDashPattern = [[NSArray alloc] initWithObjects:[NSNumber numberWithInt:2], [NSNumber numberWithInt:12], nil];
    routeLineRenderer.lineWidth = 5;
    
    return routeLineRenderer;
}

@end
