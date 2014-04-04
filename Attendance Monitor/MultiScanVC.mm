//
//  MultiScanVC.m
//  Attendance Monitor
//
//  Created by Myles Ringle on 04/04/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import "MultiScanVC.h"
#import "FaceAnalyser.hh"

static NSString *getImagesLink = @"http://livattend.tk/get_images.php";
static NSString *getStudentsLink = @"http://livattend.tk/get_students_for_module.php";

@interface MultiScanVC () {
    UIActivityIndicatorView *activityView;
    UIAlertView *instructionAlert;
    UIAlertView *attendanceRecorded;
    
    int currentFrame;
    int imagesTaken;
    int badFacePosition;
    
    BOOL modelTrainPassed;
    
    cv::CascadeClassifier faceCascade;
    cv::Ptr<cv::FaceRecognizer> model;
    
    UIImageView *overlayImageView;
    
    UIAlertView *downloadFailedAlert;
    UIAlertView *badPositionAlert;
    BOOL badPositionAlertVisible;
    UIAlertView *captureCompleteAlert;
    
    FaceAnalyser *faceAnalyser;
    
    int matches;
}

@property (strong, nonatomic) NSMutableArray *imageArray;
@property (assign, nonatomic) NSString *fullname;
@property (assign, nonatomic) int studentID;

@property (assign, nonatomic) BOOL recordSuccessful;
@property (strong, nonatomic) NSMutableArray *studentList;
@property (assign, nonatomic) BOOL downloadInProgress;
@property (assign, nonatomic) BOOL downloadFailed;

@property (strong, nonatomic) NSMutableDictionary *studentDetails;

@end

@implementation MultiScanVC

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self.navigationItem setHidesBackButton:YES];
    [[[[[[self navigationController] tabBarController] tabBar] items] objectAtIndex:0] setEnabled:NO];
    [[[[[[self navigationController] tabBarController] tabBar] items] objectAtIndex:1] setEnabled:NO];
    [[self doneButton] setEnabled:NO];
    
    self.name.text = @"";
    self.confidence.text = @"";
    
    [self setupModel];
    [self getStudentList];
    [self downloadData];
}

- (void) viewDidAppear:(BOOL)animated {
    imagesTaken = 1;
    badFacePosition = 0;
    matches = 0;
    badPositionAlertVisible = NO;
    modelTrainPassed = NO;
    [self setRecordSuccessful:NO];
    
    [self addLoadingSpinner];
    
    faceAnalyser = [[FaceAnalyser alloc] init];
    
}

- (void) viewDidDisappear:(BOOL)animated {
    // REMOVE OVERLAY
    [[self camera3] stop];
    [overlayImageView removeFromSuperview];
    self.name.text = @"";
    self.confidence.text = @"";
}

- (void) addLoadingSpinner {
    
    activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [activityView setColor:[UIColor grayColor]];
    
    activityView.center = CGPointMake(self.cameraView3.frame.size.width/2,
                                      self.cameraView3.frame.size.height/2);
    [activityView startAnimating];
    
    
    [self.cameraView3 addSubview:activityView];
}

- (void) removeLoadingSpinner {
    [activityView stopAnimating];
    [activityView removeFromSuperview];
}

- (void)setupModel {
    
    model = cv::createLBPHFaceRecognizer();
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
    }
}

- (void)downloadData {
    
    // Create the thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Generate the URL request for the JSON data
        NSURL *url = [NSURL URLWithString:getImagesLink];
        NSError *error;
        
        NSData *data = [NSData dataWithContentsOfURL:url options:kNilOptions error:&error];
        [self performSelectorOnMainThread:@selector(fetchedImageArray:) withObject:data waitUntilDone:YES];
    });
}

- (void) fetchedImageArray:(NSData *) data {
    
    // Check if the download was interrupted or failed.
    // If so, display an error alert and instruct the user accordingly.
    if (data == nil) {
        [self removeLoadingSpinner];
        downloadFailedAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                         message:@"Failed to download student list.\nPlease check your network connection or push retry to try again." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Retry", nil];
        [downloadFailedAlert show];
    }
    // Otherwise, the download was successful.
    else {
        NSError *error;
        
        // Note that we are not calling the setter method here... as this would be recursive!!!
        _imageArray = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        
        // Reset the download property, as we have now finished the download.
        // [self setDownloadInProgress:NO];
        
        // Check again to make sure the download has completely finished.
        if (_imageArray != nil) {
            
            // ****************************************************************************************************************
            // End the refresh animation of the refresh control.
            // [[self refreshControl] endRefreshing];
            [self removeLoadingSpinner];
            
            [self downloadComplete];
            [[self doneButton] setEnabled:YES];
        }
        else {
            [self removeLoadingSpinner];
            instructionAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                          message:@"No facial data for the selected student." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [instructionAlert show];
        }
    }
}

- (void)downloadComplete {
    
    // TRAIN THE MODEL
    std::vector<cv::Mat> images;
    std::vector<int> labels;
    
    for (int i = 0; i < [[self imageArray] count]; i++) {
        NSDictionary *imageDict = [[self imageArray] objectAtIndex:i];
        
        int studentID = [[imageDict objectForKey:@"user_id"] intValue];
        
        // Pull out the image into NSData
        NSString *theString = [imageDict objectForKey:@"image"];
        NSData *imageData = [[NSData alloc] initWithBase64EncodedString:theString
                                                                options:kNilOptions];
        
        
        // Then convert NSData to a cv::Mat. Images are standardized into 100x100
        cv::Mat faceData = cv::Mat(400, 400, CV_8UC1);
        faceData.data = (unsigned char*)imageData.bytes;
        
        // Put this image into the model
        images.push_back(faceData);
        labels.push_back(studentID);
    }
    
    
    if (images.size() > 0 && labels.size() > 0) {
        model->train(images, labels);
        modelTrainPassed = YES;
    }
    else {
        printf("********* MODEL TRAIN FAILED *************");
    }
    [self setupCamera];
}

- (void) setupCamera {
    [self setCamera3: [[CvVideoCamera alloc] initWithParentView:[self cameraView3]]];
    [[self camera3] setDelegate:self];
    [[self camera3] setDefaultAVCaptureDevicePosition:AVCaptureDevicePositionFront];
    [[self camera3] setDefaultAVCaptureSessionPreset:AVCaptureSessionPreset640x480];
    [[self camera3] setDefaultAVCaptureVideoOrientation:AVCaptureVideoOrientationPortrait];
    [[self camera3] setDefaultFPS:30];
    [[self camera3] setGrayscaleMode:NO];
    [[self camera3] start];
    
    overlayImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.cameraView3.bounds.size.width,
                                                                     self.cameraView3.bounds.size.height)];
    overlayImageView.image = [UIImage imageNamed:@"Overlay-NoFace.png"];
    [self.cameraView3 addSubview:overlayImageView];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)processImage:(cv::Mat&)image
{
    if (currentFrame == 20) {
        
        if (badPositionAlertVisible == NO) {
            
            int isFaceDetected = [faceAnalyser detectFace:image];
            
            if (isFaceDetected == 0) {
                // No face detected
                dispatch_sync(dispatch_get_main_queue(), ^{
                    self.name.text = @"No face detected";
                    self.confidence.text = @"N/A";
                    
                    overlayImageView.image = [UIImage imageNamed:@"Overlay-NoFace.png"];
                });
            }
            else if (isFaceDetected == 1) {
                // Face is not positioned correctly
                dispatch_sync(dispatch_get_main_queue(), ^{
                    self.name.text = @"Bad face position";
                    self.confidence.text = @"N/A";
                    
                    overlayImageView.image = [UIImage imageNamed:@"Overlay-NoFace.png"];
                    
                    badFacePosition++;
                    if (badFacePosition == 15) {
                        badPositionAlert = [[UIAlertView alloc] initWithTitle:@"Bad Face Positioning"
                                                                      message:@"Please align your face with so that it fully fills the red bordered view."
                                                                     delegate:self
                                                            cancelButtonTitle:nil
                                                            otherButtonTitles:@"OK", nil];
                        [badPositionAlert show];
                        badPositionAlertVisible = YES;
                        
                    }
                });
            }
            else if (isFaceDetected == 2) {
                // Face is detected and has good positioning
                dispatch_sync(dispatch_get_main_queue(), ^{
                    overlayImageView.image = [UIImage imageNamed:@"Overlay-Face.png"];
                });
                
                badFacePosition = 0;
                
                NSString *message = @"No match found";
                NSString *confidenceLabelString = @"";
                
                // Unless the database is empty, try a match
                if (modelTrainPassed == YES) {
                    
                    cv::Mat croppedFace = [faceAnalyser getCroppedFace];
                    
                    int predictedLabel = -1;
                    double confidence = 0.0;
                    
                    model->predict(croppedFace, predictedLabel, confidence);

                    if (confidence < 28) {
                        NSString *personName = @"";
                        
                        // If a match was found, lookup the person's name
                        if (predictedLabel != -1) {
                            for (int i = 0; i < [[self studentList] count]; i++) {
                                NSDictionary *temp = [[self studentList] objectAtIndex:i];
                                if ([[temp objectForKey:@"id"] intValue] == predictedLabel) {
                                    personName = [temp objectForKey:@"fullname"];
                                }
                            }
                        }
                        
                        NSDictionary *match = @{
                                                @"personID": [NSNumber numberWithInt:predictedLabel],
                                                @"personName": personName,
                                                @"confidence": [NSNumber numberWithDouble:confidence]
                                                };
                        
                        // Match found
                        if ([match objectForKey:@"personID"] != [NSNumber numberWithInt:-1]) {
                            
                            message = [match objectForKey:@"personName"];
                            [self setStudentID:[[match objectForKey:@"personID"] intValue]];
                            
                            NSNumberFormatter *confidenceFormatter = [[NSNumberFormatter alloc] init];
                            [confidenceFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
                            confidenceFormatter.maximumFractionDigits = 0;
                            
                            confidenceLabelString = [NSString stringWithFormat:@"%@",
                                                     [confidenceFormatter stringFromNumber:[match objectForKey:@"confidence"]]];
                            
                            matches++;
                        }
                    }
                    
                }
                
                // All changes to the UI have to happen on the main thread
                dispatch_sync(dispatch_get_main_queue(), ^{
                    if (matches > 3) {
                        for (int i = 0; i < [[self studentList] count]; i++) {
                            if ([[[[self studentList] objectAtIndex:i] objectForKey:@"id"] intValue] == [self studentID]) {
                                [self setStudentDetails:[[self studentList] objectAtIndex:i]];
                                break;
                            }
                        }
                        
                        [[self studentDetails] setObject:[NSNumber numberWithInt:1] forKey:@"status"];
                        [self recognisedUser:[self studentID]];
                        matches = 0;
                    }
                    else {
                        self.name.text = message;
                        self.confidence.text = confidenceLabelString;
                    }
                });
                
            }
        }
        currentFrame = 1;
    }
    else {
        currentFrame++;
    }
}

- (void) recognisedUser:(int)userID {
    [[self camera3] stop];
    [overlayImageView removeFromSuperview];
    self.confidence.text = @"";
    
    for (int i = 0; i < [[self imageArray] count]; i++) {
        NSDictionary *imageDict = [[self imageArray] objectAtIndex:i];
        
        if ([[imageDict objectForKey:@"user_id"] intValue] == userID) {
            [[self imageArray] removeObjectAtIndex:i];
        }
    }
    
    attendanceRecorded = [[UIAlertView alloc] initWithTitle:self.name.text
                                                                 message:@"Your attendance has been successfully recorded.\nPlease pass the device to the next person." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [attendanceRecorded show];
    
    self.name.text = @"";

}

// Prepare to move to new view
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"finishAttendanceMonitor2"]) {
        
        [[segue destinationViewController] setReceivedModuleID:[self receivedModuleID]];
        [[segue destinationViewController] setReceivedLectureID:[self receivedLectureID]];
        [[segue destinationViewController] setStudentList:[self studentList]];
        
    }
}

//==============================================================================
#pragma mark - Error Handling
//==============================================================================

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView == badPositionAlert) {
        if (buttonIndex == 0) {
            badFacePosition = 0;
            badPositionAlertVisible = NO;
        }
    }
    if (alertView == instructionAlert) {
        if (buttonIndex == 0) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    if (alertView == attendanceRecorded) {
        if (buttonIndex == 0) {
            [self downloadComplete];
        }
    }
    
}

@end
