//
//  BARTApi.m
//  BARTicus
//
//  Created by Neal Hardesty on 10/1/13.
//  Copyright (c) 2013 RoadWaffle Software. All rights reserved.
//

#import "BARTApi.h"
#import "ParserStations.h"
#import "ParserSchedule.h"

@interface BARTApi()

@end

@implementation BARTApi

@synthesize stationsByAbbreviation = _stationsByAbbreviation;

// Turn on the network activity indicator
- (void)beginNetworkActivity
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

// Turn off the network activity indicator
- (void)endNetworkActivity
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

// Try and load a Schedule for the specified station
- (Schedule *)getScheduleForStation:(Station *)station
{

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:API_ETD, station.abbreviation]];
    [self beginNetworkActivity];
    NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
    ParserSchedule *scheduleParser = [[ParserSchedule alloc] initWithParser:parser];
    scheduleParser.station = station;
    [self endNetworkActivity];

    return scheduleParser.schedule;
}

- (NSArray *)stations
{
    if(!_stations) {
        NSURL *url = [NSURL URLWithString:API_STATION];
        [self beginNetworkActivity];
        NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
        ParserStations *stationParser = [[ParserStations alloc] initWithParser:parser];
        [self endNetworkActivity];
        
        _stations = stationParser.stations;
        _stationsByAbbreviation = stationParser.stationsByAbbreviations;
    }

    return _stations;
}

- (Station *)findClosestStation
{
    CLLocationCoordinate2D currentLocation = [self getLocation];
    
    double closestDistance = DBL_MAX;
    Station *closestStation;

    for(Station *station in self.stations) {
        double distance = [self calcDistanceToStation:station withLocation:currentLocation];
        if(!closestStation || distance < closestDistance) {
            closestDistance = distance;
            closestStation = station;
        }
    }

    return closestStation;
}

#define MEAN_EARTH_RADIUS 6371.0
- (double)calcDistanceToStation:(Station *)station withLocation:(CLLocationCoordinate2D)currentLocation
{
    // Spherical Law of Cosines
    // acos(sin(lat1)*sin(lat2) + cos(lat1)*cos(lat2)*cos(lon2-lon1)) * (6371)
    CLLocationCoordinate2D coord = [self getLocation];
    double lat1 = coord.latitude;
    double lon1 = coord.longitude;
    
    double lat2 = station.latitude;
    double lon2 = station.longitude;
    
    double distance = acos(sin(lat1)*sin(lat2) + cos(lat1)*cos(lat2)*cos(lon2-lon1)) * MEAN_EARTH_RADIUS;
    
    return distance;
}

- (CLLocationCoordinate2D) getLocation
{
    CLLocationManager *locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    [locationManager startUpdatingLocation];
    CLLocation *location = [locationManager location];
    CLLocationCoordinate2D coord = [location coordinate];
    
    return coord;
}

@end