NSData-AsyncCacher
==================

NSData category for async loading data from url and calling block. Requested data is cached with NSCache and can be requested multiple times simultaneously.

You need no more care about:

* cache responses
* several same requests simultaniuosly

Example:

```
- (void)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = // . . .
    
    [NSData getDataWithContentsOfURL:[NSURL URLWithString:urlString]
                             toBlock:^(NSData * data, BOOL * retry)
    {
        if (data == nil) {
           *retry = YES;
           return;
        }
        
        // cell may be nil if you scroll away
        UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
       	cell.imageView.image = [UIImage imageWithData:data];
    }];
    
    return cell;
}
```

