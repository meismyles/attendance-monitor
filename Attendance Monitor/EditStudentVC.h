//
//  EditStudentVC.h
//  Attendance Monitor
//
//  Created by Myles Ringle on 24/03/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FUIButton.h"
#import "UIColor+FlatUI.h"
#import "UIFont+FlatUI.h"

@interface EditStudentVC : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *firstName;
@property (strong, nonatomic) IBOutlet UITextField *lastName;
@property (strong, nonatomic) IBOutlet UITextField *usernameField;
@property (strong, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet FUIButton *captureImagesButton;

@property (assign, nonatomic) int studentID;
@property (strong, nonatomic) NSString *receivedFirstName;
@property (strong, nonatomic) NSString *receivedLastName;
@property (strong, nonatomic) NSString *receivedUsername;

@end
