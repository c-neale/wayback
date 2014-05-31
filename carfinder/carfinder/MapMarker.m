//
//  MapMarker.m
//  carfinder
//
//  Created by Cory Neale on 29/05/2014.
//  Copyright (c) 2014 Cory Neale. All rights reserved.
//

#import "MapMarker.h"

@implementation MapMarker

@synthesize loc;
@synthesize name;

#pragma mark - MKAnnotation
// this will plot the marker to a correct place on map
- (CLLocationCoordinate2D)coordinate
{
    return loc.coordinate;
}

// this will be shown as marker title
- (NSString *)title
{
    return name;
}

// this will be shown as marker subtitle
- (NSString *)subtitle
{
    return @"";
}

@end
