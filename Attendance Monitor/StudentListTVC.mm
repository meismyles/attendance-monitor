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

static NSString *getAllPeopleLink = @"http://project.waroftoday.com/index.php";

@interface StudentListTVC () {
    UIAlertView *downloadFailedAlert;
}

@property (assign, nonatomic) BOOL downloadInProgress;
@property (assign, nonatomic) BOOL downloadFailed;

@property (strong, nonatomic) NSArray *studentList;

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
    
    [self setDownloadInProgress:NO];
    [self setDownloadFailed:YES];
    
    [self refreshStudentList];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

// Method to re-download the student list
- (void) refreshStudentList {

    [self setStudentList:nil];
    
    // Call method again to re-download
    [self getStudentList];

}

/*
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
*/

- (NSArray *) getStudentList {
    
    // Only download module details if it does not already exist and if a download is not currently
    // in progress.
    if ((_studentList == nil) && ([self downloadInProgress] == NO)) {
        
        // Create the thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            // Generate the URL request for the JSON data
            NSURL *url = [NSURL URLWithString:getAllPeopleLink];
            NSError *error;
            
            // Get the data.
            NSData *data = [NSData dataWithContentsOfURL:url options:kNilOptions error:&error];
            
            // Check for error while downloading.
            // If not, set bool accordingly.
            if (error == nil) {
                [self setDownloadFailed:NO];
            }
            
            // Call fetchedModuleDetails and pass the data to be handled.
            [self performSelectorOnMainThread:@selector(fetchedStudentList:) withObject:data waitUntilDone:YES];
        });
        [self setDownloadInProgress:YES];
    }
    return _studentList;
}

// Method to parse JSON.
// Stop _studentList from being modified before fully downloaded.
- (void) fetchedStudentList:(NSData *) data {
    
    // Check if the download was interrupted or failed.
    // If so, display an error alert and instruct the user accordingly.
    if ((data == nil) || ([self downloadFailed])) {
        [self setDownloadInProgress:NO];
        downloadFailedAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Failed to download student list.\nPlease check your network connection or push retry to try again." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Retry", nil];
        [downloadFailedAlert show];
    }
    // Otherwise, the download was successful.
    else {
        NSError *error;
        
        // Note that we are not calling the setter method here... as this would be recursive!!!
        _studentList = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        
        // Reset the download property, as we have now finished the download.
        [self setDownloadInProgress:NO];
        
        // Check again to make sure the download has completely finished.
        if (_studentList != nil) {
            
            // ****************************************************************************************************************
            // End the refresh animation of the refresh control.
            // [[self refreshControl] endRefreshing];
            
            [[self tableView] reloadData];
            
        }
    }
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
    return [[self studentList] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    // Re-use table view cell
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary *studentDetails = [[self studentList] objectAtIndex:[indexPath row]];
    
    // Set the title of the rows with their corresponding location title
    NSString *studentName = [studentDetails objectForKey:@"fullname"];
    [[cell textLabel] setText:studentName];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sectionTitle = [NSString stringWithFormat:@"Number of Students: %d", (int)[[self studentList] count]];
    return sectionTitle;
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
    if ([[segue identifier] isEqualToString:@"studentSelected"]) {
        
        NSIndexPath *indexPath = [[self tableView] indexPathForSelectedRow];

        NSDictionary *studentDetails = [[self studentList] objectAtIndex:[indexPath row]];

        
        int studentID = [[studentDetails objectForKey:@"id"] intValue];
        NSArray *fullName = [[studentDetails objectForKey:@"fullname"] componentsSeparatedByString:@" "];
        NSString *firstName = [fullName objectAtIndex:0];
        NSString *lastName = [fullName objectAtIndex:1];
        NSString *username = [studentDetails objectForKey:@"username"];
        
        [[segue destinationViewController] setStudentID:studentID];
        [[segue destinationViewController] setReceivedFirstName:firstName];
        [[segue destinationViewController] setReceivedLastName:lastName];
        [[segue destinationViewController] setReceivedUsername:username];
        
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:nil
                                                                                action:nil];
    }
}


//==============================================================================
#pragma mark - Error Handling
//==============================================================================

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView == downloadFailedAlert) {
        if (buttonIndex == 0) {
            // START RE-DOWNLOAD HERE
        }
    }
    
}

@end
