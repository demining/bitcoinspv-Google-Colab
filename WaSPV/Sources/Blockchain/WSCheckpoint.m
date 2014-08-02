//
//  WSCheckpoint.m
//  WaSPV
//
//  Created by Davide De Rosa on 08/07/14.
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

#import "WSCheckpoint.h"
#import "WSErrors.h"

@interface WSCheckpoint ()

@property (nonatomic, assign) uint32_t height;
@property (nonatomic, strong) WSHash256 *blockId;
@property (nonatomic, assign) uint32_t timestamp;
@property (nonatomic, assign) uint32_t bits;

@end

@implementation WSCheckpoint

- (instancetype)initWithHeight:(uint32_t)height blockId:(WSHash256 *)blockId timestamp:(uint32_t)timestamp bits:(uint32_t)bits
{
    WSExceptionCheckIllegal(blockId != nil, @"Nil blockId");
    
    if ((self = [super init])) {
        self.height = height;
        self.blockId = blockId;
        self.timestamp = timestamp;
        self.bits = bits;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<#%u, %@, %u, %x>",
            self.height, self.blockId, self.timestamp, self.bits];
}

@end