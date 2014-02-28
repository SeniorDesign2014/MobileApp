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
    /*if (self.myCentralManager.state != CBCentralManagerStatePoweredOn) {
        NSLog(@"Bluetooth is not turned on");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Bluetooth Connection"
                                                        message:@"You must turn Bluetooth on in device settings in order to communicate with the Bike Theft Tracker."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }*/
    
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
    if ([peripheral.name isEqualToString:@"BikeTheftTracker"]) {
        
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
        //NSLog(@"Discovered characteristic; data: %@", characteristic.UUID.data);
        
        NSString *characteristicName = [NSString stringWithFormat:@"%@", characteristic.UUID.data];
        
        NSLog(@"Discovered characteristic: %@", characteristicName);
        
        // Read the characteristic's value
        [peripheral readValueForCharacteristic:characteristic];
        
        // *** DEBUG - write data to Bluetooth characteristic
        
        if ([characteristicName isEqualToString:@"<5fc569a0 74a94fa4 b8b78354 c86e45a4>"]) {
            
            NSString *stringToWrite = @"hijklmnop";
            NSData *dataToWrite = [stringToWrite dataUsingEncoding:NSUTF8StringEncoding];
            
            // Write to Bluetooth device - callback is peripheral:didwritevalueforcharacteristics:error
            [peripheral writeValue:dataToWrite forCharacteristic:characteristic
                              type:CBCharacteristicWriteWithResponse];
        }
    }
}

// Called when the app reads a characteristic or the peripheral notifies the app of a change
- (void)peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    
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
    
    NSLog(@"The raw value is %@",characteristic.value);
    
    NSString *value = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    
    if (value) {
        
        NSString *stringFromData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        NSLog(@"The String is %@", stringFromData);
        
        // *** TODO during integration - change status to reflect armed/unarmed state ***
        [self.loadingAnimation stopAnimating];
        self.statusLabel.text = @"Unarmed";
        self.armSwitch.enabled = TRUE;
        
        
        // *** TODO during integration - Deactivate stolen state? ***
    }
}

// Callback for Bluetooth write
- (void)peripheral:(CBPeripheral *)peripheral
didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    
    if (error) {
        NSLog(@"Error writing to Bluetooth device: %@",
              [error localizedDescription]);
    }
    else {
        NSLog(@"Write to Bluetooth device was successful.");
    }
}

// When the switch is flipped
- (IBAction)armSwitchFlipped:(id)sender
{
    if (self.armSwitch.on) {
        // Switch was just flipped on
    }
    else {
        // Switch was just flipped off
    }
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

/*
-(NSString *)GetServiceName:(CBUUID *)UUID{
    
    UInt16 _uuid = [self CBUUIDToInt:UUID];
    NSString *characteristicName = [NSString stringWithFormat:@"%@", characteristic.UUID.data];

    
    switch(_uuid)
    {
        case 0x2A2D: return @"Latitude"; break;
        case 0x2A2E: return @"Longitude"; break;
        case 0x2A2F: return @"Position 2D"; break;
        case 0x2A30: return @"Position 3D"; break;
        default:
            return @"Unknkown Characteristic";
            break;
    }
}*/

@end
