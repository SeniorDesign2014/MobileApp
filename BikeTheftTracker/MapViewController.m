//
//  MapViewController.m
//  BikeTheftTracker
//
//  Created by Russell Barnes on 1/12/14.
//  Copyright (c) 2014 SeniorDesign2014. All rights reserved.
//

#import "MapViewController.h"


@interface MapViewController ()

@end

@implementation MapViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    // Define constants
    
    // Object containing our Google App Engine URLs (closed-source for privacy)
    GAEData *oregonStateAccount = [[GAEData alloc] init];
    NSString *const GetLocationURL = [NSString stringWithFormat:@"%@", oregonStateAccount.GetLocationURL];
    
    NSLog(@"appid: %@", self.appid);
    
    // Request bike location data
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:[NSURL URLWithString:GetLocationURL]
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error) {
                // handle response
                //NSLog(@"Response: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                NSError *jsonError;
                NSArray *locationsFromServer = [NSJSONSerialization JSONObjectWithData:data
                                                                     options:NSJSONReadingAllowFragments
                                                                       error:&jsonError];
                self.locations = [[NSArray alloc] initWithArray:locationsFromServer];
                
                NSLog(@"JSON data: %@", self.locations);
                NSLog(@"First location - X: %f", [[[self.locations objectAtIndex:0] objectForKey:@"X"] floatValue]);
                
                [self didReceiveLocationData];
            }
      ] resume];
}

- (void)didReceiveLocationData
{
    CLLocationCoordinate2D eventLocation;
    eventLocation.latitude = [[[self.locations objectAtIndex:0] objectForKey:@"X"] floatValue];
    eventLocation.longitude = [[[self.locations objectAtIndex:0] objectForKey:@"Y"] floatValue];
    
    // Display a point where the cooridnates are
    self.point = [[MKPointAnnotation alloc] init];
    [self.point setCoordinate:(CLLocationCoordinate2D)CLLocationCoordinate2DMake(eventLocation.latitude, eventLocation.longitude)];
    
    // Add title
    [self.point setTitle:[[self.locations objectAtIndex:0] objectForKey:@"Date"]];
    //[self.point setSubtitle:[[locations objectAtIndex:0] objectForKey:@"Clientid"]];
    
    // Add the annotation point
    [self.mapView addAnnotation:self.point];
    
    // The window to display around the event
    MKCoordinateRegion windowRegion = MKCoordinateRegionMakeWithDistance(eventLocation, 800, 800);
    // Zoom to the location of the Last.FM event found in ViewController
    [_mapView setRegion:windowRegion animated:YES];
    
    NSLog(@"Confirming location data - X: %f", [[[self.locations objectAtIndex:0] objectForKey:@"X"] floatValue]);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
