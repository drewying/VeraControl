//
//  VeraController.m
//  Home
//
//  Created by Drew Ingebretsen on 2/25/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import "ZWaveNode.h"

@implementation ZwaveNode


-(void)performAction:(NSString*)action usingService:(NSString*)service completion:(void(^)(NSURLResponse *response, NSData *data, NSError *devices))callback{
    
    //NSString *htmlString = [NSString stringWithFormat:@"http://%@:3480/data_request?id=action&output_format=json&DeviceNum=%@&serviceId=urn:upnp-org:serviceId:%@&action=%@", self.controllerIpAddress, self.identifier, service, action];
    
    NSString *htmlString = [NSString stringWithFormat:@"http://%@/data_request?id=action&output_format=json&DeviceNum=%@&serviceId=urn:upnp-org:serviceId:%@&action=%@", self.controllerUrl, self.identifier, service, action];
    
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:htmlString]] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        callback(response, data, error);
    }];
}

@end