//
//  GAEData.h
//  BikeTheftTracker
//
//  Created by Russell Barnes on 2/7/14.
//  Copyright (c) 2014 SeniorDesign2014. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GAEData : NSObject

@property (nonatomic, strong) NSString *GetLocationURL;

@property (nonatomic, strong) NSString *SetPushTokenURL;

@property (nonatomic, strong) NSString *UpdateClientURL;

@end
