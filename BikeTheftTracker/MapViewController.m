//
//  MapViewController.m
//  BikeTheftTracker
//
//  Created by Russell Barnes on 1/12/14.
//  Copyright (c) 2014 SeniorDesign2014. All rights reserved.
//

#import "MapViewController.h"


@interface MapViewController ()

// Text above the map ("Loading..." by default)
@property (weak, nonatomic) IBOutlet UILabel *mapUpperCaption;

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
    
    // Add newline to label
    self.mapUpperCaption.text = @"Searching...\r ";
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
                //NSLog(@"First location - X: %f", [[[self.locations objectAtIndex:0] objectForKey:@"X"] floatValue]);
                
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
    
    // Display the time at which this location was received by the server
    NSDateFormatter *dateFromServerFormatter, *dateOfLocationFormatter;
    NSDate *dateOfLocation;
    NSString *locationDate, *locationTime;
    
    // Convert the RFC 3339 date-time string to an NSDate
    dateFromServerFormatter = [[NSDateFormatter alloc] init];
    assert(dateFromServerFormatter != nil);
    
    [dateFromServerFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSSSSS'Z'"];
    [dateFromServerFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    dateOfLocation = [dateFromServerFormatter dateFromString:[[self.locations objectAtIndex:0] objectForKey:@"Date"]];
    NSLog(@"iOS date: %@", dateOfLocation);
    
    // Convert the NSDate to a user-visible date string.
    
    dateOfLocationFormatter = [[NSDateFormatter alloc] init];
    assert(dateOfLocationFormatter != nil);
    
    [dateOfLocationFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateOfLocationFormatter setTimeStyle:NSDateFormatterNoStyle];
    
    locationDate = [dateOfLocationFormatter stringFromDate:dateOfLocation];
    
    [dateOfLocationFormatter setDateStyle:NSDateFormatterNoStyle];
    [dateOfLocationFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    locationTime = [dateOfLocationFormatter stringFromDate:dateOfLocation];
    
    NSLog(@"Formatted date: %@", locationTime);
    
    // Update the Map caption on the main thread to avoid long delay
    dispatch_async(dispatch_get_main_queue(), ^{
        self.mapUpperCaption.text = [NSString stringWithFormat:@"Spotted on %@ at %@", locationDate, locationTime];
    });
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
