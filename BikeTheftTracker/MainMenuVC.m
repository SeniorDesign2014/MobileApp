//
//  MainMenuVC.m
//  BikeTheftTracker
//
//  Created by Russell Barnes on 1/12/14.
//  Copyright (c) 2014 SeniorDesign2014. All rights reserved.
//

#import "MainMenuVC.h"
#import "MapViewController.h"

@interface MainMenuVC ()

@property (nonatomic) NSString *appid;

@end

@implementation MainMenuVC

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // If appid is saved in program memory, retrieve it
    self.appid = @"00000030";
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"switchToMap"]) {
        
        // Refer to instance of MapViewController
        MapViewController *newView = segue.destinationViewController;
        
        // Pass the map view the array of events
        newView.appid = self.appid;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
