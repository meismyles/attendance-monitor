//
//  ScanVC.h
//  Attendance Monitor
//
//  Created by Myles Ringle on 22/02/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>
#import <opencv2/highgui/cap_ios.h>
#import <opencv2/objdetect/objdetect.hpp>
#import <opencv2/imgproc/imgproc.hpp>
#import <opencv2/contrib/contrib.hpp>

@interface ScanVC : UIViewController <CvVideoCameraDelegate> {

    cv::Ptr<cv::FaceRecognizer> model;
}

@property (strong, nonatomic) IBOutlet UIImageView *cameraView;
@property (nonatomic, retain) IBOutlet CvVideoCamera *camera;
@property (strong, nonatomic) IBOutlet UILabel *confidence;
@property (strong, nonatomic) IBOutlet UILabel *name;
@property (strong, nonatomic) NSString *username;


@property (strong, nonatomic) IBOutlet UILabel *test;


@end
