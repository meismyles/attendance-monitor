//
//  UploadDataVC.h
//  Attendance Monitor
//
//  Created by Myles Ringle on 03/04/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FUIButton.h"
#import "UIColor+FlatUI.h"
#import "UIFont+FlatUI.h"
#import "SelectModuleTVC.h"

@interface UploadDataVC : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *username;
@property (strong, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet FUIButton *saveDataButton;

@property (assign, nonatomic) int receivedModuleID;
@property (assign, nonatomic) int receivedLectureID;
@property (strong, nonatomic) NSMutableArray *studentList;

@end
