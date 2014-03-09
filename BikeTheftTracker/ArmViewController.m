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
 
 Byte0 	-	Audio alarm manual test
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

// Switch to arm/disarm the BTT once connected
@property (weak, nonatomic) IBOutlet UISwitch *armSwitch;

// "Settings" label
@property (weak, nonatomic) IBOutlet UILabel *settingsLabel;

// "Sound" label
@property (weak, nonatomic) IBOutlet UILabel *soundLabel;

// "Alarm Type" label
@property (weak, nonatomic) IBOutlet UILabel *alarmTypeLabel;

// Alarm "Test" label
@property (weak, nonatomic) IBOutlet UITextField *testButton;

// "Alarm Delay" label
@property (weak, nonatomic) IBOutlet UILabel *alarmDelayLabel;

// Turn audio alarm on/off on the BTT
@property (weak, nonatomic) IBOutlet UISwitch *soundSwitch;

@property (weak, nonatomic) IBOutlet UISegmentedControl *alarmSegmentControl;

// Slider to choose alarm delay
@property (weak, nonatomic) IBOutlet UISlider *alarmDelaySlider;

// String values selected by slider
@property (nonatomic, strong) NSArray *alarmDelayValues;


@end




@implementation ArmViewController

#pragma mark BTT Control Functions

// Update UI to reflect new data from Bluetooth module
- (void)bttConnected
{
    [self.loadingAnimation stopAnimating];
    
    // Set armed status
    unichar armed[1];
    [self.bttData getCharacters:armed range:NSMakeRange(1, 1)];
    if (armed[0] == '0') {
        self.armSwitch.on = false;
        self.statusLabel.text = @"Unarmed";
    }
    else if (armed[0] == '1') {
        self.armSwitch.on = true;
        self.statusLabel.text = @"Armed";
    }
    else {
        // This case may occur when app disconnects and reconnects
        self.armSwitch.on = false;
        self.statusLabel.text = @"Connected";
    }
    // TODO: add loading indicator for changing a value
    // text doesn't change until receive even though switch is flipped
    
    // Set audio status
    unichar audio[1];
    [self.bttData getCharacters:audio range:NSMakeRange(2, 1)];
    if (audio[0] == '0') {
        self.soundSwitch.on = FALSE;
    }
    else if (audio[0] == '1') {
        self.soundSwitch.on = TRUE;
    }
    
    // Set sound selection
    unichar selection[1];
    [self.bttData getCharacters:selection range:NSMakeRange(3, 1)];
    [self.alarmSegmentControl setSelectedSegmentIndex:[[NSNumber numberWithChar:selection[0]] integerValue] - 48];
    
    // Set alarm delay
    unichar delay[1];
    [self.bttData getCharacters:delay range:NSMakeRange(4, 1)];
    NSUInteger sliderIndex = (NSUInteger)([[NSNumber numberWithChar:delay[0]] unsignedIntegerValue] - 48);   // Round the number.
    [self.alarmDelaySlider setValue:sliderIndex animated:true];
    
    
    // Enable UI elements
    self.armSwitch.enabled = true;
    self.settingsLabel.enabled = true;
    self.soundLabel.enabled = true;
    self.alarmTypeLabel.enabled = true;
    self.alarmDelayLabel.enabled = true;
    self.soundSwitch.enabled = true;
    self.soundSwitch.enabled = true;
    self.alarmSegmentControl.enabled = true;
    self.testButton.enabled = true;
    self.alarmDelaySlider.enabled = true;
}

// When the armed/disarmed/searching switch is flipped
- (IBAction)armSwitchFlipped:(id)sender
{
    if (((UISwitch *)sender).on) {
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

// Sound switch changed
- (IBAction)soundSwitchFlipped:(id)sender
{
    if (((UISwitch *)sender).on) {
        // Switch was just flipped on
        
        [self.bttDataToWrite setString:self.bttData];
        [self.bttDataToWrite replaceCharactersInRange:NSMakeRange(2, 1) withString:@"1"];
        [self bttUpdate];
    }
    else {
        // Switch was just flipped off
        
        [self.bttDataToWrite setString:self.bttData];
        [self.bttDataToWrite replaceCharactersInRange:NSMakeRange(2, 1) withString:@"0"];
        [self bttUpdate];
    }
}

// Alarm Type changed
- (IBAction)alarmSegmentControlChanged:(id)sender {
    [self.bttDataToWrite setString:self.bttData];
    [self.bttDataToWrite replaceCharactersInRange:NSMakeRange(3, 1) withString:[NSString stringWithFormat:@"%ld", (long)((UISegmentedControl *)sender).selectedSegmentIndex]];
    [self bttUpdate];
}


// Value of slider changed
- (void)sliderChanged:(UISlider*)sender
{
    NSUInteger index = (NSUInteger)(self.alarmDelaySlider.value + 0.5); // Round the number.
    [self.alarmDelaySlider setValue:index animated:NO];
    
    // Update value and write to module (0, 1 or 3 minutes)
    [self.bttDataToWrite setString:self.bttData];
    [self.bttDataToWrite replaceCharactersInRange:NSMakeRange(4, 1) withString:[self.alarmDelayValues objectAtIndex:index]];
    [self bttUpdate];
}

// Alarm "Test" button pressed
- (BOOL) textFieldShouldBeginEditing:(UITextField *)textField
{
    /*
        This delegate method always returns false in order to
        disable text editing - we're using the textfield as a 
        button.
     */
    
    // Only accept presses if buttons are enabled
    if (!textField.enabled)
        return false;
    
    unichar test_flag[1];
    [self.bttData getCharacters:test_flag range:NSMakeRange(0, 1)];
    
    if (test_flag[0] == '0') {
     // Turn on the audio alarm
     [self.bttDataToWrite setString:self.bttData];
     [self.bttDataToWrite replaceCharactersInRange:NSMakeRange(0, 1) withString:@"1"];
     [self bttUpdate];
     }
     else if (test_flag[0] == '1') {
     // Turn off the audio alarm
     // We have coded the BTT firmware to shut off the test alarm after 5 seconds,
     // so this transmission is just for safety.
     
     [self.bttDataToWrite setString:self.bttData];
     [self.bttDataToWrite replaceCharactersInRange:NSMakeRange(0, 1) withString:@"0"];
     [self bttUpdate];
     }
    
    return false;
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
    [self.testButton setDelegate:self];
    
    // Alarm delay slider values
    self.alarmDelayValues = [[NSArray alloc] initWithObjects:@"0", @"1", @"3", nil];
    
    self.alarmDelaySlider.continuous = false; // Slider should not snap-to when dragging
    [self.alarmDelaySlider addTarget:self
               action:@selector(sliderChanged:)
     forControlEvents:UIControlEventValueChanged];
    
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
}

#pragma mark Bluetooth Delegate Functions

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
            NSLog(@"self.bttData:%@", self.bttData);//DEBUG
            
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
        NSLog(@"self.bttDataToWrite:%@", self.bttDataToWrite);//DEBUG
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error
{
    NSLog(@"Disconnected from peripheral");
    
    // Disable UI elements
    self.armSwitch.enabled = false;
    self.settingsLabel.enabled = false;
    self.soundLabel.enabled = false;
    self.alarmTypeLabel.enabled = false;
    self.alarmDelayLabel.enabled = false;
    self.soundSwitch.enabled = false;
    self.soundSwitch.enabled = false;
    self.alarmSegmentControl.enabled = false;
    self.testButton.enabled = false;
    self.alarmDelaySlider.enabled = false;
    
    self.statusLabel.text = @"Disconnected";
    
    if ( self.peripheral )
    {
        [self.peripheral setDelegate:nil];
        self.peripheral = nil;
    }
    // Attempt to re-scan for the peripheral
    [self bluetoothPoweredOn:self.myCentralManager];
}

#pragma mark System Functions

// Terminate Bluetooth connection if user presses Back button
- (void)viewWillDisappear:(BOOL)animated
{
    if (self.peripheral) {
        [self.myCentralManager cancelPeripheralConnection:self.peripheral];
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
