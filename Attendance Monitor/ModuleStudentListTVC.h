//
//  ModuleStudentListTVC.h
//  Attendance Monitor
//
//  Created by Myles Ringle on 03/04/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ModuleStudentListTVC : UITableViewController

@property (assign, nonatomic) int receivedModuleID;
@property (assign, nonatomic) int receivedLectureID;
@property (strong, nonatomic) NSString *receivedModuleCode;

@end
