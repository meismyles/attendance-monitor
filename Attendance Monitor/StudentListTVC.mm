//
//  StudentListTVC.m
//  Attendance Monitor
//
//  Created by Myles Ringle on 24/03/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import <sqlite3.h>
#import "StudentListTVC.h"
#import "EditStudentVC.h"
#import "FaceAnalyser.hh"

@interface StudentListTVC () {
    FaceAnalyser *faceAnalyser;
    NSArray *studentList;
}

@end

@implementation StudentListTVC

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    faceAnalyser = [[FaceAnalyser alloc] init];
    [faceAnalyser openDatabase];
    
    studentList = [self getAllPeople];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (NSArray *)getAllPeople
{
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    const char *findPeopleSQL = "SELECT id, fullName, username FROM people ORDER BY fullName";
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2([faceAnalyser database], findPeopleSQL, -1, &statement, nil) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            NSNumber *personID = [NSNumber numberWithInt:sqlite3_column_int(statement, 0)];
            NSString *personName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 1)];
            NSString *username = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 2)];

            
            [results addObject:@{@"id": personID, @"fullName": personName, @"username": username}];
        }
    }
    
    sqlite3_finalize(statement);
    
    return results;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [studentList count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    // Re-use table view cell
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Set the title of the rows with their corresponding location title
    NSString *studentName = [[studentList objectAtIndex:[indexPath row]] objectForKey:@"fullName"];
    NSString *username = [[studentList objectAtIndex:[indexPath row]] objectForKey:@"username"];
    [[cell textLabel] setText:studentName];
    [[cell detailTextLabel] setText:username];
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


// Prepare to move to new view
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    printf("************* TROLOLOLOL ***************");
    if ([[segue identifier] isEqualToString:@"studentSelected"]) {
        
        NSIndexPath *indexPath = [[self tableView] indexPathForSelectedRow];

        int studentID = [[[studentList objectAtIndex:[indexPath row]] objectForKey:@"id"] intValue];
        NSArray *fullName = [[[studentList objectAtIndex:[indexPath row]] objectForKey:@"fullName"]
                                                                            componentsSeparatedByString:@" "];
        NSString *firstName = [fullName objectAtIndex:0];
        NSString *lastName = [fullName objectAtIndex:1];
        NSString *username = [[studentList objectAtIndex:[indexPath row]] objectForKey:@"username"];
        
        [[segue destinationViewController] setStudentID:studentID];
        [[[segue destinationViewController] firstName] setText:firstName];
        [[[segue destinationViewController] lastName] setText:lastName];
        [[[segue destinationViewController] usernameField] setText:username];
        
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:nil
                                                                                action:nil];
    }
}

@end
