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

static NSString *addUserLink = @"http://livattend.tk/add_user.php";
static NSString *getModuleList = @"http://livattend.tk/get_modules.php";

@interface AddStudentVC () {
    UIAlertView *downloadFailedAlert;
    UIAlertView *emptyFieldAlert;
}

@property (strong, nonatomic) UINavigationController *navController;
@property (strong, nonatomic) SelectModuleTVC *selectModuleController;

@property (assign, nonatomic) BOOL downloadInProgress;
@property (assign, nonatomic) BOOL downloadFailed;

@property (strong, nonatomic) NSMutableArray *moduleList;

@end

@implementation AddStudentVC

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.returnKeyType == UIReturnKeyNext) {
        if (textField == self.firstName) {
            [self.lastName becomeFirstResponder];
        }
        else if (textField == self.lastName) {
            [self.usernameField becomeFirstResponder];
        }
        else if (textField == self.usernameField) {
            [self.passwordField becomeFirstResponder];
        }
    }
    else if (textField.returnKeyType == UIReturnKeyDone) {
        [textField resignFirstResponder];
    }
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [[self navigationItem] setTitle:@"Add Student"];
    
    [self setDownloadInProgress:NO];
    [self setDownloadFailed:YES];
    
    [[self firstName] setDelegate:self];
    [[self lastName] setDelegate:self];
    [[self usernameField] setDelegate:self];
    [[self passwordField] setDelegate:self];
    
    self.selectModulesButton.buttonColor = [UIColor concreteColor];
    self.selectModulesButton.shadowColor = [UIColor asbestosColor];
    self.selectModulesButton.shadowHeight = 3.0f;
    self.selectModulesButton.titleLabel.font = [UIFont boldFlatFontOfSize:16];
    self.selectModulesButton.highlightedColor = [UIColor blackColor];
    
    [self refreshModuleList];
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
    
    if ([[segue identifier] isEqualToString:@"addCaptureImagesSegue"]) {
        NSString *username = [NSString stringWithFormat:@"%@", [[self usernameField] text]];
        [[segue destinationViewController] setUsername:username];
    }
}

- (IBAction)saveStudent {
    
    NSString *fullName = [NSString stringWithFormat:@"%@ %@", [[self firstName] text], [[self lastName] text]];
    NSString *username = [NSString stringWithFormat:@"%@", [[self usernameField] text]];
    NSString *password = [NSString stringWithFormat:@"%@", [[self passwordField] text]];
    
    BOOL emptyInput = NO;
    emptyFieldAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                 message:@"Please enter a password." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *trimmed1 = [password stringByTrimmingCharactersInSet:whitespace];
    if ([trimmed1 length] == 0) {
        emptyInput = YES;
    }
    NSString *trimmed2 = [username stringByTrimmingCharactersInSet:whitespace];
    if ([trimmed2 length] == 0) {
        emptyInput = YES;
        emptyFieldAlert.message = @"Please enter a username.";
    }
    NSString *trimmed3 = [fullName stringByTrimmingCharactersInSet:whitespace];
    if ([trimmed3 length] == 0) {
        emptyInput = YES;
        emptyFieldAlert.message = @"Please enter the students name.";
    }
    
    if (emptyInput == NO) {
        NSMutableArray *selectedModulesArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < [[self moduleList] count]; i++) {
            NSMutableArray *yearArray = [[self moduleList] objectAtIndex:i];
            
            for (int j = 0; j < [yearArray count]; j++) {
                NSMutableArray *semesterArray = [yearArray objectAtIndex:j];
                
                for (int k = 0; k < [semesterArray count]; k++) {
                    NSMutableDictionary *moduleDict = [semesterArray objectAtIndex:k];
                    if ([[moduleDict objectForKey:@"cmark"] intValue] == 1) {
                        [selectedModulesArray addObject:[moduleDict objectForKey:@"id"]];
                    }
                }
            }
        }
        
        NSDictionary *studentDict = [NSDictionary dictionaryWithObjectsAndKeys:fullName, @"fullname",
                                                                                username, @"username",
                                                                                password, @"password",
                                                                                selectedModulesArray, @"modules", nil];
        
        NSError *error;
        NSData *studentData =[NSJSONSerialization dataWithJSONObject:studentDict options:0 error:&error];
        NSURL *url = [NSURL URLWithString:addUserLink];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:url];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"%d", (int)studentData.length] forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody:studentData];
        
        NSURLResponse *response = nil;
        error = nil;
        
        [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        [self performSegueWithIdentifier: @"addCaptureImagesSegue" sender:self];
    }
    else {
        [emptyFieldAlert show];
    }
}

//==============================================================================
#pragma mark - Modal View
//==============================================================================

// Method to create the navigation controller.
- (UINavigationController *) navController {
    
    // Only create if doesn't exist.
    if (_navController == nil) {
        _navController = [[UINavigationController alloc] init];
        
        // Push the modal table view controller into the root view of the nav controller.
        [_navController pushViewController:[self selectModuleController] animated:NO];
        
        // Set styles for its display and animations to display.
        [_navController setModalPresentationStyle:UIModalPresentationFormSheet];
        [_navController setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
    }
    return _navController;
}

// Lazy instantiation to create the edit module controller
- (SelectModuleTVC *)selectModuleController {
    
    // Only create if doesn't exist.
    if (_selectModuleController == nil) {
        _selectModuleController = [[SelectModuleTVC alloc]
                                 initWithNibName:@"SelectModuleTVC"
                                 bundle:nil];
        [_selectModuleController setDelegate:self];
    }
    return _selectModuleController;
}

// Method to show the modal view to edit modules.
- (IBAction) showSelectModuleList:(id)sender {
    if ([self downloadFailed]) {
        UIAlertView *downloadNotComplete = [[UIAlertView alloc] initWithTitle:@"Please Wait"
                                                         message:@"Module list download has not completed yet.\nPlease wait and try again." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [downloadNotComplete show];
    }
    else {
        [[self selectModuleController] setTotalModuleList:[self moduleList]];
        [self presentViewController:[self navController] animated:YES completion:nil];
    }
}

// Method to dismiss the modal view.
- (void) doneSelectModuleList:(SelectModuleTVC *)controller {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

// Method to re-download the student list
- (void) refreshModuleList {
    
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
            
            // Generate the URL request for the JSON data
            NSURL *url = [NSURL URLWithString:getModuleList];
            NSError *error;
            
            // Get the data.
            NSData *data = [NSData dataWithContentsOfURL:url options:kNilOptions error:&error];
            
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
        [self setDownloadInProgress:NO];
        downloadFailedAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                         message:@"Failed to download module list.\nPlease check your network connection or push retry to try again." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", @"Retry", nil];
        [downloadFailedAlert show];
    }
    // Otherwise, the download was successful.
    else {
        NSError *error;
        
        // Note that we are not calling the setter method here... as this would be recursive!!!
        _moduleList = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        
        // Reset the download property, as we have now finished the download.
        [self setDownloadInProgress:NO];
        
        // Check again to make sure the download has completely finished.
        if (_moduleList != nil) {
            
            // ********* DO ANYTHING AFTER DOWNLOAD HAS COMPLETED **********
        }
    }
}

//==============================================================================
#pragma mark - Error Handling
//==============================================================================

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView == downloadFailedAlert) {
        if (buttonIndex == 1) {
            [self refreshModuleList];
        }
    }
    
}

@end