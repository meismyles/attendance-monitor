//
//  CaptureImagesVC.h
//  Attendance Monitor
//
//  Created by Myles Ringle on 22/02/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/highgui/cap_ios.h>
#import <opencv2/objdetect/objdetect.hpp>
#import <opencv2/imgproc/imgproc.hpp>

@interface CaptureImagesVC : UIViewController <CvVideoCameraDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *cameraView;
@property (nonatomic, retain) IBOutlet CvVideoCamera *camera;
@property (strong, nonatomic) IBOutlet UILabel *photosTaken;
@property (strong, nonatomic) NSString *username;


@property (strong, nonatomic) IBOutlet UILabel *test;

@end
