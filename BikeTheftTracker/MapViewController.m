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

// Buttons for switching between locations/points
@property (weak, nonatomic) IBOutlet UIStepper *stepper;

// Current location/point
@property (nonatomic, assign) NSInteger currentIndex;

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
    //self.mapUpperCaption.text = @"Searching...\r ";
}

- (void)viewWillAppear:(BOOL)animated
{
    // Define constants
    
    // Object containing our Google App Engine URLs (closed-source for privacy)
    GAEData *oregonStateAccount = [[GAEData alloc] init];
    NSString *const GetLocationURL = [NSString stringWithFormat:@"%@?clientid=00000001", oregonStateAccount.GetLocationURL];
    
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
                
                // Set stepper bound to number of locations available
                self.stepper.maximumValue = [self.locations count] - 1;
                self.stepper.value = self.stepper.maximumValue;
                
                // If there are no locations, return.
                if ([self.locations count] < 1)
                    return;
                
                // Display all known points on the map
                [self displayLocations];
                
                [self didReceiveLocationData];
            }
      ] resume];
}

- (void)displayLocations
{
    /*
        Display all known locations/points on the map as pins
     */
    int index;
    for (index = [self.locations count] - 1; index >= 0; index--) {
        CLLocationCoordinate2D eventLocation;
        eventLocation.latitude = [[[self.locations objectAtIndex:index] objectForKey:@"X"] floatValue];
        eventLocation.longitude = [[[self.locations objectAtIndex:index] objectForKey:@"Y"] floatValue];
        
        /*
         Display a point where the cooridnates are
         */
        MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
        [point setCoordinate:(CLLocationCoordinate2D)CLLocationCoordinate2DMake(eventLocation.latitude, eventLocation.longitude)];
        
        // Add title for point (the coordinates)
        NSString *title = [NSString stringWithFormat:@"%@, %@", [[self.locations objectAtIndex:index] objectForKey:@"X"], [[self.locations objectAtIndex:index] objectForKey:@"Y"]];
        [point setTitle:title];
        //[self.point setSubtitle:[[locations objectAtIndex:index] objectForKey:@"Clientid"]];
        
        // Add the annotation point
        [self.mapView addAnnotation:point];
    }
}

- (void)showLocation:(int)index
{
    CLLocationCoordinate2D eventLocation;
    eventLocation.latitude = [[[self.locations objectAtIndex:index] objectForKey:@"X"] floatValue];
    eventLocation.longitude = [[[self.locations objectAtIndex:index] objectForKey:@"Y"] floatValue];
    
    // The window to display around the event
    MKCoordinateRegion windowRegion = MKCoordinateRegionMakeWithDistance(eventLocation, 800, 800);
    // Zoom to the location of the Last.FM event found in ViewController
    [_mapView setRegion:windowRegion animated:YES];
    
    /*
        Display the time at which this location was received by the server
     */
    NSDateFormatter *dateFromServerFormatter, *dateOfLocationFormatter;
    NSDate *dateOfLocation;
    NSString *locationDate, *locationTime;
    
    // Convert the RFC 3339 date-time string to an NSDate
    dateFromServerFormatter = [[NSDateFormatter alloc] init];
    assert(dateFromServerFormatter != nil);
    
    [dateFromServerFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSSSSS'Z'"];
    [dateFromServerFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    dateOfLocation = [dateFromServerFormatter dateFromString:[[self.locations objectAtIndex:index] objectForKey:@"Date"]];
    //NSLog(@"iOS date: %@", dateOfLocation);
    
    // Convert the NSDate to a user-visible date string.
    
    dateOfLocationFormatter = [[NSDateFormatter alloc] init];
    assert(dateOfLocationFormatter != nil);
    
    [dateOfLocationFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateOfLocationFormatter setTimeStyle:NSDateFormatterNoStyle];
    
    locationDate = [dateOfLocationFormatter stringFromDate:dateOfLocation];
    
    [dateOfLocationFormatter setDateStyle:NSDateFormatterNoStyle];
    [dateOfLocationFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    locationTime = [dateOfLocationFormatter stringFromDate:dateOfLocation];
    //NSLog(@"Formatted date: %@", locationTime);
    
    // Update the Map caption on the main thread to avoid long delay
    dispatch_async(dispatch_get_main_queue(), ^{
        self.mapUpperCaption.text = [NSString stringWithFormat:@"Spotted on %@ at %@", locationDate, locationTime];
    });
}


- (IBAction)stepperValueChanged:(id)sender {
    // If there are no locations, return.
    if ([self.locations count] < 1)
        return;
    UIStepper *stepper = (UIStepper *) sender;
    self.currentIndex = ([self.locations count] - 1) - stepper.value;
    [self showLocation:self.currentIndex];
}




- (void)didReceiveLocationData
{
    self.currentIndex = 0;
    [self showLocation:self.currentIndex];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
