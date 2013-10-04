//
//  BarticusViewController.m
//  BARTicus
//
//  Created by Neal Hardesty on 10/1/13.
//  Copyright (c) 2013 RoadWaffle Software. All rights reserved.
//

#import "BarticusViewController.h"
#import "Model/BARTApi.h"

@interface BarticusViewController ()
@property (nonatomic, strong) BARTApi *bartapi;
@property (nonatomic, strong) Station *closestStation;
@property (nonatomic, strong) NSArray *currentTrainsGroupedByDestinationSortedByTime;
@end

@implementation BarticusViewController

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.currentTrainsGroupedByDestinationSortedByTime count];
}

#define CELL_IDENTIFIER @"Schedule Cell"
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CELL_IDENTIFIER];
    }
    NSArray *trains = [self.currentTrainsGroupedByDestinationSortedByTime objectAtIndex:indexPath.item];
    BOOL first=YES;
    for(Train *train in trains) {
        Station *destinationStation = self.bartapi.stationsByAbbreviation[train.destination];
        cell.textLabel.text = destinationStation.name;
        if(first) {
            first=NO;
            cell.detailTextLabel.text = [self formatMinutes:train.minutes];
        } else {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@,%@", cell.detailTextLabel.text, [self formatMinutes:train.minutes]];
        }
    }
    
    return cell;
}

- (NSString *)formatMinutes:(short)minutes {
    if(minutes == 0) {
        return @"<at station>";
    } else {
        return [NSString stringWithFormat:@"%hd", minutes];
    }
    
}

/*
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(self.closestStation) {
        return [NSString stringWithFormat:@"%@\nDepartures",self.closestStation.name];
    } else {
        return @"Loading Departures...";
    }
}
 */

- (BARTApi *)bartapi {
    if(!_bartapi) {
        _bartapi = [[BARTApi alloc] init];
    }
    
    return _bartapi;
}

// Triggered by the refresh indicator turning on/off
- (IBAction)refreshAction:(UIRefreshControl *)sender {
    //NSLog(@"got refresh action");
    if(sender.refreshing) {
        [self doRefresh];
    }
}

// This actually does the API refresh
- (void)doRefresh
{
    //NSLog(@"got refresh");
    dispatch_async(dispatch_queue_create("Reload Data", NULL), ^{
        self.closestStation = [self.bartapi findClosestStation];
        //NSLog(@"closest: %@", closest);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.title = self.closestStation.name;
            
        });
        

        Schedule *schedule = [self.bartapi getScheduleForStation:self.closestStation];
        //NSLog(@"schedule: %@", schedule);
        
        self.currentTrainsGroupedByDestinationSortedByTime = [schedule getTrainsGroupedByDestinationSortedByTime];
        
        //NSLog(@"station info: %@", [self.bartapi.stationsByAbbreviation objectForKey:closest.abbreviation]);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDate *now = [[NSDate alloc] init];
            NSDateFormatter *format = [[NSDateFormatter alloc] init];
            [format setDateFormat:@"'Last Updated' h:mm:ss a"];
            NSString *lastUpdated = [format stringFromDate:now];
            UIBarButtonItem *toolbarLabel = [[UIBarButtonItem alloc] initWithTitle:lastUpdated style:UIBarButtonItemStylePlain target:self action:@selector(showAndStartRefresh)];
            UIBarButtonItem *flexiSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            [self.navigationController.toolbar setItems:[NSArray arrayWithObjects:flexiSpace, toolbarLabel, flexiSpace, nil] animated:YES];
            
        });
        
        //[NSThread sleepForTimeInterval:5];
        [self hideRefresh];
        
        [self.tableView reloadData];
    });
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self showAndStartRefresh];
    
    [self.refreshControl addTarget:self
                            action:@selector(refreshAction:)
                  forControlEvents:UIControlEventValueChanged];
}

// Called from viewDidLoad and as callback for clicking refresh.
- (void)showAndStartRefresh
{
    [self showRefresh];
    [self doRefresh];
}


// Force the refresh indicator on to the screen, and animate it
- (void)showRefresh {
    [self.refreshControl beginRefreshing];
    CGPoint newOffset = CGPointMake(0, -self.refreshControl.frame.size.height);
    [self.tableView setContentOffset:newOffset
                            animated:YES];
    
}

// Stop the animation on the refresh indicator, and hide it
- (void) hideRefresh {
    [self.refreshControl endRefreshing];
}

@end
