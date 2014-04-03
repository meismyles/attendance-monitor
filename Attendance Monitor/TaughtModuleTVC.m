//
//  TaughtModuleTVC.m
//  Attendance Monitor
//
//  Created by Myles Ringle on 06/02/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import "TaughtModuleTVC.h"
#import "MonitorOptionsVC.h"

static NSString *getTaughtModules = @"http://livattend.tk/get_taught_modules.php";

@interface TaughtModuleTVC () {
    UIActivityIndicatorView *activityView;
    UIAlertView *downloadFailedAlert;

}

@property (strong, nonatomic) NSArray *moduleList;
@property (assign, nonatomic) BOOL downloadInProgress;
@property (assign, nonatomic) BOOL downloadFailed;

@end

@implementation TaughtModuleTVC

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self setUsername:@"tpayne"]; // *******************************************************************************
    
    [self setDownloadInProgress:NO];
    [self setDownloadFailed:YES];
    
    // Add refresh control to Master table view.
    // Used to re-download the module details dictionary.
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshStudentList) forControlEvents:UIControlEventValueChanged];
    [self setRefreshControl:refreshControl];
    
    [self addLoadingSpinner];
    [self refreshStudentList];
}

- (void) refreshStudentList {
    
    [self setModuleList:nil];
    
    // Call method again to re-download
    [self getModuleList];
}

- (NSArray *) getModuleList {
    
    // Only download module details if it does not already exist and if a download is not currently
    // in progress.
    if ((_moduleList == nil) && ([self downloadInProgress] == NO)) {
        
        // Create the thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSDictionary *studentDict = [NSDictionary dictionaryWithObjectsAndKeys:[self username], @"username", nil];
            
            NSError *error;
            NSData *studentData =[NSJSONSerialization dataWithJSONObject:studentDict options:0 error:&error];
            NSURL *url = [NSURL URLWithString:getTaughtModules];
            
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
            [self performSelectorOnMainThread:@selector(fetchedModuleList:) withObject:data waitUntilDone:YES];
        });
        [self setDownloadInProgress:YES];
    }
    return _moduleList;
}

// Method to parse JSON.
// Stop _studentList from being modified before fully downloaded.
- (void) fetchedModuleList:(NSData *) data {
    
    // Check if the download was interrupted or failed.
    // If so, display an error alert and instruct the user accordingly.
    if ((data == nil) || ([self downloadFailed])) {
        // End the refresh animation of the refresh control.
        [[self refreshControl] endRefreshing];
        [self removeLoadingSpinner];
        
        [self setDownloadInProgress:NO];
        downloadFailedAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                         message:@"Failed to download module list.\nPlease check your network connection or push retry to try again." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", @"Retry", nil];
        [downloadFailedAlert show];
    }
    // Otherwise, the download was successful.
    else {
        NSError *error;
        
        // Note that we are not calling the setter method here... as this would be recursive!!!
        _moduleList = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        
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

/////////////////////////////////////
#pragma mark - Table view data source
/////////////////////////////////////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[self moduleList] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    // Re-use table view cell
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary *moduleDict = [[self moduleList] objectAtIndex:[indexPath row]];
    
    // Set the main text to be the module code and the subtitle to be the module title.
    [[cell textLabel] setText:[moduleDict objectForKey:@"code"]];
    [[cell detailTextLabel] setText:[moduleDict objectForKey:@"title"]];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Your Modules";
}

///////////////////////////////////////

// Prepare to move to new view
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"selectedModuleAttendance"]) {
        
        NSIndexPath *indexPath = [[self tableView] indexPathForSelectedRow];
        
        NSDictionary *moduleDetails = [[self moduleList] objectAtIndex:[indexPath row]];
        
        
        int moduleID = [[moduleDetails objectForKey:@"id"] intValue];
        NSString *moduleCode = [moduleDetails objectForKey:@"code"];
        NSString *moduleTitle = [moduleDetails objectForKey:@"title"];
        
        [[segue destinationViewController] setReceivedModuleID:moduleID];
        [[segue destinationViewController] setReceivedModuleCode:moduleCode];
        [[segue destinationViewController] setReceivedModuleTitle:moduleTitle];
        
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
