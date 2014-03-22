//
//  FaceAnalyser.mm
//  Attendance Monitor
//
//  Created by Myles Ringle on 22/03/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import "FaceAnalyser.hh"

@implementation FaceAnalyser

- (void) openDatabase {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [paths objectAtIndex:0];
    NSString *dbPath = [documentDirectory stringByAppendingPathComponent:@"local-database.sqlite"];
    
    if (sqlite3_open([dbPath UTF8String], &_database) != SQLITE_OK) {
        NSLog(@"Cannot open the database.");
    }
}


- (void) loadFaceCascade {
    NSString *pathOfFaceCascade = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_default"
                                                                  ofType:@"xml"];

    if (!_faceCascade.load([pathOfFaceCascade UTF8String])) {
        NSLog(@"Error loading face cascade: %@", pathOfFaceCascade);
    }
}


- (std::vector<cv::Rect>) detectFace:(cv::Mat&)image {
    std::vector<cv::Rect> faces;
    _faceCascade.detectMultiScale(image, faces, 1.1, 2, CV_HAAR_FIND_BIGGEST_OBJECT | CV_HAAR_DO_ROUGH_SEARCH,
                                 cv::Size(60, 60));
    return faces;
}

@end
