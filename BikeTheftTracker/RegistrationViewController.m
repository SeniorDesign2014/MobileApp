//
//  RegistrationViewController.m
//  BikeTheftTracker
//
//  Created by Russell Barnes on 3/9/14.
//  Copyright (c) 2014 SeniorDesign2014. All rights reserved.
//

#import "RegistrationViewController.h"

@interface RegistrationViewController ()

// Email address text field
@property (weak, nonatomic) IBOutlet UITextField *emailField;

// Phone number text field
@property (weak, nonatomic) IBOutlet UITextField *numberField;

@end


@implementation RegistrationViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Init properties
    [self.emailField setDelegate:self];
    [self.numberField setDelegate:self];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];  // For hiding the keyboard
    
    [self.view addGestureRecognizer:tap];
}

// Done editing email field
- (IBAction)emailEditEnd:(id)sender {
    NSLog(@"email submit");
}

// Done editing phone number field
- (IBAction)numberDidEnd:(id)sender {
    NSLog(@"phone number submit");
}


// Done / Next key pressed in text field
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // Hide keyboard
    [textField resignFirstResponder];
    
    // Move to phone number field if applicable
    if(textField == self.emailField)
        [self.numberField becomeFirstResponder];
    
    return YES;
}

// Hide keyboard for outside click
-(void)hideKeyboard {
    // Hide keyboard for either text field, if present
    [self.emailField resignFirstResponder];
    [self.numberField resignFirstResponder];
}


#pragma mark System Functions

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
