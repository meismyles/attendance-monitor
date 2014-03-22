//
//  AddStudentVC.m
//  Attendance Monitor
//
//  Created by Myles Ringle on 06/02/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import "AddStudentVC.h"
#import "CaptureImagesVC.h"
#import "FaceAnalyser.hh"

@interface AddStudentVC () {
    FaceAnalyser *faceAnalyser;
}

@end

@implementation AddStudentVC

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [[self navigationItem] setTitle:@"Add Student"];
    [[self navigationItem] setPrompt:@"Please enter the details below."];
    
    faceAnalyser = [[FaceAnalyser alloc] init];
}

- (void)viewWillDisappear:(BOOL)animated
{

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Prepare to move to new view
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"captureImagesSegue"]) {
        
        [self saveStudent];
        
        NSString *username = [NSString stringWithFormat:@"%@", [[self usernameField] text]];
        [[segue destinationViewController] setUsername:username];
        
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:nil
                                                                                action:nil];
    }
}

- (IBAction)saveStudent {
    [faceAnalyser openDatabase];
    
    // People table
    const char *peopleSQL = "CREATE TABLE IF NOT EXISTS people ("
    "'id' integer NOT NULL PRIMARY KEY AUTOINCREMENT, "
    "'fullName' text NOT NULL, "
    "'username' text NOT NULL, "
    "'pass' text NOT NULL)";
    
    if (sqlite3_exec([faceAnalyser database], peopleSQL, nil, nil, nil) != SQLITE_OK) {
        NSLog(@"The people table could not be created.");
    }
    
    // Images table
    const char *imagesSQL = "CREATE TABLE IF NOT EXISTS images ("
    "'id' integer NOT NULL PRIMARY KEY AUTOINCREMENT, "
    "'person_id' integer NOT NULL, "
    "'image' blob NOT NULL)";
    
    if (sqlite3_exec([faceAnalyser database], imagesSQL, nil, nil, nil) != SQLITE_OK) {
        NSLog(@"The images table could not be created.");
    }

    NSString *fullName = [NSString stringWithFormat:@"%@ %@", [[self firstName] text], [[self lastName] text]];
    NSString *username = [NSString stringWithFormat:@"%@", [[self usernameField] text]];
    NSString *password = [NSString stringWithFormat:@"%@", [[self passwordField] text]];
    
    const char *newPersonSQL = "INSERT INTO people (fullName, username, pass) VALUES (?, ?, ?)";
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2([faceAnalyser database], newPersonSQL, -1, &statement, nil) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [fullName UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 2, [username UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 3, [password UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_step(statement);
    }
    
    sqlite3_finalize(statement);
    sqlite3_last_insert_rowid([faceAnalyser database]);
    
    
    /*
    // PRITING THE CONTENTS OF THE ARRAY
    
    // GETTING THE CONTENTS
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    const char *findPeopleSQL = "SELECT id, fullName, username, pass FROM people ORDER BY id";
    sqlite3_stmt *statement2;
    
    if (sqlite3_prepare_v2([faceAnalyser database], findPeopleSQL, -1, &statement2, nil) == SQLITE_OK) {
        while (sqlite3_step(statement2) == SQLITE_ROW) {
            NSNumber *personID = [NSNumber numberWithInt:sqlite3_column_int(statement2, 0)];
            NSString *personName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement2, 1)];
            NSString *username = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement2, 2)];
            NSString *password = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement2, 3)];

            [results addObject:@{@"id": personID, @"fullName": personName, @"username": username, @"pass": password}];
        }
    }
    
    sqlite3_finalize(statement2);
    
    // PRINTING THE CONTENTS
    for (int i = 0; i < [results count]; i++) {
        NSDictionary *temp = [results objectAtIndex:i];
        NSLog(@"*** %@ - %@ - %@ - %@ ***", [temp objectForKey:@"id"], [temp objectForKey:@"fullName"], [temp objectForKey:@"username"], [temp objectForKey:@"pass"]);
    }
    
    [self.navigationController popViewControllerAnimated:YES];
    */ 
}


@end