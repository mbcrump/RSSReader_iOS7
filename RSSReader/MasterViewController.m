//
//  MasterViewController.m
//  RSSReader
//
//  Created by Michael Crump on 8/7/13.
//  Copyright (c) 2013 Michael Crump. All rights reserved.
//

#import "MasterViewController.h"

#import "DetailViewController.h"

@interface MasterViewController () {
    NSXMLParser *parser;
    NSMutableArray *feeds;
    NSMutableDictionary *item;
    NSString *title;
    NSString *blogTitle;
    NSString *link;
    NSString *element;
    NSDate *published;
}
@end

@implementation MasterViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    feeds = [[NSMutableArray alloc] init];
    
    NSArray *_feeds = @[@"http://www.raywenderlich.com/feed",@"http://feeds.feedburner.com/CoryWilesBlog",@"http://michaelcrump.net/feed"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    for (NSString *url in _feeds) {
        [[session dataTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            [self parseRSSData:data];
            
        }] resume];
    }
}

- (void)parseRSSData:(NSData*)data
{
    parser = [[NSXMLParser alloc]initWithData:data];
    
    [parser setDelegate:self];
    [parser setShouldResolveExternalEntities:NO];
    [parser parse];
    
    NSSortDescriptor *titleDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"published" ascending:NO];
    
    [feeds sortUsingDescriptors:@[titleDescriptor]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [feeds count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (cell == nil) {
      cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:@"Cell"];
    }
    
    //Main Label
    NSString *articleTitle = feeds [indexPath.row] [@"title"];
    cell.textLabel.text = feeds [indexPath.row] [@"blogTitle"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    
    //Add Published Information
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    NSString *articleDateString = [dateFormatter stringFromDate:feeds [indexPath.row] [@"published"]];
    //Detail
    cell.detailTextLabel.text =  [NSString stringWithFormat:@"%@ - %@", articleDateString, articleTitle];
   
    return cell;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self performSegueWithIdentifier:@"showDetail" sender:self];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{
    
    element = elementName;
    
    if ([element isEqualToString:@"entry"] || [element isEqualToString:@"item"]) {
        item = [[NSMutableDictionary alloc] init];
        isEntryElement = YES;
    }
    
    if ([elementName isEqualToString:@"link"]){
        //Feedburner users @"href"
        NSString *temp = [attributeDict valueForKey:@"href"];
        if (temp == nil) {
        //Not Feedburner blog - ray's blog
            //TODO: NOT WORKING Ray's LINKS are not being passed in.
           link = [[NSString alloc] init];
        }
        else
        {
            link = temp;
        }
        NSLog(@"%@", link);
    }
  
    
    if ([elementName isEqualToString:@"title"]){
        isTitleElement = YES;
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    if ([elementName isEqualToString:@"entry"] || ([elementName isEqualToString:@"item"])) {
        
        [item setObject:title forKey:@"title"];
        [item setObject:link forKey:@"link"];
        [item setObject:published forKey:@"published"];
        [item setObject:blogTitle forKey:@"blogTitle"];
        
        [feeds addObject:item];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    NSString *formattedString = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([formattedString isEqualToString:@""])
        return;
    
    if ([element isEqualToString:@"published"] || ([element isEqualToString:@"pubDate"])){
        
        NSDate *articleDate = [NSDate dateFromInternetDateTimeString:formattedString formatHint:DateFormatHintRFC3339];
        published = articleDate;
        
    }
    
    if ([element isEqualToString:@"title"]){
        title = formattedString;
        if (!isEntryElement && isTitleElement){
            blogTitle = title;
        }
    }
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    
    [self.tableView reloadData];
    
    isTitleElement = NO;
    isEntryElement = NO;
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        //NSString *string = [feeds[indexPath.row] objectForKey: @"link"];
        NSString *string = feeds [indexPath.row] [@"link"];
        
        [[segue destinationViewController] setUrl:string];
        
    }
}

@end
