//
//  GAEData.m
//  BikeTheftTracker
//
//  Created by Russell Barnes on 2/7/14.
//  Copyright (c) 2014 SeniorDesign2014. All rights reserved.
//

#import "GAEData.h"

@implementation GAEData

- (id) init {
    self = [super init];
    if (self) {
        self.GetLocationURL = @"http://bikethefttracker.appspot.com/getlocation";
    }
    return(self);
}

@end

