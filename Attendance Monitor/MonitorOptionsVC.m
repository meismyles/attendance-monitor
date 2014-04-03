//
//  MonitorOptionsVC.m
//  Attendance Monitor
//
//  Created by Myles Ringle on 03/04/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import "MonitorOptionsVC.h"

static NSString *addLectureLink = @"http://livattend.tk/add_lecture.php";

@interface MonitorOptionsVC () {
    int nextLectureID;
    UIAlertView *checkMonitorSettings;
    UIAlertView *checkCancel;
}

@end

@implementation MonitorOptionsVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[self moduleCode] setText:[self receivedModuleCode]];
    [[self moduleTitle] setText:[self receivedModuleTitle]];

    nextLectureID = [[self receivedPrevLectureID] intValue] + 1;
    
    [[self lectureIDField] setText:[NSString stringWithFormat:@"%d", nextLectureID]];
    
    if (nextLectureID > 1) {
        [[self prevLecture] setText:[NSString stringWithFormat:@"Previous Lecture: %d", [[self receivedPrevLectureID] intValue]]];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)saveLecture {
    
    UITableViewCell *cell = [[self tableView] cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    if ([cell accessoryType] == UITableViewCellAccessoryCheckmark) {
        checkCancel = [[UIAlertView alloc] initWithTitle:@"Are you sure?"
                                                               message:@"Are you sure you wish to cancel this lecture?" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Continue", @"Cancel", nil];
        [checkCancel show];
    }
    else {
        cell = [[self tableView] cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
        if ([cell accessoryType] == UITableViewCellAccessoryCheckmark) {
            checkMonitorSettings = [[UIAlertView alloc] initWithTitle:@"Are you sure?"
                                                                   message:@"Do you wish to continue with the selected monitoring options.\nThese cannot be changed." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Continue", @"Cancel", nil];
            [checkMonitorSettings show];
        }
    }
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            if ([cell accessoryType] == UITableViewCellAccessoryNone) {
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
                UITableViewCell *otherCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
                [otherCell setAccessoryType:UITableViewCellAccessoryNone];
                
                UITableViewCell *section2Cell1 = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
                UITableViewCell *section2Cell2 = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
                section2Cell1.userInteractionEnabled = YES;
                section2Cell1.textLabel.enabled = YES;
                [section2Cell1 setAccessoryType:UITableViewCellAccessoryCheckmark];
                section2Cell2.userInteractionEnabled = YES;
                section2Cell2.textLabel.enabled = YES;
            }
        }
        else if (indexPath.row == 1) {
            if ([cell accessoryType] == UITableViewCellAccessoryNone) {
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
                UITableViewCell *otherCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
                [otherCell setAccessoryType:UITableViewCellAccessoryNone];
                
                UITableViewCell *section2Cell1 = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
                UITableViewCell *section2Cell2 = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
                section2Cell1.userInteractionEnabled = NO;
                section2Cell1.textLabel.enabled = NO;
                [section2Cell1 setAccessoryType:UITableViewCellAccessoryNone];
                section2Cell2.userInteractionEnabled = NO;
                section2Cell2.textLabel.enabled = NO;
                [section2Cell2 setAccessoryType:UITableViewCellAccessoryNone];
            }
        }
    }
    if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            if ([cell accessoryType] == UITableViewCellAccessoryNone) {
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
                UITableViewCell *otherCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
                [otherCell setAccessoryType:UITableViewCellAccessoryNone];
            }
        }
        else if (indexPath.row == 1) {
            if ([cell accessoryType] == UITableViewCellAccessoryNone) {
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
                UITableViewCell *otherCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
                [otherCell setAccessoryType:UITableViewCellAccessoryNone];
            }
        }
    }
}

// Prepare to move to new view
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"singleScanSegue"]) {
        [[segue destinationViewController] setReceivedModuleID:[self receivedModuleID]];
        [[segue destinationViewController] setReceivedModuleCode:[self receivedModuleCode]];
    }
    else if ([[segue identifier] isEqualToString:@"multiScanSegue"]) {
        
        
    }
}

//==============================================================================
#pragma mark - Error Handling
//==============================================================================

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView == checkMonitorSettings) {
        if (buttonIndex == 0) {
            NSDictionary *lectureDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSNumber numberWithInt:nextLectureID], @"lectureID",
                                         [NSNumber numberWithInt:[self receivedModuleID]], @"moduleID",
                                         [NSNumber numberWithInt:1], @"status", nil];
            
            NSError *error;
            NSData *studentData =[NSJSONSerialization dataWithJSONObject:lectureDict options:0 error:&error];
            NSURL *url = [NSURL URLWithString:addLectureLink];
            
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
            [self performSegueWithIdentifier: @"singleScanSegue" sender:self];
        }
    }
    if (alertView == checkCancel) {
        if (buttonIndex == 0) {
            NSDictionary *lectureDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSNumber numberWithInt:nextLectureID], @"lectureID",
                                         [NSNumber numberWithInt:[self receivedModuleID]], @"moduleID",
                                         [NSNumber numberWithInt:0], @"status", nil];
            
            NSError *error;
            NSData *studentData =[NSJSONSerialization dataWithJSONObject:lectureDict options:0 error:&error];
            NSURL *url = [NSURL URLWithString:addLectureLink];
            
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
            
            [self.navigationController popToRootViewControllerAnimated:YES];
            UIAlertView *lectureSaved = [[UIAlertView alloc] initWithTitle:@"Lecture Cancelled"
                                                                   message:@"The lecture have been successfully cancelled and saved." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [lectureSaved show];
        }
    }
}

@end
