//
//  LoginVC.m
//  Attendance Monitor
//
//  Created by Myles Ringle on 04/04/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import "LoginVC.h"
#import "TaughtModuleTVC.h"

static NSString *loginLink = @"http://livattend.tk/check_login.php";

@interface LoginVC ()

@end

@implementation LoginVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.returnKeyType == UIReturnKeyNext) {
        if (textField == self.username) {
            [self.password becomeFirstResponder];
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
    // Do any additional setup after loading the view.
    [[self navigationItem] setTitle:@"Login"];
    
    [[self username] setDelegate:self];
    [[self password] setDelegate:self];
    
    self.loginButton.buttonColor = [UIColor concreteColor];
    self.loginButton.shadowColor = [UIColor asbestosColor];
    self.loginButton.shadowHeight = 3.0f;
    self.loginButton.titleLabel.font = [UIFont boldFlatFontOfSize:16];
    self.loginButton.highlightedColor = [UIColor blackColor];
    
}

- (void) viewDidAppear:(BOOL)animated {
    [[self username] becomeFirstResponder];
}

- (IBAction)login {
    
    NSString *username = [NSString stringWithFormat:@"%@", [[self username] text]];
    NSString *password = [NSString stringWithFormat:@"%@", [[self password] text]];
    
    NSDictionary *attendanceDict = [NSDictionary dictionaryWithObjectsAndKeys:username, @"username",
                                    password, @"password", nil];
    
    NSError *error;
    NSData *studentData =[NSJSONSerialization dataWithJSONObject:attendanceDict options:0 error:&error];
    NSURL *url = [NSURL URLWithString:loginLink];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%d", (int)studentData.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:studentData];
    
    NSURLResponse *response = nil;
    error = nil;
    
    NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString *uploadResult = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
    
    if (error != nil) {
        UIAlertView *uploadError = [[UIAlertView alloc] initWithTitle:@"Error"
                                                              message:@"Failed to send login data.\nPlease check your network connection and try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [uploadError show];
    }
    else {
        if ([uploadResult isEqualToString:@"correct"]) {
            [self performSegueWithIdentifier: @"loginSegue" sender:self];
        }
        else if ([uploadResult isEqualToString:@"incorrect"]) {
            UIAlertView *incorrectDetails = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                       message:@"Username or password is incorrect.\nPlease try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [incorrectDetails show];
        }
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Prepare to move to new view
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"loginSegue"]) {
        
        UITabBarController *tabBarController = [segue destinationViewController];
        TaughtModuleTVC *taughtModuleTVC = [[[tabBarController.viewControllers objectAtIndex:0] viewControllers] firstObject];
        
        [taughtModuleTVC setUsername:[NSString stringWithFormat:@"%@", [[self username] text]]];
    }
}

@end
