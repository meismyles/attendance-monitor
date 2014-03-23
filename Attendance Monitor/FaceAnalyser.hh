//
//  FaceAnalyser.h
//  Attendance Monitor
//
//  Created by Myles Ringle on 22/03/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <sqlite3.h>
#import <opencv2/highgui/cap_ios.h>
#import <opencv2/objdetect/objdetect.hpp>
#import <opencv2/imgproc/imgproc.hpp>

@interface FaceAnalyser : NSObject {
    cv::CascadeClassifier faceCascade;
    cv::Mat croppedFace;
}

@property (assign, nonatomic) sqlite3 *database;

- (cv::Mat) getCroppedFace;

- (void) openDatabase;
- (int) detectFace:(cv::Mat&)image;

@end
