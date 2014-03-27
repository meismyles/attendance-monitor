//
//  AddStudentVC.h
//  Attendance Monitor
//
//  Created by Myles Ringle on 06/02/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>

@interface AddStudentVC : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *firstName;
@property (strong, nonatomic) IBOutlet UITextField *lastName;
@property (strong, nonatomic) IBOutlet UITextField *usernameField;
@property (strong, nonatomic) IBOutlet UITextField *passwordField;

@end