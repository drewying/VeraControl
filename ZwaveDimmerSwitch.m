//
//  VeraController.m
//  Home
//
//  Created by Drew Ingebretsen on 2/25/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import "ZwaveDimmerSwitch.h"

#define SERVICE @"Dimming1"

@implementation ZwaveDimmerSwitch

-(void)setBrightness:(NSInteger)brightness completion:(void(^)())callback{
    [self performAction:[NSString stringWithFormat:@"SetLoadLevelTarget&newLoadlevelTarget=%i",brightness] usingService:SERVICE completion:^(NSURLResponse *response, NSData *data, NSError *error){
        self.brightness = brightness;
        if (callback){
            callback();
        }
    }];
}


@end