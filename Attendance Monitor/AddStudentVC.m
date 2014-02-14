//
//  AddStudentVC.m
//  Attendance Monitor
//
//  Created by Myles Ringle on 06/02/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import "AddStudentVC.h"

@interface AddStudentVC ()

@end

@implementation AddStudentVC

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [[self navigationItem] setTitle:@"Add Student"];
    [[self navigationItem] setPrompt:@"Please enter the details below."];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end