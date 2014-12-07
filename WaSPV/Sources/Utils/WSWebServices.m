//
//  WSWebServices.m
//  WaSPV
//
//  Created by Davide De Rosa on 07/12/14.
//  Copyright (c) 2014 Davide De Rosa. All rights reserved.
//
//  http://github.com/keeshux
//  http://twitter.com/keeshux
//  http://davidederosa.com
//
//  This file is part of WaSPV.
//
//  WaSPV is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  WaSPV is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with WaSPV.  If not, see <http://www.gnu.org/licenses/>.
//

#import "DDLog.h"

#import "WSWebServices.h"
#import "WSConfig.h"

@implementation WSWebServices

+ (instancetype)sharedInstance
{
    static WSWebServices *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)asynchronousRequestWithBaseURL:(NSURL *)baseURL path:(NSString *)path success:(void (^)(id))success failure:(void (^)(NSError *))failure
{
    [self asynchronousRequestWithBaseURL:baseURL path:path timeout:WSWebServicesDefaultTimeout success:success failure:failure];
}

- (void)asynchronousRequestWithBaseURL:(NSURL *)baseURL path:(NSString *)path timeout:(NSTimeInterval)timeout success:(void (^)(id))success failure:(void (^)(NSError *))failure
{
    NSURL *url = [NSURL URLWithString:path relativeToURL:baseURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:timeout];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError) {
            DDLogDebug(@"Connection error from %@: %@", request, connectionError);
            failure(connectionError);
            return;
        }
        
        NSError *error = nil;
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (!json) {
            DDLogDebug(@"Malformed JSON from %@: %@", request, error);
            failure(error);
        }

        DDLogDebug(@"Returned JSON from %@: %@", request, json);
        success(json);
    }];
}

@end