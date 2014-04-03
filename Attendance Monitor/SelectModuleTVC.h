//
//  SelectModuleTVC.h
//  Attendance Monitor
//
//  Created by Myles Ringle on 29/03/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SelectModuleTVCDelegate
@end

@interface SelectModuleTVC : UITableViewController <UIPickerViewDataSource, UIPickerViewDelegate>

@property (strong, nonatomic) IBOutlet UIPickerView *yearPicker;

@property (nonatomic, assign) id <SelectModuleTVCDelegate> delegate;
@property (strong, nonatomic) NSMutableArray *totalModuleList;

@end