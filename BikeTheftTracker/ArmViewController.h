//
//  ArmViewController.h
//  BikeTheftTracker
//
//  Created by Russell Barnes on 1/26/14.
//  Copyright (c) 2014 SeniorDesign2014. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ArmViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate, UITextFieldDelegate>

@end
