//
//  MasterViewController.h
//  RSSReader
//
//  Created by Michael Crump on 8/7/13.
//  Copyright (c) 2013 Michael Crump. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NSDate+InternetDateTime.h"

@interface MasterViewController : UITableViewController <NSXMLParserDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end
