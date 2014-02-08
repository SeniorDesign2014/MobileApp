//
//  MapViewController.h
//  BikeTheftTracker
//
//  Created by Russell Barnes on 1/12/14.
//  Copyright (c) 2014 SeniorDesign2014. All rights reserved.
//

FOUNDATION_EXPORT NSString *const *GetLocationURL;

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "GAEData.h" // Data for contacting our app engine server (closed-source for privacy)

@interface MapViewController : UIViewController <MKMapViewDelegate>

// Unique identifier for this user (not to be confused with ID of BTT module)
@property (nonatomic) NSString *appid;

@property (weak, nonatomic) IBOutlet MKMapView *mapView;


// The point to display on the map
@property (nonatomic, strong) MKPointAnnotation *point;

// Coordinates from the server
@property (nonatomic) NSArray *locations;

@end
