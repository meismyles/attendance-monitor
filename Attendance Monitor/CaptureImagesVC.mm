//
//  CaptureImagesVC.mm
//  Attendance Monitor
//
//  Created by Myles Ringle on 22/02/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import "CaptureImagesVC.h"
#import "FaceAnalyser.hh"

@interface CaptureImagesVC () {
    int currentFrame;
    int imagesTaken;
    int badFacePosition;
    
    cv::CascadeClassifier faceCascade;
    
    UIImageView *overlayImageView;
    
    UIAlertView *badPositionAlert;
    BOOL badPositionAlertVisible;
    UIAlertView *captureCompleteAlert;
    
    FaceAnalyser *faceAnalyser;
}

@property (assign, nonatomic) int userID;

@end

@implementation CaptureImagesVC

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // Variable initialization
    imagesTaken = 1;
    badFacePosition = 0;
    badPositionAlertVisible = NO;
    
    
    // Allocate main faceAnalyser
    faceAnalyser = [[FaceAnalyser alloc] init];
    
    [faceAnalyser openDatabase];

    
    // Get the user ID of the new user
    const char *getUserIDSQL = [[NSString stringWithFormat:@"SELECT id FROM people WHERE username = \"%@\"", [self username]]
                                                                            cStringUsingEncoding:NSUTF8StringEncoding];
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2([faceAnalyser database], getUserIDSQL, -1, &statement, nil) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            [self setUserID: [[NSNumber numberWithInt:sqlite3_column_int(statement, 0)] intValue]];
        }
    }
    sqlite3_finalize(statement);

    
    // Load face cascade
    [faceAnalyser loadFaceCascade];
    
    
    // Set up camera
	[self setCamera: [[CvVideoCamera alloc] initWithParentView:[self cameraView]]];
    [[self camera] setDelegate:self];
    [[self camera] setDefaultAVCaptureDevicePosition:AVCaptureDevicePositionFront];
    [[self camera] setDefaultAVCaptureSessionPreset:AVCaptureSessionPreset640x480];
    [[self camera] setDefaultAVCaptureVideoOrientation:AVCaptureVideoOrientationPortrait];
    [[self camera] setDefaultFPS:30];
    [[self camera] setGrayscaleMode:NO];
    [[self camera] start];
    
    
    // Set up camera overlay
    overlayImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.cameraView.bounds.size.width,
                                                                                        self.cameraView.bounds.size.height)];
    overlayImageView.image = [UIImage imageNamed:@"Overlay-NoFace.png"];
    [self.cameraView addSubview:overlayImageView];
     
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)processImage:(cv::Mat&)image
{
    if (currentFrame == 20) {
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            std::vector<cv::Rect> faces;
            faceCascade.detectMultiScale(image, faces, 1.1, 2, CV_HAAR_FIND_BIGGEST_OBJECT | CV_HAAR_DO_ROUGH_SEARCH,
                                                                                                            cv::Size(60, 60));
            
            if (faces.size() != 1) {
                // No face detected
                overlayImageView.image = [UIImage imageNamed:@"Overlay-NoFace.png"];
            }
            else {
                // We only care about the first face
                cv::Rect face = faces[0];
                
                [[self test] setText: [NSString stringWithFormat: @"%d * %d", face.x, face.y]];
                
                int faceWidth = face.width;
                int faceHeight = face.height;
                
                // X: 25-50
                // Y: 150-225
                // Width: 380-410
                // Height: 380-410
                if (((face.x >= 25) && (face.x <= 50)) && ((face.y >= 150) && (face.y <= 225)) &&
                    ((faceWidth >= 380) && (faceWidth <= 410)) && ((faceHeight >= 380) && (faceHeight <= 410)) &&
                        (badPositionAlertVisible == NO)) {
                
                    
                    overlayImageView.image = [UIImage imageNamed:@"Overlay-Face.png"];
                    badFacePosition = 0;
                    //rectangle(image, face, CV_RGB(0, 255,0), 3);

                    
                    // Learn it
                    // Pull the grayscale face ROI out of the captured image
                    cv::Mat croppedFace;
                    cv::cvtColor(image(face), croppedFace, CV_RGB2GRAY);
                    
                    // Standardize the face to 100x100 pixels
                    cv::resize(croppedFace, croppedFace, cv::Size(300, 300), 1.0, 1.0, cv::INTER_CUBIC);
                    
                    NSData *serialized = [[NSData alloc] initWithBytes:croppedFace.data length:croppedFace.elemSize() * croppedFace.total()];;
                    
                    const char* insertSQL = "INSERT INTO images (person_id, image) VALUES (?, ?)";
                    sqlite3_stmt *statement;
                    
                    if (sqlite3_prepare_v2([faceAnalyser database], insertSQL, -1, &statement, nil) == SQLITE_OK) {
                        sqlite3_bind_int(statement, 1, [self userID]);
                        sqlite3_bind_blob(statement, 2, serialized.bytes, (int)serialized.length, SQLITE_TRANSIENT);
                        sqlite3_step(statement);
                    }
                    
                    sqlite3_finalize(statement);
                    
                    
                    [[self photosTaken] setText:[NSString stringWithFormat:@"Photos taken: %d", imagesTaken++]];
                    
                    if (imagesTaken == 15) {
                        
                        [[self camera] stop];
                        sqlite3_close([faceAnalyser database]);
                        [self.navigationController popViewControllerAnimated:YES];
                        
                        captureCompleteAlert = [[UIAlertView alloc] initWithTitle:@"Image Capture Complete"
                                                                        message:@"All images have been successfully captured."
                                                                       delegate:nil
                                                              cancelButtonTitle:nil
                                                              otherButtonTitles:@"OK", nil];
                        [captureCompleteAlert show];
                        
                    }
                    
                }
                else {
                    // Face is not positioned correctly
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
                }
            }
            
            currentFrame = 1;
        });
        
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
