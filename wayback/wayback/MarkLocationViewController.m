//
//  MarkLocationViewController.m
//  carfinder
//
//  Created by Cory Neale on 29/05/2014.
//  Copyright (c) 2014 Cory Neale. All rights reserved.
//

#import "MarkLocationViewController.h"

#import "MapLocationViewController.h"
#import "LocationDetailsViewController.h"

#import "MapMarker.h"

@interface MarkLocationViewController ()
{
    UIBarButtonItem * editButton;
}

- (void) toggleEditMode;
- (void) updateEditButtonVisiblity;

@end

@implementation MarkLocationViewController

#pragma mark - Properties

@synthesize locationManager;
@synthesize locations;

#pragma mark - Init/Lifecycle
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        locations = [[NSMutableArray alloc] init];
        locationManager = [[CLLocationManager alloc] init];
        
        currentLocation = nil;
        
        editButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit"
                                                      style:UIBarButtonItemStylePlain
                                                     target:self
                                                     action:@selector(toggleEditMode)];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void) viewWillAppear:(BOOL)animated
{
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.delegate = self;
    [locationManager startUpdatingLocation];
    
    [locationTableView reloadData];
    
    [self updateEditButtonVisiblity];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [locationManager stopUpdatingLocation];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Class methods

- (void)toggleEditMode
{
    BOOL enterEditMode = YES;
    
    [editButton setTitle:@"Stop Editting"];
    
    if([locationTableView isEditing])
    {
        enterEditMode = NO;
        [editButton setTitle:@"Edit"];
    }
    
    [locationTableView setEditing:enterEditMode animated:YES];
}

- (void) updateEditButtonVisiblity
{
    if([locations count] > 0)
    {
        [[self navigationItem] setRightBarButtonItem:editButton animated:YES];
    }
    else
    {
        [[self navigationItem] setRightBarButtonItem:nil animated:YES];
    }
}

#pragma mark - IBActions

- (IBAction)FindButtonPressed:(id)sender
{
    MapLocationViewController * mlvc = [[MapLocationViewController alloc] init];
    
    [mlvc setLocations:locations];
    
    [self.navigationController pushViewController:mlvc animated:YES];
}

- (IBAction)markLocationButtonPressed:(id)sender
{
    if(currentLocation != nil)
    {
        CLGeocoder * geocoder = [[CLGeocoder alloc] init];
        [geocoder reverseGeocodeLocation:currentLocation
                       completionHandler:^(NSArray * placemarks, NSError * error) {
                           if(error != nil)
                           {
                               
                               DebugLog(@"error domain: %@ code: %d", error.domain, error.code);
                               
                               switch(error.code)
                               {
                                   case kCLErrorNetwork:
                                       DebugLog(@"no network access, or geocode flooding detected");
                                       break;
                                   default:
                                       break;
                               }
                           }
                           else
                           {
                               // TODO: handle multiple results somehow?
                               MapMarker * newMarker = [[MapMarker alloc] initWithPlacemark:[placemarks lastObject]];
                               
                               [locations addObject:newMarker];
                               
                               // tell the table view it needs to update its data.
                               [locationTableView reloadData];
                               
                               [self updateEditButtonVisiblity];

                           }
                       }];
        
    }
    else
    {
        NSString * errorTitle = @"Unable to find location";
        NSString * errorMessage = @"Unable to find your current location.  Please enable location services in the privacy settings and try again";
        
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:errorTitle
                                                         message:errorMessage
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
        [alert show];
        
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    return [locations count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    UITableViewCell * cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LocationCell"];
    CLLocation * locationAtIndex = (CLLocation *)[locations objectAtIndex:indexPath.row];
    
    cell.textLabel.text = locationAtIndex.description;
    
    return cell;
}

- (void)
tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // remove the data from the array
    [locations removeObjectAtIndex:indexPath.row];
    
    // remove the row from the table
    NSArray * removeIndexes = [[NSArray alloc] initWithObjects:indexPath, nil];
    [tableView deleteRowsAtIndexPaths:removeIndexes withRowAnimation:UITableViewRowAnimationAutomatic];
    
    if([locations count] == 0)
    {
        [self toggleEditMode];
        [self updateEditButtonVisiblity];
    }
    
    //TODO: work out which routes need re-calculating.
    // for now, just recalculate all of them.
    for(int i = 0; i < [locations count]; ++i)
    {
        MapMarker * marker = [locations objectAtIndex:i];
        [marker setRouteCalcRequired:YES];
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)source toIndexPath:(NSIndexPath *)dest;
{
    MapMarker * sourceItem = [locations objectAtIndex:source.row];
    
    [locations removeObject:sourceItem];
    [locations insertObject:sourceItem atIndex:dest.row];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    LocationDetailsViewController * ldvc = [[LocationDetailsViewController alloc] init];
    
    [ldvc setCurrentIndex:indexPath.row];
    [ldvc setLocations:locations];
    
    [self.navigationController pushViewController:ldvc animated:YES];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    // just silently store the location so we know where they are when the button is pressed.
    currentLocation = newLocation;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    // TODO: contains hardcoded strings.  should probably put them somewhere better.
    
    BOOL displayMessage = NO;
    NSString * errorTitle = @"";
    NSString * errorMessage = @"";
    
    DebugLog(@"Error domain: %@ code: %d", error.domain, error.code);
    
    switch(error.code)
    {
        case kCLErrorDenied:
            
            displayMessage = YES;
            errorTitle = @"Unable to find location";
            errorMessage = @"Unable to find your current location.  Please enable location services in the privacy settings and try again";
            
            DebugLog(@"Access to location services is denied. need to prompt user");
            break;
        case kCLErrorLocationUnknown:
            DebugLog(@"Could not find location right now. will keep trying. - safe to ignore.");
            break;
        case kCLErrorHeadingFailure:
            DebugLog(@"could not determine heading at this time. will keep trying - safe to ignore.");
            break;
        default:

            displayMessage = YES;
            errorTitle = @"Unknown Error";
            errorMessage = @"Unable to find location due to unknown error. Please try again later.";

            DebugLog(@"An unhandled error occurred while attempting to find user location.");
            DebugLog(@"message: %@", error.debugDescription);
            break;
    }
 
    if( displayMessage )
    {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:errorTitle
                                                     message:errorMessage
                                                    delegate:nil
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil];
        [alert show];
        
    }
}

@end