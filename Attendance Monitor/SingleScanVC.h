//
//  SingleScanVC.h
//  Attendance Monitor
//
//  Created by Myles Ringle on 03/04/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/highgui/cap_ios.h>
#import <opencv2/objdetect/objdetect.hpp>
#import <opencv2/imgproc/imgproc.hpp>
#import <opencv2/contrib/contrib.hpp>

@interface SingleScanVC : UIViewController <CvVideoCameraDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *cameraView;
@property (nonatomic, retain) IBOutlet CvVideoCamera *camera;
@property (strong, nonatomic) IBOutlet UILabel *confidence;
@property (strong, nonatomic) IBOutlet UILabel *name;

@property (strong, nonatomic) NSMutableDictionary *studentDetails;


@property (strong, nonatomic) IBOutlet UILabel *test;


@end
