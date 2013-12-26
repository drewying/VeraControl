//
//  VeraController.m
//  Home
//
//  Created by Drew Ingebretsen on 2/25/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import "ZWaveNode.h"

@implementation ZwaveNode

-(id)initWithDictionary:(NSDictionary*)dictionary{
    self = [super init];
    if (self){
        self.identifier = dictionary[@"id"];
        [self updateWithDictionary:dictionary];
    }
    return self;
}

-(void)updateWithDictionary:(NSDictionary *)dictionary {
    self.name = dictionary[@"name"];
    self.veraDeviceFileName = [dictionary[@"device_file"] stringByReplacingOccurrencesOfString:@"xml" withString:@"json"];
    self.room = dictionary[@"room"];
}

-(void)performAction:(NSString*)action usingService:(NSString*)service completion:(void(^)(NSURLResponse *response, NSData *data, NSError *devices))callback{
    
    NSString *htmlString = [NSString stringWithFormat:@"%@/data_request?id=action&output_format=json&DeviceNum=%@&serviceId=%@&action=%@", self.controllerUrl, self.identifier, service, action];
    
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:htmlString]] queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        if (callback){
            callback(response, data, error);
        }
    }];
}

-(void)getDeviceFileInformation:(void(^)(NSDictionary *deviceInfo))callback{
    NSString *htmlString = [NSString stringWithFormat:@"%@/data_request?id=file&parameters=%@", self.controllerUrl, self.veraDeviceFileName];
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:htmlString]] queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        callback(dict);
    }];
    
}

-(void)getDeviceTriggers:(void(^)(NSArray *triggers))callback{
    [self getDeviceFileInformation:^(NSDictionary *deviceInformation){
        NSArray *array = @[];
        for (NSDictionary *dict in deviceInformation[@"eventList2"]){
            array = [array arrayByAddingObject:dict];
        }
        callback(array);
    }];
    
}

@end