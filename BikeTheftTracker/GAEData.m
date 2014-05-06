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
        self.SetPushTokenURL = @"http://bikethefttracker.appspot.com/setpushtoken";
        self.UpdateClientURL = @"http://bikethefttracker.appspot.com/updateclient";
        self.GetPreferencesURL = @"http://bikethefttracker.appspot.com/getpreferences";
    }
    return(self);
}

@end

