//
//  AddStudentVC.h
//  Attendance Monitor
//
//  Created by Myles Ringle on 06/02/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddStudentVC : UIViewController

@property (strong, nonatomic) IBOutlet UITextField *firstName;
@property (strong, nonatomic) IBOutlet UITextField *lastName;
@property (strong, nonatomic) IBOutlet UITextField *username;
@property (strong, nonatomic) IBOutlet UITextField *password;

@end
