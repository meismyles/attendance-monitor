//
//  EditStudentVC.m
//  Attendance Monitor
//
//  Created by Myles Ringle on 24/03/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import "EditStudentVC.h"

@interface EditStudentVC ()

@end

@implementation EditStudentVC

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
    // Do any additional setup after loading the view.
    
    [[self firstName] setDelegate:self];
    [[self lastName] setDelegate:self];
    [[self usernameField] setDelegate:self];
    [[self passwordField] setDelegate:self];
    
    self.captureImagesButton.buttonColor = [UIColor concreteColor];
    self.captureImagesButton.shadowColor = [UIColor asbestosColor];
    self.captureImagesButton.shadowHeight = 3.0f;
    self.captureImagesButton.cornerRadius = 6.0f;
    self.captureImagesButton.titleLabel.font = [UIFont boldFlatFontOfSize:16];
    self.captureImagesButton.highlightedColor = [UIColor blackColor];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
