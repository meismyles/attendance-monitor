//
//  FaceAnalyser.mm
//  Attendance Monitor
//
//  Created by Myles Ringle on 22/03/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import "FaceAnalyser.hh"

@implementation FaceAnalyser

- (id)init
{
    self = [super init];
    if (self) {
        NSString *pathOfFaceCascade = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_default"
                                                                      ofType:@"xml"];
        if (!faceCascade.load([pathOfFaceCascade UTF8String])) {
            NSLog(@"Error loading face cascade: %@", pathOfFaceCascade);
        }
    }
    
    return self;
}


//////////////////////

- (cv::Mat) getCroppedFace {
    return croppedFace;
}

//////////////////////

- (int) detectFace:(cv::Mat&)image {
    
    std::vector<cv::Rect> faces;
    
    faceCascade.detectMultiScale(image, faces, 1.1, 2, CV_HAAR_FIND_BIGGEST_OBJECT | CV_HAAR_DO_ROUGH_SEARCH, cv::Size(60, 60));
    
    
    if (faces.size() != 1) {
        // No face detected
        return 0;
    }
    else {
        // We only care about the first face
        cv::Rect face = faces[0];
        
        int faceWidth = face.width;
        int faceHeight = face.height;
        
        // X: 25-50
        // Y: 150-225
        // Width: 380-410
        // Height: 380-410
        if (((face.x >= 25) && (face.x <= 50)) && ((face.y >= 150) && (face.y <= 225)) &&
            ((faceWidth >= 380) && (faceWidth <= 410)) && ((faceHeight >= 380) && (faceHeight <= 410))) {
            // Face detected and good position
            
            // LEARNING THE FACE
            // Crop the image to just the face
            cv::Mat tempCroppedFace;
            cv::cvtColor(image(face), tempCroppedFace, CV_RGB2GRAY);
            cv::resize(tempCroppedFace, tempCroppedFace, cv::Size(400, 400), 1.0, 1.0, cv::INTER_CUBIC);
            croppedFace = tempCroppedFace;
            
            return 2;
        }
        else {
            // Face detected but bad positioning
            return 1;
        }
    }
}

@end
