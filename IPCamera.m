//
//  IPCamera.m
//  Home
//
//  Created by Drew Ingebretsen on 11/3/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import "IPCamera.h"

#define UPNP_SERVICE_CAMERA @"urn:micasaverde-com:serviceId:Camera1"
#define UPNP_SERVICE_CAMERA_PAN_TILT_ZOOM @"urn:micasaverde-com:serviceId:PanTiltZoom1"

@implementation IPCamera

-(IPCamera*)initWithDictionary:(NSDictionary*)dictionary{
    self = [super initWithDictionary:dictionary];
    if (self){
        self.username = [dictionary objectForKey:@"username"];
        self.password = [dictionary objectForKey:@"password"];
        self.ipAddress = [dictionary objectForKey:@"ipaddress"];
        
        for (NSDictionary *serviceDictionary in dictionary[@"states"]){
            NSString *service = serviceDictionary[@"service"];
            if ([service isEqualToString:UPNP_SERVICE_CAMERA]){
                NSString *variable = serviceDictionary[@"variable"];
                if ([variable isEqualToString:@"URL"]){
                    self.snapshotUrl = serviceDictionary[@"value"];
                }
                if ([variable isEqualToString:@"DirectStreamingURL"]){
                    self.videoUrl = serviceDictionary[@"value"];
                }
                if ([variable isEqualToString:@"Commands"]){
                    NSString *commandString = serviceDictionary[@"value"];
                    if ([commandString hasPrefix:@"camera_up"]){
                        self.canPan = YES;
                    }
                }
            }
        }

    }
    return self;
}

-(void)getVideoFeedURL:(void (^)(NSURL *url))callback{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/data_request?id=relay&device=%@", self.controllerUrl, self.identifier]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (responseString.length > 1){
            NSURL *videoStreamUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%@@%@%@", self.username, self.password, responseString, self.videoUrl]];
            if (callback){
                callback(videoStreamUrl);
            }
        }
    }];
}

-(void)getSnapshot:(void (^)(UIImage *image))callback{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/data_request?id=relay&device=%@", self.controllerUrl, self.identifier]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (responseString.length > 1){
            NSURL *snapshotUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%@@%@%@", self.username, self.password, responseString, self.snapshotUrl]];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
                [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:snapshotUrl] queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
                    UIImage *image = [UIImage imageWithData:data];
                    if (callback){
                        callback(image);
                    }
                }];
                
            });
            
        }
    }];
}

-(void)moveUp{
    [self performAction:@"MoveUp" usingService:UPNP_SERVICE_CAMERA_PAN_TILT_ZOOM completion:Nil];
}
-(void)moveDown{
    [self performAction:@"MoveDown" usingService:UPNP_SERVICE_CAMERA_PAN_TILT_ZOOM completion:Nil];
}
-(void)moveRight{
    [self performAction:@"MoveLeft" usingService:UPNP_SERVICE_CAMERA_PAN_TILT_ZOOM completion:Nil];
}
-(void)moveLeft{
    [self performAction:@"MoveRight" usingService:UPNP_SERVICE_CAMERA_PAN_TILT_ZOOM completion:Nil];
}

@end
