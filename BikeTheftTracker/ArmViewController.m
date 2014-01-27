//
//  ArmViewController.m
//  BikeTheftTracker
//
//  Created by Russell Barnes on 1/26/14.
//  Copyright (c) 2014 SeniorDesign2014. All rights reserved.
//

#import "ArmViewController.h"

@interface ArmViewController ()

@property (nonatomic) CBCentralManager *myCentralManager;

// Bluetooth peripheral to connect to (BTT)
@property (nonatomic) CBPeripheral *peripheral;

@end

@implementation ArmViewController

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
    // Search for the Bluetooth device
    self.myCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
    NSLog(@"BT view loaded");
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if ([central state] == CBCentralManagerStatePoweredOn) {
        NSLog(@"Bluetooth is powered on!");
        [self bluetoothPoweredOn:central];
    }
}

// Called from centralManagerDidUpdateState
- (void)bluetoothPoweredOn:(CBCentralManager *)central
{
    [central scanForPeripheralsWithServices:nil options:nil];
}

// Called each time a device is discovered
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"Device discovered");
    NSLog(@"Peripheral name: %@", peripheral.name);
    NSLog(@"Device: %@", advertisementData);
    NSLog(@"RSI: %@", RSSI);
    
    // If this is the device that we're looking for, stop the scan
    [central stopScan];
    NSLog(@"Scanning stopped");
    self.peripheral = peripheral;
    
    // Connect to device
    [central connectPeripheral:self.peripheral options:nil];
}

// Connected to device
- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral {
    peripheral.delegate = self;
    NSLog(@"Peripheral connected");
    // TODO: Replace nil with service that we want
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
        NSLog(@"Discovered characteristic: %@", characteristic);
        
        // Read the characteristic's value
        [peripheral readValueForCharacteristic:characteristic];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
    
    NSData *data = characteristic.value;
    // parse the data as needed
    NSLog(@"Data from char: %@", data);
    
    NSMutableString *stringFromData = [NSMutableString stringWithString:@""];
    
    for (int i = 0; i < characteristic.value.length; i++) {
        unsigned char _byte;
        [characteristic.value getBytes:&_byte range:NSMakeRange(i, 1)];
        
        if (_byte >= 32 && _byte < 127) {
            [stringFromData appendFormat:@"%c", _byte];
        }
    }
    NSLog(@"The String is %@", stringFromData);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
