//
//  MultiScanVC.h
//  Attendance Monitor
//
//  Created by Myles Ringle on 04/04/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/highgui/cap_ios.h>
#import <opencv2/objdetect/objdetect.hpp>
#import <opencv2/imgproc/imgproc.hpp>
#import <opencv2/contrib/contrib.hpp>

@interface MultiScanVC : UIViewController <CvVideoCameraDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *cameraView3;
@property (nonatomic, retain) IBOutlet CvVideoCamera *camera3;
@property (strong, nonatomic) IBOutlet UILabel *confidence;
@property (strong, nonatomic) IBOutlet UILabel *name;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *doneButton;

@property (assign, nonatomic) int receivedModuleID;
@property (assign, nonatomic) int receivedLectureID;
@property (strong, nonatomic) NSString *receivedModuleCode;

@end