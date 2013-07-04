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
    static NSOperationQueue * queue;
    static NSMutableDictionary * blocksDict;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 64;
        blocksDict = [NSMutableDictionary dictionary];
        
        NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:4*1024*1024 diskCapacity:20*1024*1024 diskPath:nil];
        [NSURLCache setSharedURLCache:URLCache];
    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (blocksDict[url] == nil)
            blocksDict[url] = [NSMutableArray array];
        
        NSMutableArray * blocks = blocksDict[url];
        [blocks addObject:(block ? (id)block : (id)[NSNull null])];
        if (blocks.count != 1)
            return;
        
        [queue addOperationWithBlock:^
        {
            [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * response, NSData * data, NSError * error)
            {
                for (id a in blocks)
                {
                    void(^aBlock)(NSData *,BOOL *) = a;
                    if ((id)aBlock == [NSNull null])
                        continue;
                    
                    BOOL retry = NO;
                    aBlock(data, &retry);
                    if (retry)
                        [NSData getDataFromURL:url toBlock:aBlock];
                }
                [blocks removeAllObjects];
            }];
        }];
    });
}

@end
