//
//  CaptureImagesVC.mm
//  Attendance Monitor
//
//  Created by Myles Ringle on 22/02/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import "CaptureImagesVC.h"
#import "FaceAnalyser.hh"

static NSString *getUserIDLink = @"http://project.waroftoday.com/get_user_id.php";
static NSString *addImageLink = @"http://project.waroftoday.com/add_images.php";

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
    imagesTaken = 0;
    badFacePosition = 0;
    badPositionAlertVisible = NO;
    
    
    // Allocate main faceAnalyser
    faceAnalyser = [[FaceAnalyser alloc] init];
    
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
    
    NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString *responseData = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
    [self setUserID:[responseData intValue]];
    
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
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            if (badPositionAlertVisible == NO) {
                
                int isFaceDetected = [faceAnalyser detectFace:image];
                
                if (isFaceDetected == 0) {
                    // No face detected
                    overlayImageView.image = [UIImage imageNamed:@"Overlay-NoFace.png"];
                }
                else if (isFaceDetected == 1) {
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
                else if (isFaceDetected == 2) {
                    
                    // Face is detected and has good positioning
                    cv::Mat croppedFace = [faceAnalyser getCroppedFace];
                    
                    overlayImageView.image = [UIImage imageNamed:@"Overlay-Face.png"];
                    badFacePosition = 0;
                    
                    
                    // Create the thread
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        
                        NSData *serialized = [[NSData alloc] initWithBytes:croppedFace.data
                                                                    length:croppedFace.elemSize() * croppedFace.total()];
                        NSString *theData = [serialized base64EncodedStringWithOptions:kNilOptions];
                        
                        NSNumber *userIDConverted = [NSNumber numberWithInt:[self userID]];
                        NSDictionary *studentDict = [NSDictionary dictionaryWithObjectsAndKeys:userIDConverted, @"user_id",
                                                                                                theData, @"image", nil];
                        
                        printf("********* YOLO MOFO 2 *********");
                        NSLog(@"!!!!!!!!!!!! %@", theData);

                        
                        NSError *error;
                        NSData *studentData = [NSJSONSerialization dataWithJSONObject:studentDict options:0 error:&error];
                        NSURL *url = [NSURL URLWithString:addImageLink];
                        
                        printf("********* YOLO MOFO 3 *********");
                        
                        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
                        [request setURL:url];
                        [request setHTTPMethod:@"POST"];
                        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
                        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
                        [request setValue:[NSString stringWithFormat:@"%d", (int)studentData.length] forHTTPHeaderField:@"Content-Length"];
                        [request setHTTPBody:studentData];
                        
                        NSURLResponse *response = nil;
                        error = nil;
                        
                        printf("********* YOLO MOFO 4 *********");
                        
                        [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
                        
                        printf("********* YOLO MOFO 5 *********");

                    });
                    
                    printf("********* YOLO MOFO 6 *********");
                    
                    [[self photosTaken] setText:[NSString stringWithFormat:@"Photos taken: %d", imagesTaken++]];
                    
                    // If all images have been taken then end the learning process
                    if (imagesTaken == 15) {
                        
                        [self.navigationController popToRootViewControllerAnimated:YES];
                        
                        captureCompleteAlert = [[UIAlertView alloc] initWithTitle:@"Image Capture Complete"
                                                                        message:@"All images have been successfully captured."
                                                                       delegate:nil
                                                              cancelButtonTitle:nil
                                                              otherButtonTitles:@"OK", nil];
                        [captureCompleteAlert show];
                        
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
