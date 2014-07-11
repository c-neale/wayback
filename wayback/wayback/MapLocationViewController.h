//
//  MapLocationViewController.h
//  wayback
//
//  Created by Cory Neale on 29/05/2014.
//  Copyright (c) 2014 Cory Neale. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GAI.h"

@interface MapLocationViewController : GAITrackedViewController

@property (nonatomic, strong) NSMutableArray * locations;

- (IBAction)changeMapType:(UISegmentedControl *)sender;

- (void)addAnnotations;
- (void)removeAnnotations;

- (void) showDirections;

@end
