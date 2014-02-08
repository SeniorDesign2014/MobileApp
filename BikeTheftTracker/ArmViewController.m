//
//  ArmViewController.m
//  BikeTheftTracker
//
//  Created by Russell Barnes on 1/26/14.
//  Copyright (c) 2014 SeniorDesign2014. All rights reserved.
//
//  Called by the "Arm my bike" button.
//  Searches for a matching Bluetooth 4.0 peripheral nearby.
//  Reads current status automatically and writes to it.

#import "ArmViewController.h"

@interface ArmViewController ()

@property (nonatomic) CBCentralManager *myCentralManager;

// Bluetooth peripheral to connect to (BTT)
@property (nonatomic) CBPeripheral *peripheral;

// The spinning loading indicator
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingAnimation;

// The text displaying if BTT is armed/unarmed/searching
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

// Switch to arm/disarm once connected
@property (weak, nonatomic) IBOutlet UISwitch *armSwitch;

@end




@implementation ArmViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Create a new Bluetooth central
    self.myCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
    
    // If Bluetooth is not turned on, ask the iPhone user to turn it on
    if (self.myCentralManager.state != CBCentralManagerStatePoweredOn) {
        NSLog(@"Bluetooth is not turned on");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Bluetooth Connection"
                                                        message:@"You must turn Bluetooth on in device settings in order to communicate with the Bike Theft Tracker."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        //[alert release];
    }
    NSLog(@"BT view loaded");
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if ([central state] == CBCentralManagerStatePoweredOn) {
        [self bluetoothPoweredOn:central];
    }
}

// Called from centralManagerDidUpdateState
- (void)bluetoothPoweredOn:(CBCentralManager *)central
{
    // Search for nearby Bluetooth peripherals
    NSLog(@"Bluetooth is powered on!  Searching for peripherals...");
    [central scanForPeripheralsWithServices:nil options:nil];
}

// Called each time a device is discovered in bluetoothPoweredOn
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"Device Discovered");
    NSLog(@"Peripheral Name: %@", peripheral.name);
    //NSLog(@"Device: %@", advertisementData);
    //NSLog(@"RSI: %@", RSSI);
    
    // If this is the device that we're looking for, stop the scan
    // *** TODO during integration - look for our peripheral's name ***
    if (TRUE) {
        
        [central stopScan];
        NSLog(@"Matching device found.");
        
        self.peripheral = peripheral;
        
        // Connect to this peripheral
        [central connectPeripheral:self.peripheral options:nil];
    }
}

// Connected to device
- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral {
    
    peripheral.delegate = self;
    NSLog(@"Peripheral connected");
    // *** TODO during integration - Replace nil with service that we want ***
    [peripheral discoverServices:nil];
}

// Service(s) discovered
- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverServices:(NSError *)error {
    
    for (CBService *service in peripheral.services) {
        NSLog(@"Discovered service: %@", service);
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service
            error:(NSError *)error {
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSLog(@"Discovered characteristic: %@", characteristic.UUID.data);
        
        NSMutableString *stringFromData = [[NSMutableString alloc] initWithData:characteristic.UUID.data encoding:NSUTF8StringEncoding];
        
        NSLog(@"The characteristic name string is %@", stringFromData);
        
        // Read the characteristic's value
        [peripheral readValueForCharacteristic:characteristic];
    }
}

// Called when the app reads a characteristic or the peripheral notifies the app of a change
- (void)peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
    
    NSData *data = characteristic.value;
    // parse the data as needed
    //NSLog(@"Data from char: %@", data);
    
    /*NSMutableString *stringFromData = [NSMutableString stringWithString:@""];
    
    for (int i = 0; i < characteristic.value.length; i++) {
        unsigned char _byte;
        [characteristic.value getBytes:&_byte range:NSMakeRange(i, 1)];
        
        if (_byte >= 32 && _byte < 127) {
            [stringFromData appendFormat:@"%c", _byte];
        }
    }*/
    
    NSString *value = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    
    NSLog(@"Value %@",value);
    NSString *stringFromData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSLog(@"The String is %@", stringFromData);
    
    // *** TODO during integration - change status to reflect armed/unarmed state ***
    [self.loadingAnimation stopAnimating];
    self.statusLabel.text = @"Unarmed";
    self.armSwitch.enabled = TRUE;
    
    
    // *** TODO during integration - Deactivate stolen state? ***
    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
