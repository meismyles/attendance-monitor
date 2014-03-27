//
//  ScanVC.mm
//  Attendance Monitor
//
//  Created by Myles Ringle on 22/02/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import "ScanVC.h"
#import "FaceAnalyser.hh"

static NSString *getUserIDLink = @"http://project.waroftoday.com/get_images.php";

@interface ScanVC () {
    int currentFrame;
    int imagesTaken;
    int badFacePosition;
    
    BOOL modelTrainPassed;
    
    cv::CascadeClassifier faceCascade;
    
    UIImageView *overlayImageView;
    
    UIAlertView *downloadFailedAlert;
    UIAlertView *badPositionAlert;
    BOOL badPositionAlertVisible;
    UIAlertView *captureCompleteAlert;
    
    FaceAnalyser *faceAnalyser;
}

@property (assign, nonatomic) int userID;
@property (strong, nonatomic) NSArray *imageArray;

@end

@implementation ScanVC

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    faceAnalyser = [[FaceAnalyser alloc] init];
    
    
    modelTrainPassed = NO;
    
    model = cv::createLBPHFaceRecognizer();
        
    imagesTaken = 1;
    badFacePosition = 0;
    badPositionAlertVisible = NO;
    
	[self setCamera: [[CvVideoCamera alloc] initWithParentView:[self cameraView]]];
    [[self camera] setDelegate:self];
    [[self camera] setDefaultAVCaptureDevicePosition:AVCaptureDevicePositionFront];
    [[self camera] setDefaultAVCaptureSessionPreset:AVCaptureSessionPreset640x480];
    [[self camera] setDefaultAVCaptureVideoOrientation:AVCaptureVideoOrientationPortrait];
    [[self camera] setDefaultFPS:30];
    [[self camera] setGrayscaleMode:NO];
    
    ///////////
    // NOT NEEDED RIGHT NOW - POSTING DATA FOR NO REASON
    NSDictionary *studentDict = [NSDictionary dictionaryWithObjectsAndKeys:[self username], @"username", nil];
    
    NSError *error;
    NSData *studentData =[NSJSONSerialization dataWithJSONObject:studentDict options:0 error:&error];
    NSURL *url = [NSURL URLWithString:getUserIDLink];
    
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
    
    ///////////
    
}

- (void) fetchedImageArray:(NSData *) data {
    
    // Check if the download was interrupted or failed.
    // If so, display an error alert and instruct the user accordingly.
    if (data == nil) {
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
            
            [self downloadComplete];
            
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
        NSString *imageString = [imageDict objectForKey:@"image"];
        NSData *imageData = [[NSData alloc] initWithBase64EncodedString:imageString options:NSDataBase64DecodingIgnoreUnknownCharacters];
        NSLog(@"!!!!!!!!!!!! %@", imageData);

        
        // Then convert NSData to a cv::Mat. Images are standardized into 100x100
        cv::Mat faceData = cv::Mat(300, 300, CV_8UC1);
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
    
    ////////
    
    [[self camera] start];

    overlayImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.cameraView.bounds.size.width,
                                                                     self.cameraView.bounds.size.height)];
    overlayImageView.image = [UIImage imageNamed:@"Overlay-NoFace.png"];
    [self.cameraView addSubview:overlayImageView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[self camera] stop];
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
                    
                    NSString *personName = @"";
                    
                    // If a match was found, lookup the person's name
                    if (predictedLabel != -1) {
                        NSNumber *predictedUserID = [NSNumber numberWithInt:predictedLabel];
                        NSDictionary *studentDict = [NSDictionary dictionaryWithObjectsAndKeys:predictedUserID, @"user_id", nil];
                        
                        NSError *error;
                        NSData *studentData =[NSJSONSerialization dataWithJSONObject:studentDict options:0 error:&error];
                        NSURL *url = [NSURL URLWithString:getUserIDLink];
                        
                        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
                        [request setURL:url];
                        [request setHTTPMethod:@"POST"];
                        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
                        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
                        [request setValue:[NSString stringWithFormat:@"%d", (int)studentData.length] forHTTPHeaderField:@"Content-Length"];
                        [request setHTTPBody:studentData];
                        
                        NSURLResponse *response = nil;
                        error = nil;
                        
                        NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
                        personName = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                    }
                    
                    NSDictionary *match = @{
                             @"personID": [NSNumber numberWithInt:predictedLabel],
                             @"personName": personName,
                             @"confidence": [NSNumber numberWithDouble:confidence]
                             };
                    
                    // Match found
                    if ([match objectForKey:@"personID"] != [NSNumber numberWithInt:-1]) {
                        int confidenceNumber = [[match objectForKey:@"confidence"] intValue];
                        if (confidenceNumber <= 1500) {
                            
                            message = [match objectForKey:@"personName"];
                            
                            NSNumberFormatter *confidenceFormatter = [[NSNumberFormatter alloc] init];
                            [confidenceFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
                            confidenceFormatter.maximumFractionDigits = 0;
                            
                            confidenceLabelString = [NSString stringWithFormat:@"%@",
                                          [confidenceFormatter stringFromNumber:[match objectForKey:@"confidence"]]];
                        }
                    }

                
                }
                
                // All changes to the UI have to happen on the main thread
                dispatch_sync(dispatch_get_main_queue(), ^{
                    self.name.text = message;
                    self.confidence.text = confidenceLabelString;
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

}

@end
