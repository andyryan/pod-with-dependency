//
//  ObjCHelper.m
//  Echo
//
//  Created by Adam Price - myBBC on 16/06/2016.
//  Copyright © 2016 BBC. All rights reserved.
//

#import "ObjCHelper.h"

@implementation ObjCHelper

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error {
    @try {
        tryBlock();
        return YES;
    }
    @catch (NSException *exception) {
        *error = [[NSError alloc] initWithDomain:exception.name code:0 userInfo:exception.userInfo];
    }
}

@end
