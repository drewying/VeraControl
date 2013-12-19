//
//  VeraSceneTrigger.m
//  C2
//
//  Created by Drew Ingebretsen on 9/22/13.
//  Copyright (c) 2013 People Tech. All rights reserved.
//

#import "VeraSceneTrigger.h"

#define UPNP_SERVICE_SCENE @"urn:micasaverde-com:serviceId:HomeAutomationGateway1"

//Sample request - http://ip_address:3480/data_request?id=lu_action&serviceId=urn:micasaverde-com:serviceId:HomeAutomationGateway1&action=RunScene&SceneNum=

@implementation VeraSceneTrigger

-(void)performAction:(NSString*)action usingService:(NSString*)service onScene:(NSString*)sceneNum completion:(void(^)(NSURLResponse *response, NSData *data, NSError *devices))callback{
    
    NSString *htmlString = [NSString stringWithFormat:@"%@/data_request?id=action&output_format=json&serviceId=%@&action=%@&SceneNum=%@", self.controllerUrl, service, action, sceneNum];
    
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:htmlString]] queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        if (callback){
            callback(response, data, error);
        }
    }];
}

-(void)runSceneCompletion:(void(^)())callback {
    [self performAction:@"RunScene" usingService:UPNP_SERVICE_SCENE onScene:self.sceneNum completion:^(NSURLResponse *response, NSData *data, NSError *error){
        if (callback){
            callback();
        }
    }];
    
}

-(void)SceneOffCompletion:(void(^)())callback {
    [self performAction:@"SceneOff" usingService:UPNP_SERVICE_SCENE onScene:self.sceneNum completion:^(NSURLResponse *response, NSData *data, NSError *error){
        if (callback){
            callback();
        }
    }];
}

@end
