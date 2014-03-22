//
//  SQLQueries.m
//  Attendance Monitor
//
//  Created by Myles Ringle on 22/03/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import "SQLQueries.h"
#import "FaceAnalyser.hh"

@interface SQLQueries () {
    FaceAnalyser *faceAnalyser;
}

@end

@implementation SQLQueries

- (int) getUserID:(NSString *) username {
    
    int userID;
    
    // Get the user ID of the new user
    const char *getUserIDSQL = [[NSString stringWithFormat:@"SELECT id FROM people WHERE username = \"%@\"", username]
                                cStringUsingEncoding:NSUTF8StringEncoding];
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2([faceAnalyser database], getUserIDSQL, -1, &statement, nil) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            userID = [[NSNumber numberWithInt:sqlite3_column_int(statement, 0)] intValue];
        }
    }
    sqlite3_finalize(statement);
    
    return userID;
}

@end
