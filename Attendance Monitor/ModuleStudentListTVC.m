//
//  ModuleStudentListTVC.m
//  Attendance Monitor
//
//  Created by Myles Ringle on 03/04/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import "ModuleStudentListTVC.h"
#import "SingleScanVC.h"

static NSString *getStudentsLink = @"http://livattend.tk/get_students_for_module.php";

@interface ModuleStudentListTVC () {
    UIActivityIndicatorView *activityView;
    
    UIAlertView *downloadFailedAlert;
}

@property (strong, nonatomic) NSMutableArray *studentList;
@property (assign, nonatomic) BOOL downloadInProgress;
@property (assign, nonatomic) BOOL downloadFailed;
@property (assign, nonatomic) BOOL reloadStudentList;

@end

@implementation ModuleStudentListTVC

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
    
    [[[[[[self navigationController] tabBarController] tabBar] items] objectAtIndex:0] setEnabled:NO];
    [[[[[[self navigationController] tabBarController] tabBar] items] objectAtIndex:1] setEnabled:NO];
    
    [[self navigationItem] setTitle:[NSString stringWithFormat:@"%@: Student List", [self receivedModuleCode]]];
    [self.navigationItem setHidesBackButton:YES];
    
    [self setDownloadInProgress:NO];
    [self setDownloadFailed:YES];
    [self setReloadStudentList:NO];
    
}

- (void)viewDidAppear:(BOOL)animated {
    if (([self studentList] == nil) || ([self reloadStudentList] == YES)) {
        [self addLoadingSpinner];
        [self refreshStudentList];
        [self setReloadStudentList:NO];
    }
    else {
        [[self tableView] reloadData];
    }
}

- (void) viewDidDisappear:(BOOL)animated {
    [self removeLoadingSpinner];
}

// Method to re-download the student list
- (void) refreshStudentList {
    
    [self setStudentList:nil];
    
    // Call method again to re-download
    [self getStudentList];
}

- (NSArray *) getStudentList {
    
    // Only download module details if it does not already exist and if a download is not currently
    // in progress.
    if ((_studentList == nil) && ([self downloadInProgress] == NO)) {
        
        // Create the thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSDictionary *studentDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:[self receivedModuleID]], @"moduleID", nil];
            
            NSError *error;
            NSData *studentData =[NSJSONSerialization dataWithJSONObject:studentDict options:0 error:&error];
            NSURL *url = [NSURL URLWithString:getStudentsLink];
            
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
            [request setURL:url];
            [request setHTTPMethod:@"POST"];
            [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            [request setValue:[NSString stringWithFormat:@"%d", (int)studentData.length] forHTTPHeaderField:@"Content-Length"];
            [request setHTTPBody:studentData];
            
            NSURLResponse *response = nil;
            error = nil;
            
            NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            
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
        // End the refresh animation of the refresh control.
        [[self refreshControl] endRefreshing];
        [self removeLoadingSpinner];
        
        [self setDownloadInProgress:NO];
        downloadFailedAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                         message:@"Failed to download student list.\nPlease check your network connection or push retry to try again." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", @"Retry", nil];
        [downloadFailedAlert show];
    }
    // Otherwise, the download was successful.
    else {
        NSError *error;
        
        // Note that we are not calling the setter method here... as this would be recursive!!!
        _studentList = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        
        // Reset the download property, as we have now finished the download.
        [self setDownloadInProgress:NO];
        
        
        // End the refresh animation of the refresh control.
        [[self refreshControl] endRefreshing];
        [self removeLoadingSpinner];
        
        [[self tableView] reloadData];
    }
}

- (void) addLoadingSpinner {
    
    activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [activityView setColor:[UIColor grayColor]];
    
    activityView.center = CGPointMake(self.tableView.frame.size.width/2,
                                      (self.tableView.frame.size.height/2)-self.tabBarController.tabBar.frame.size.height);
    [activityView startAnimating];
    
    [self.view addSubview:activityView];
}

- (void) removeLoadingSpinner {
    [activityView stopAnimating];
    [activityView removeFromSuperview];
}
    
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary *studentDetails = [[self studentList] objectAtIndex:[indexPath row]];
    
    // Set the title of the rows with their corresponding location title
    [[cell textLabel] setText:[studentDetails objectForKey:@"fullname"]];
    [[cell detailTextLabel] setText:[studentDetails objectForKey:@"username"]];
        
    if ([[studentDetails objectForKey:@"status"] intValue] != 0) {
        [cell setUserInteractionEnabled:NO];
        [[cell textLabel] setEnabled:NO];
        [[cell detailTextLabel] setEnabled:NO];
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sectionTitle = [NSString stringWithFormat:@"Number of Students: %d", (int)[[self studentList] count]];
    return sectionTitle;
}


// Prepare to move to new view
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"studentSelectedSingleScan"]) {
        
        NSIndexPath *indexPath = [[self tableView] indexPathForSelectedRow];
        NSMutableDictionary *studentDetails = [[self studentList] objectAtIndex:[indexPath row]];
        
        [[segue destinationViewController] setStudentDetails:studentDetails];
                
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:nil
                                                                                action:nil];
    }
    if ([[segue identifier] isEqualToString:@"finishAttendanceMonitor"]) {
        
        [[segue destinationViewController] setReceivedModuleID:[self receivedModuleID]];
        [[segue destinationViewController] setReceivedLectureID:[self receivedLectureID]];
        [[segue destinationViewController] setStudentList:[self studentList]];
        
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
        if (buttonIndex == 1) {
            [self addLoadingSpinner];
            [[self refreshControl] beginRefreshing];
            [self refreshStudentList];
        }
    }
    
}


@end
