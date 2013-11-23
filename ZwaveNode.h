//
//  ZWaveNode.h
//  Home
//
//  Created by Drew Ingebretsen on 5/21/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZwaveNode : NSObject
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *controllerUrl;
@property (nonatomic, strong) NSString *veraDeviceFileName;

-(void)performAction:(NSString*)action usingService:(NSString*)service completion:(void(^)(NSURLResponse *response, NSData *data, NSError *devices))callback;

-(void)getDeviceTriggers:(void(^)(NSArray *triggers))callback;
    
@end
