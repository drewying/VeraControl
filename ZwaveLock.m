//
//  VeraController.m
//  Home
//
//  Created by Drew Ingebretsen on 2/25/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import "ZwaveLock.h"

@implementation ZwaveLock

#define SERVICE @"DoorLock1"

-(void)setLocked:(BOOL)locked completion:(void(^)())callback{
    [self performAction:[NSString stringWithFormat:@"SetTarget&newTargetValue=%i",(locked == YES)] usingService:SERVICE completion:^(NSURLResponse *response, NSData *data, NSError *error){
        if (callback){
            callback();
        }
    }];
}


@end