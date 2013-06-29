//
//  NSData+AsyncCacher.m
//  Meetweet
//
//  Created by Антон Буков on 28.06.13.
//  Copyright (c) 2013 Anton Bukov. All rights reserved.
//

#import "NSData+AsyncCacher.h"

@implementation NSData (AsyncCacher)

+ (void)getDataWithContentsOfURL:(NSURL *)url toBlock:(void(^)(NSData * data, BOOL * retry))block
{
    static NSCache * cache;
    static NSOperationQueue * queue;
    static NSMutableDictionary * blocksDict;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
        queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 64;
        blocksDict = [NSMutableDictionary dictionary];
    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (blocksDict[url] == nil)
            blocksDict[url] = [NSMutableArray array];
        
        NSData * data = [cache objectForKey:url];
        if (data != nil)
        {
            BOOL retry = NO;
            if (block)
                block(data, &retry);
            if (!retry)
                return;
        }
        
        NSMutableArray * blocks = blocksDict[url];
        [blocks addObject:(block ? (id)block : (id)[NSNull null])];
        if (blocks.count != 1)
            return;
        
        [queue addOperationWithBlock:^{
            NSData * data = [NSData dataWithContentsOfURL:url];
            if (data != nil)
                [cache setObject:data forKey:url];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                for (id a in blocks)
                {
                    BOOL retry = NO;
                    void(^aBlock)(NSData *,BOOL *) = a;
                    if ((id)aBlock != [NSNull null])
                        aBlock([cache objectForKey:url], &retry);
                    if (retry)
                        [NSData getDataWithContentsOfURL:url toBlock:block];
                }
                [blocks removeAllObjects];
            });
        }];
    });
}

@end
