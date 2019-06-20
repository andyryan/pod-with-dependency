//
//  ObjCHelper.h
//  Echo
//
//  Created by Adam Price - myBBC on 16/06/2016.
//  Copyright © 2016 BBC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ObjCHelper : NSObject

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error;

@end
