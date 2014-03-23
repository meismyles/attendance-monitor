//
//  ScanVC.mm
//  Attendance Monitor
//
//  Created by Myles Ringle on 22/02/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import "ScanVC.h"
#import "FaceAnalyser.hh"

@interface ScanVC () {
    int currentFrame;
    int imagesTaken;
    int badFacePosition;
    
    BOOL modelTrainPassed;
    
    cv::CascadeClassifier faceCascade;
    
    UIImageView *overlayImageView;
    
    UIAlertView *badPositionAlert;
    BOOL badPositionAlertVisible;
    UIAlertView *captureCompleteAlert;
    
    FaceAnalyser *faceAnalyser;
}

@property (assign, nonatomic) int userID;

@end

@implementation ScanVC

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    faceAnalyser = [[FaceAnalyser alloc] init];
    
    
    modelTrainPassed = NO;
    
    model = cv::createLBPHFaceRecognizer();
    
    [faceAnalyser openDatabase];
    
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
     
}

- (void)viewDidAppear:(BOOL)animated {
    
    // TRAIN THE MODEL
    std::vector<cv::Mat> images;
    std::vector<int> labels;
    
    const char* selectSQL = "SELECT person_id, image FROM images";
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2([faceAnalyser database], selectSQL, -1, &statement, nil) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            int personID = sqlite3_column_int(statement, 0);
            
            // First pull out the image into NSData
            int imageSize = sqlite3_column_bytes(statement, 1);
            NSData *imageData = [NSData dataWithBytes:sqlite3_column_blob(statement, 1) length:imageSize];
            
            // Then convert NSData to a cv::Mat. Images are standardized into 100x100
            cv::Mat faceData = cv::Mat(300, 300, CV_8UC1);
            faceData.data = (unsigned char*)imageData.bytes;
            
            // Put this image into the model
            images.push_back(faceData);
            labels.push_back(personID);
        }
    }
    
    sqlite3_finalize(statement);

    if (images.size() > 0 && labels.size() > 0) {
        model->train(images, labels);
        modelTrainPassed = YES;
    }
    else {
        printf("********* MODEL TRAIL FAILED *************");
    }

    ////////
    
    [[self camera] start];

    overlayImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.cameraView.bounds.size.width,
                                                                     self.cameraView.bounds.size.height)];
    overlayImageView.image = [UIImage imageNamed:@"Overlay-NoFace.png"];
    [self.cameraView addSubview:overlayImageView];
}

- (void)viewWillDisappear:(BOOL)animated
{
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
                        const char* selectSQL = "SELECT username FROM people WHERE id = ?";
                        sqlite3_stmt *statement;
                        
                        if (sqlite3_prepare_v2([faceAnalyser database], selectSQL, -1, &statement, nil) == SQLITE_OK) {
                            sqlite3_bind_int(statement, 1, predictedLabel);
                            
                            if (sqlite3_step(statement) != SQLITE_DONE) {
                                personName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
                            }
                        }
                        
                        sqlite3_finalize(statement);
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
