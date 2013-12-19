//
//  VeraScene.m
//  Home
//
//  Created by Drew Ingebretsen on 11/14/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import "VeraScene.h"

@implementation VeraScene

-(VeraScene*)initWithDictionary:(NSDictionary*)dictionary{
    self = [super init];
    if (self){
        self.identifier = [NSString stringWithFormat:@"%i", [dictionary[@"id"] integerValue]];
        self.name = dictionary[@"name"];
    }
    return self;
}

-(void)runScene:(void(^)())callback{
    NSString *htmlString = [NSString stringWithFormat:@"%@/data_request?id=action&output_format=json&serviceId=urn:micasaverde-com:serviceId:HomeAutomationGateway1&action=RunScene&SceneNum=%@", self.controllerUrl, self.identifier];
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:htmlString]] queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        if (callback){
            callback();
        }
    }];
}

@end
