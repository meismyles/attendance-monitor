//
//  AddStudentVC.h
//  Attendance Monitor
//
//  Created by Myles Ringle on 06/02/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FUIButton.h"
#import "UIColor+FlatUI.h"
#import "UIFont+FlatUI.h"
#import "SelectModuleTVC.h"

@protocol SelectModuleTVC;

@interface AddStudentVC : UIViewController <UITextFieldDelegate, SelectModuleTVCDelegate>

@property (strong, nonatomic) IBOutlet UITextField *firstName;
@property (strong, nonatomic) IBOutlet UITextField *lastName;
@property (strong, nonatomic) IBOutlet UITextField *usernameField;
@property (strong, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet FUIButton *selectModulesButton;

- (void)doneSelectModuleList:(SelectModuleTVC *)controller;

@end