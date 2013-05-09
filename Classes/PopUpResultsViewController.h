// Copyright 2012 ESRI
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// You may freely redistribute and use this sample code, with or
// without modification, provided you include the original copyright
// notice and use restrictions.
//
// See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
//

/*
 
 Load the data source - the dictionary with the array necessary to return the items in the correct order, add a NSArray property and pass that as the data source for the ResultsViewController??
 
 */

#import <UIKit/UIKit.h>


@interface PopUpResultsViewController : UIViewController {
    NSDictionary *_results;
    UITableView *_tableView;

}

//results are the attributes of the result of the geocode operation
@property (nonatomic, retain) NSDictionary *results;
@property (nonatomic,retain) NSArray *resultsArray;
@property (nonatomic, retain) IBOutlet UITableView *tableView;

//close the view controller
- (IBAction)done:(id)sender;

@end
