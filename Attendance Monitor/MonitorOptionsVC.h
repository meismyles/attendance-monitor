//
//  MonitorOptionsVC.h
//  Attendance Monitor
//
//  Created by Myles Ringle on 03/04/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MonitorOptionsVC : UITableViewController

@property (strong, nonatomic) IBOutlet UILabel *moduleCode;
@property (strong, nonatomic) IBOutlet UILabel *moduleTitle;
@property (strong, nonatomic) IBOutlet UITextField *lectureIDField;
@property (strong, nonatomic) IBOutlet UILabel *prevLecture;

@property (assign, nonatomic) int receivedModuleID;
@property (strong, nonatomic) NSString *receivedModuleCode;
@property (strong, nonatomic) NSString *receivedModuleTitle;
@property (strong, nonatomic) NSString *receivedPrevLectureID;

@end