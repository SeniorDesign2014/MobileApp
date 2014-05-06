//
//  RegistrationViewController.m
//  BikeTheftTracker
//
//  Created by Russell Barnes on 3/9/14.
//  Copyright (c) 2014 SeniorDesign2014. All rights reserved.
//

#import "RegistrationViewController.h"
#include "GAEData.h"

@interface RegistrationViewController ()

// Loading indicator in upper-right
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

// Email address text field
@property (weak, nonatomic) IBOutlet UITextField *emailField;

// Phone number text field
@property (weak, nonatomic) IBOutlet UITextField *numberField;

// Email switch
@property (weak, nonatomic) IBOutlet UISwitch *emailSwitch;

// SMS switch
@property (weak, nonatomic) IBOutlet UISwitch *smsSwitch;

// Push notifications switch
@property (weak, nonatomic) IBOutlet UISwitch *pushSwitch;

@end


@implementation RegistrationViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Loading indicator
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.loadingIndicator startAnimating];
    }];
    
    // Init properties
    [self.emailField setDelegate:self];
    [self.numberField setDelegate:self];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];  // For hiding the keyboard
    
    [self.view addGestureRecognizer:tap];
    
    // --- Load preference data from server ---
    
    /* 
     Example response:
 [{"Email":false,"Sms":true,"Push":false,"Address":"abcd@efgh.com","Phonenumber":"1971#######","Clientid":"########","Date":"2014-05-06T20:45:01.502244Z"}]
     */
    
    // Object containing our Google App Engine URLs (closed-source for privacy)
    GAEData *oregonStateAccount = [[GAEData alloc] init];
    NSString *const GetPreferencesURL = [NSString stringWithFormat:@"%@?clientid=00000001", oregonStateAccount.GetPreferencesURL];
    
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:[NSURL URLWithString:GetPreferencesURL]
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error) {
                // Handle response
                if (error) {
                    NSLog(@"Problem loading preferences from server.");
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [self.loadingIndicator stopAnimating];
                    }];
                    return;
                }
                NSError *jsonError;
                NSArray *preferencesFromServer = [NSJSONSerialization JSONObjectWithData:data
                                                                               options:NSJSONReadingAllowFragments
                                                                                 error:&jsonError];
                if (jsonError) {
                    NSLog(@"Problem parsing preferences from server.");
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [self.loadingIndicator stopAnimating];
                    }];
                    return;
                }
                
                NSArray *prefs = [[NSArray alloc] initWithArray:preferencesFromServer];
                
                // Populate fields with server data
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    self.emailField.text = [[prefs objectAtIndex:0] objectForKey:@"Address"];
                    // Substring chops off the first character (country code)
                    self.numberField.text = [[[prefs objectAtIndex:0] objectForKey:@"Phonenumber"] substringFromIndex:1];
                    self.emailSwitch.on = [[[prefs objectAtIndex:0] objectForKey:@"Email"] boolValue];
                    self.smsSwitch.on = [[[prefs objectAtIndex:0] objectForKey:@"Sms"] boolValue];
                    self.pushSwitch.on = [[[prefs objectAtIndex:0] objectForKey:@"Push"] boolValue];
                    
                    [self.loadingIndicator stopAnimating];
                }];
            }
      ] resume];
}

// Done / Next key pressed in text field
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // Hide keyboard
    [textField resignFirstResponder];
    
    // Move to phone number field if applicable
    if (textField == self.emailField)
        [self.numberField becomeFirstResponder];
    
    if (textField == self.numberField && [self.numberField.text length] != 10 && [self.numberField.text length] != 0) {
        self.numberField.text = @"";
        self.numberField.placeholder = @"Format: 5031234444";
        return FALSE;
    }
    
    // Update client preferences on server
    [self updateServer];
    
    return TRUE;
}

// Email, SMS or push notification switch flipped
- (IBAction)switchFlipped:(id)sender {
    // Send updated preferences to the server
    [self updateServer];
}


// Update client preferences on server
- (void)updateServer
{
    /*
        Message format:
        <server>/updateclient?clientid=########[&email=[0/1]&address=abc@123.com][&sms=[0/1]&phonenumber=1503#######][&push=[0/1]]
     */
    
    // Loading indicator
    [self.loadingIndicator startAnimating];
    
    // Get data from forms
    NSString *preferences = [NSString stringWithFormat:@"&email=%@%@%@&sms=%@%@%@&push=%@",
                             self.emailSwitch.on ? @"1" : @"0", [self.emailField.text length] != 0 ? @"&address=" : @"",
                             [self.emailField.text length] != 0 ? self.emailField.text : @"",
                             self.smsSwitch.on ? @"1" : @"0", [self.numberField.text length] != 0 ? @"&phonenumber=" : @"",
                             [self.numberField.text length] != 0 ? self.numberField.text : @"",
                             self.pushSwitch.on ? @"1" : @"0"];
    
    // Receive closed-source server information from file
    GAEData *oregonStateAccount = [[GAEData alloc] init];
    NSString *const serverPrefs = [NSString stringWithFormat:@"%@?clientid=00000001%@", oregonStateAccount.UpdateClientURL, preferences];
    
    
    // Send updated client preferences to server
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:[NSURL URLWithString:serverPrefs]
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error) {
                
                NSLog(@"Request completed.");
                if (error)
                    NSLog(@"Error: %@", error);
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.loadingIndicator stopAnimating];
                }];
            }
      ] resume];
}


#pragma mark System Functions

// Hide keyboard for outside click
-(void)hideKeyboard {
    // Hide keyboard for either text field, if present
    [self.emailField resignFirstResponder];
    [self.numberField resignFirstResponder];
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
