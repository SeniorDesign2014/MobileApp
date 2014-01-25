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
    
    // Define constants
    NSString *const GetLocationURL = @"http://bikethefttracker.appspot.com/getlocation";

    NSLog(@"appid: %@", self.appid);
    
    // Request bike location data
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:[NSURL URLWithString:GetLocationURL]
        completionHandler:^(NSData *data,
                            NSURLResponse *response,
                            NSError *error) {
            // handle response
            NSLog(@"Response: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        }
    ] resume];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
