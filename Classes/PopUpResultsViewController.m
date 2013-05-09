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

#import "PopUpResultsViewController.h"


@implementation PopUpResultsViewController

@synthesize results = _results;
@synthesize tableView = _tableView;
@synthesize resultsArray = _resultsArray;

- (IBAction)done:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //if results is not nil and we have results, return that number
    return ((self.results != nil && [self.results count] > 0) ? [self.results count] : 0);
   //  return ((self.resultsArray != nil && [self.resultsArray count] > 0) ? [self.resultsArray count] : 0);
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
  //  NSInteger row = [indexPath row];
  //  NSDictionary *object = [datasouce objectAtIndex:row]; // datasource is an array
    
  //  NSArray *temp = [divisionDict objectForKey:[divisionArray objectAtIndex:[indexPath section]]];
  //  [[cell textLabel] setText:[temp objectAtIndex:[indexPath row]]];
    
   // NSArray *temp = [[self.results objectForKey:[]]
    //text is the key at the given indexPath

    NSString *keyAtIndexPath = [[self.results allKeys] objectAtIndex:indexPath.row];
    
    // retrieve the value from the dictionary stored in the resultsArray at this row location
  //NSString *keyAtIndexPath = [_resultsArray objectAtIndex:[indexPath row]];
    
  //  NSDictionary *oneEntryDict = [_resultsArray objectAtIndex:[indexPath row]];
  //  NSArray *tempArray = [oneEntryDict objectForKey:[_resultsArray objectAtIndex:[indexPath row]]];
  //  NSString *keyAtIndexPath = [tempArray objectAtIndex:[indexPath row]];

    cell.textLabel.text = keyAtIndexPath;
    
    //detail text is the value associated with the key above
    id detailValue = [self.results objectForKey:keyAtIndexPath];
    
    //figure out if the value is a NSDecimalNumber or NSString
    if ([detailValue isKindOfClass:[NSString class]])
     {
         //value is a NSString, just set it
         cell.detailTextLabel.text = (NSString *)detailValue;
     }
    else if ([detailValue isKindOfClass:[NSDecimalNumber class]])
    {
        //value is a NSDecimalNumber, format the result as a double
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%0.0f", [detailValue doubleValue]];
    }
    else {
        //not a NSDecimalNumber or a NSString, 
        cell.detailTextLabel.text = @"N/A";
    }
	
    return cell;
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (YES);
}

- (void)dealloc {
    self.results = nil;
    self.tableView = nil;
}


@end

