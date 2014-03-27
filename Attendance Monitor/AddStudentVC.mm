//
//  AddStudentVC.m
//  Attendance Monitor
//
//  Created by Myles Ringle on 06/02/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import "AddStudentVC.h"
#import "CaptureImagesVC.h"
#import "FaceAnalyser.hh"

static NSString *addUserLink = @"http://project.waroftoday.com/add_user.php";

@interface AddStudentVC ()

@end

@implementation AddStudentVC

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.returnKeyType == UIReturnKeyNext) {
        if (textField == self.firstName) {
            [self.lastName becomeFirstResponder];
        }
        else if (textField == self.lastName) {
            [self.usernameField becomeFirstResponder];
        }
        else if (textField == self.usernameField) {
            [self.passwordField becomeFirstResponder];
        }
    }
    else if (textField.returnKeyType == UIReturnKeyDone) {
        [textField resignFirstResponder];
    }
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [[self navigationItem] setTitle:@"Add Student"];
    [[self navigationItem] setPrompt:@"Please enter the details below."];
    
    [[self firstName] setDelegate:self];
    [[self lastName] setDelegate:self];
    [[self usernameField] setDelegate:self];
    [[self passwordField] setDelegate:self];
}

- (void)viewWillDisappear:(BOOL)animated
{

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Prepare to move to new view
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"addCaptureImagesSegue"]) {
        
        [self saveStudent];
        
        NSString *username = [NSString stringWithFormat:@"%@", [[self usernameField] text]];
        [[segue destinationViewController] setUsername:username];
        
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:nil
                                                                                action:nil];
    }
}

- (IBAction)saveStudent {
    
    NSString *fullName = [NSString stringWithFormat:@"%@ %@", [[self firstName] text], [[self lastName] text]];
    NSString *username = [NSString stringWithFormat:@"%@", [[self usernameField] text]];
    NSString *password = [NSString stringWithFormat:@"%@", [[self passwordField] text]];
    
    NSDictionary *studentDict = [NSDictionary dictionaryWithObjectsAndKeys:fullName, @"fullname",
                                                                            username, @"username",
                                                                            password, @"password", nil];
    
    NSError *error;
    NSData *studentData =[NSJSONSerialization dataWithJSONObject:studentDict options:0 error:&error];
    NSURL *url = [NSURL URLWithString:addUserLink];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%d", (int)studentData.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:studentData];
    
    NSURLResponse *response = nil;
    error = nil;
    
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
}


@end