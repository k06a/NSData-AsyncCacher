//
//  NSData+AsyncCacher.m
//  Meetweet
//
//  Created by Антон Буков on 28.06.13.
//  Copyright (c) 2013 Anton Bukov. All rights reserved.
//

#import "NSData+AsyncCacher.h"

@implementation NSData (AsyncCacher)

+ (void)getDataFromURL:(NSURL *)url toBlock:(void(^)(NSData * data, BOOL * retry))block
{
    static NSCache * cache;
    static NSOperationQueue * mainQueue;
    static NSOperationQueue * parallelQueue;
    static NSMutableDictionary * blocksDict;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
        mainQueue = [[NSOperationQueue alloc] init];
        mainQueue.maxConcurrentOperationCount = 1;
        parallelQueue = [[NSOperationQueue alloc] init];
        parallelQueue.maxConcurrentOperationCount = 64;
        blocksDict = [NSMutableDictionary dictionary];
        
        NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:4*1024*1024 diskCapacity:20*1024*1024 diskPath:nil];
        [NSURLCache setSharedURLCache:URLCache];
    });
    
    NSData * object = [cache objectForKey:url];
    if (object)
    {
        BOOL retry = NO;
        block(object, &retry);
        if (!retry)
            return;
    }
    
    [mainQueue addOperationWithBlock:^{
        NSMutableArray * blocks = blocksDict[url];
        if (blocks == nil)
        {
            blocks = [NSMutableArray array];
            blocksDict[url] = blocks;
        }
        
        [blocks addObject:(block ? (id)block : (id)[NSNull null])];
        if (blocks.count != 1)
            return;
        
        [parallelQueue addOperationWithBlock:^
        {
            NSError * error;
            NSURLResponse * response;
            NSData * data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:url] returningResponse:&response error:&error];
            
            [mainQueue addOperationWithBlock:^{
                if (data)
                    [cache setObject:data forKey:url];
                
                for (id a in blocks)
                {
                    void(^aBlock)(NSData *,BOOL *) = a;
                    if ((id)aBlock == [NSNull null])
                        continue;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        BOOL retry = NO;
                        aBlock(data, &retry);
                        if (retry)
                            [NSData getDataFromURL:url toBlock:aBlock];
                    });
                }
                [blocks removeAllObjects];
            }];
        }];
    }];
}

@end
