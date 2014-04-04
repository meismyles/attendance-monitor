//
//  UploadDataVC.m
//  Attendance Monitor
//
//  Created by Myles Ringle on 03/04/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import "UploadDataVC.h"

static NSString *addAttendanceLink = @"http://livattend.tk/add_attendance.php";

@interface UploadDataVC ()

@end

@implementation UploadDataVC

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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[self username] setDelegate:self];
    [[self password] setDelegate:self];
    
    self.saveDataButton.buttonColor = [UIColor concreteColor];
    self.saveDataButton.shadowColor = [UIColor asbestosColor];
    self.saveDataButton.shadowHeight = 3.0f;
    self.saveDataButton.titleLabel.font = [UIFont boldFlatFontOfSize:16];
    self.saveDataButton.highlightedColor = [UIColor blackColor];
    
    
    NSString *prevVCName = NSStringFromClass([[self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2] class]);
    
    if ([prevVCName isEqualToString:@"MultiScanVC"]) {
        [self.navigationItem setHidesBackButton:YES];
    }
    
}

- (IBAction)uploadData {
    
    NSString *username = [NSString stringWithFormat:@"%@", [[self username] text]];
    NSString *password = [NSString stringWithFormat:@"%@", [[self password] text]];
    
    NSDictionary *attendanceDict = [NSDictionary dictionaryWithObjectsAndKeys:username, @"username",
                                    password, @"password",
                                    [NSNumber numberWithInt:[self receivedLectureID]], @"lectureID",
                                    [NSNumber numberWithInt:[self receivedModuleID]], @"moduleID",
                                    [self studentList], @"attendance", nil];
    
    NSError *error;
    NSData *studentData =[NSJSONSerialization dataWithJSONObject:attendanceDict options:0 error:&error];
    NSURL *url = [NSURL URLWithString:addAttendanceLink];
    
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
                                                         message:@"Failed to upload attendance data.\nPlease check your network connection and try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [uploadError show];
    }
    else {
        if ([uploadResult isEqualToString:@"correct"]) {
            [[[[[[self navigationController] tabBarController] tabBar] items] objectAtIndex:0] setEnabled:YES];
            [[[[[[self navigationController] tabBarController] tabBar] items] objectAtIndex:1] setEnabled:YES];
            [self.navigationController popToRootViewControllerAnimated:YES];
            UIAlertView *dataSaved = [[UIAlertView alloc] initWithTitle:@"Data Saved"
                                                                   message:@"The attendance data has been successfully uploaded and saved." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [dataSaved show];
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

@end
