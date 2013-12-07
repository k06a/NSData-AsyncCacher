//
//  NSData+AsyncCacher.h
//  Meetweet
//
//  Created by Антон Буков on 28.06.13.
//  Copyright (c) 2013 Anton Bukov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (AsyncCacher)

+ (void)getDataFromURL:(NSURL *)url
               toBlock:(void(^)(NSData * data, BOOL * retry))block;

+ (void)getDataFromURL:(NSURL *)url
               toBlock:(void(^)(NSData * data, BOOL * retry))block
             needCache:(BOOL)needCache;

@end
