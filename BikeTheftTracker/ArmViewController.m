//
//  ArmViewController.m
//  BikeTheftTracker
//
//  Created by Russell Barnes on 1/26/14.
//  Copyright (c) 2014 SeniorDesign2014. All rights reserved.
//
//  Called by the "Arm my bike" button.
//  Searches for a matching Bluetooth 4.0 peripheral nearby.
//  Reads current status and writes to it.

/* 
 DATA EXCHANGE FORMAT
 
 Byte0 	-	Secret Handshake
     App ID: (ascii “0” or hex 0x30)
 
 Byte1	- 	Arm/Disarm
     Disarm: (ascii “0” or hex 0x30)
     Arm: (ascii “1” or hex 0x31)
 
 Byte2	-	Sound On/Off
     Off: (ascii “0” or hex 0x30)
     On: (ascii “1” or hex 0x31)
 
 
 Byte3 	-	Sound Selection
     Sound0: (ascii “0” or hex 0x30)
     Sound1: (ascii “1” or hex 0x31)
     Sound2: (ascii “2” or hex 0x32)
     Sound3: (ascii “3” or hex 0x33)
     Sound4: (ascii “4” or hex 0x34)
 
 Byte4 	-	Sound Time Delay
     Delay 0m: (ascii “0” or hex 0x30)
     Delay 1m: (ascii “1” or hex 0x31)
     Delay 3m: (ascii “3” or hex 0x33)
 */

#import "ArmViewController.h"

@interface ArmViewController ()

@property (nonatomic) CBCentralManager *myCentralManager;

// Bluetooth peripheral to connect to (BTT)
@property (nonatomic) CBPeripheral *peripheral;

// Characteristic to read from the Bluetooth module (tx)
@property (nonatomic, strong) CBCharacteristic *readcharacteristic;

// Characteristic to write to the Bluetooth module (rx)
@property (nonatomic, strong) CBCharacteristic *writecharacteristic;

// Value from the BTT tx characteristic
@property (nonatomic, strong) NSString *bttData;

// Value from the BTT tx characteristic
@property (nonatomic, strong) NSMutableString *bttDataToWrite;


// The spinning loading indicator
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingAnimation;

// The text displaying if BTT is armed/unarmed/searching
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

// Switch to arm/disarm once connected
@property (weak, nonatomic) IBOutlet UISwitch *armSwitch;

@end




@implementation ArmViewController

// Update UI to reflect new data from Bluetooth module
- (void)bttConnected
{
    [self.loadingAnimation stopAnimating];
    self.statusLabel.text = @"Unarmed";
    self.armSwitch.enabled = TRUE;
    
    unichar armed[1];
    [self.bttData getCharacters:armed range:NSMakeRange(1, 1)];
    if (armed[0] == '0')
        self.armSwitch.on = FALSE;
    else if (armed[0] == '1')
        self.armSwitch.on = TRUE;
    
}

// When the switch is flipped
- (IBAction)armSwitchFlipped:(id)sender
{
    if (self.armSwitch.on) {
        // Switch was just flipped on
        
        [self.bttDataToWrite setString:self.bttData];
        [self.bttDataToWrite replaceCharactersInRange:NSMakeRange(1, 1) withString:@"1"];
        [self bttUpdate];
    }
    else {
        // Switch was just flipped off
        
        [self.bttDataToWrite setString:self.bttData];
        [self.bttDataToWrite replaceCharactersInRange:NSMakeRange(1, 1) withString:@"0"];
        [self bttUpdate];
    }
}

// Write bttDataToWrite to the Bluetooth module
- (void)bttUpdate
{
    // Ensure that writecharacteristic has been discovered
    if (!self.writecharacteristic) {
        NSLog(@"ERROR: Write characteristic has not been discovered");
        return;
    }
    NSString *stringToWrite = self.bttDataToWrite;
    NSData *dataToWrite = [stringToWrite dataUsingEncoding:NSUTF8StringEncoding];
    
    // Write to Bluetooth device - callback is peripheral:didwritevalueforcharacteristics:error
    [self.peripheral writeValue:dataToWrite forCharacteristic:self.writecharacteristic
                      type:CBCharacteristicWriteWithResponse];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Init properties
    self.bttDataToWrite = [[NSMutableString alloc] init];
    
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
  didConnectPeripheral:(CBPeripheral *)peripheral
{
    
    peripheral.delegate = self;
    // *** TODO during integration - Replace nil with service that we want ***
    [peripheral discoverServices:nil];
}

// Service(s) discovered
- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverServices:(NSError *)error
{
    
    for (CBService *service in peripheral.services) {
        NSLog(@"Discovered service: %@", service);
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

// Characteristic(s) discovered
- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service
            error:(NSError *)error
{
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        //NSLog(@"Discovered characteristic; data: %@", characteristic.UUID.data);
        
        NSString *characteristicName = [NSString stringWithFormat:@"%@", characteristic.UUID.data];
        
        NSLog(@"Discovered characteristic: %@", characteristicName);
        
        if ([characteristicName isEqualToString:@"<21819ab0 c9374188 b0dbb962 1e1696cd>"]) {    // READ characteristic
            
            // Save the characteristic for later use
            self.readcharacteristic = characteristic;
            
            // Read the tx characteristic's values
            [peripheral readValueForCharacteristic:characteristic];
            
            // Subscribe to notify changes for this characteristic
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
        else if ([characteristicName isEqualToString:@"<5fc569a0 74a94fa4 b8b78354 c86e45a4>"]) {   // WRITE characteristic
            
            // Save the characteristic for later use
            self.writecharacteristic = characteristic;
        }
    }
}

// Called when the app reads a characteristic or the peripheral notifies the app of a change
- (void)peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    // Ensure that this is the BTT's tx characteristic
    NSString *characteristicName = [NSString stringWithFormat:@"%@", characteristic.UUID.data];
    if ([characteristicName isEqualToString:@"<21819ab0 c9374188 b0dbb962 1e1696cd>"]) {    // READ characteristic
        
        
        NSLog(@"The raw value is %@",characteristic.value);
        
        NSData *data = characteristic.value;
        
        NSString *value = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        
        if (value) {
            
            NSString *stringFromData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            
            NSLog(@"The String is %@", stringFromData);
            
            // Save data
            self.bttData = stringFromData;
            
            // Parse data and display it
            [self bttConnected];
        }
    }
    
    /*
    // parse the data as needed
    //NSLog(@"Data from char: %@", data);
    
    NSMutableString *stringFromData = [NSMutableString stringWithString:@""];
    
    for (int i = 0; i < characteristic.value.length; i++) {
        unsigned char _byte;
        [characteristic.value getBytes:&_byte range:NSMakeRange(i, 1)];
        
        if (_byte >= 32 && _byte < 127) {
            [stringFromData appendFormat:@"%c", _byte];
        }
    }*/
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
    
    // TODO: indicate successful write in UI if this is the rxchar
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

/*-(NSString *)GetServiceName:(CBUUID *)UUID{
    
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
