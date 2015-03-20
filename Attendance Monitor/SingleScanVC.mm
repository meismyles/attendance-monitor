//
//  SingleScanVC.mm
//  Attendance Monitor
//
//  Created by Myles Ringle on 03/04/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import "SingleScanVC.h"
#import "FaceAnalyser.hh"

static NSString *getImagesLink = @"http://livattend.tk/get_images_for_student.php";

@interface SingleScanVC () {
    UIActivityIndicatorView *activityView;
    UIAlertView *instructionAlert;
    
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

@property (strong, nonatomic) NSArray *imageArray;
@property (assign, nonatomic) NSString *fullname;
@property (assign, nonatomic) int studentID;

@property (assign, nonatomic) BOOL recordSuccessful;

@end

@implementation SingleScanVC

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self setStudentID:[[[self studentDetails] objectForKey:@"id"] intValue]];
    [self setFullname:[[self studentDetails] objectForKey:@"fullname"]];
    
    self.name.text = @"";
    self.confidence.text = @"";
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
    
    [self setupModel];
    [self downloadData];
}

- (void) viewDidDisappear:(BOOL)animated {
    // REMOVE OVERLAY
    [[self camera2] stop];
    [overlayImageView removeFromSuperview];
    self.name.text = @"";
    self.confidence.text = @"";
    
    if ([self recordSuccessful] == YES) {
        UIAlertView *attendanceRecorded = [[UIAlertView alloc] initWithTitle:@"Attendance Recorded"
                                                                     message:@"Your attendance has been successfully recorded.\nPlease pass the device to the next person." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [attendanceRecorded show];
    }
}

- (void) addLoadingSpinner {
    
    activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [activityView setColor:[UIColor grayColor]];
    
    activityView.center = CGPointMake(self.cameraView2.frame.size.width/2,
                                      self.cameraView2.frame.size.height/2);
    [activityView startAnimating];
    
    
    [self.cameraView2 addSubview:activityView];
}

- (void) removeLoadingSpinner {
    [activityView stopAnimating];
    [activityView removeFromSuperview];
}

- (void)setupModel {
    
    model = cv::createLBPHFaceRecognizer();
}

- (void)downloadData {
    
    // Create the thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ///////////
        // NOT NEEDED RIGHT NOW - POSTING DATA FOR NO REASON
        NSDictionary *studentDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:[self studentID]], @"studentID", nil];

        NSError *error;
        NSData *studentData =[NSJSONSerialization dataWithJSONObject:studentDict options:0 error:&error];
        NSURL *url = [NSURL URLWithString:getImagesLink];
        
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
        _imageArray = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        
        // Reset the download property, as we have now finished the download.
        // [self setDownloadInProgress:NO];
        
        // Check again to make sure the download has completely finished.
        if (_imageArray != nil) {
            
            // ****************************************************************************************************************
            // End the refresh animation of the refresh control.
            // [[self refreshControl] endRefreshing];
            [self removeLoadingSpinner];
            
            [self downloadComplete];
            
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
        
        // Pull out the image into NSData
        NSString *theString = [imageDict objectForKey:@"image"];
        NSData *imageData = [[NSData alloc] initWithBase64EncodedString:theString
                                                                options:kNilOptions];
        
        
        // Then convert NSData to a cv::Mat. Images are standardized into 100x100
        cv::Mat faceData = cv::Mat(400, 400, CV_8UC1);
        faceData.data = (unsigned char*)imageData.bytes;
        
        // Put this image into the model
        images.push_back(faceData);
        labels.push_back([self studentID]);
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
    [self setCamera2: [[CvVideoCamera alloc] initWithParentView:[self cameraView2]]];
    [[self camera2] setDelegate:self];
    [[self camera2] setDefaultAVCaptureDevicePosition:AVCaptureDevicePositionFront];
    [[self camera2] setDefaultAVCaptureSessionPreset:AVCaptureSessionPreset640x480];
    [[self camera2] setDefaultAVCaptureVideoOrientation:AVCaptureVideoOrientationPortrait];
    [[self camera2] setDefaultFPS:30];
    [[self camera2] setGrayscaleMode:NO];
    [[self camera2] start];
    
    overlayImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.cameraView2.bounds.size.width,
                                                                     self.cameraView2.bounds.size.height)];
    overlayImageView.image = [UIImage imageNamed:@"Overlay-NoFace.png"];
    [self.cameraView2 addSubview:overlayImageView];
    
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
                            personName = [self fullname];
                        }
                        
                        NSDictionary *match = @{
                                                @"personID": [NSNumber numberWithInt:predictedLabel],
                                                @"personName": personName,
                                                @"confidence": [NSNumber numberWithDouble:confidence]
                                                };
                        
                        // Match found
                        if ([match objectForKey:@"personID"] != [NSNumber numberWithInt:-1]) {
                            
                            message = [match objectForKey:@"personName"];
                            
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
                        [[self studentDetails] setObject:[NSNumber numberWithInt:1] forKey:@"status"];
                        [self setRecordSuccessful:YES];
                        [self.navigationController popViewControllerAnimated:YES];
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
    
}

@end
