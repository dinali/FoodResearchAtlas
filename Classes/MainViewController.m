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
#import "MainViewController.h"
#import "TOCViewController.h"
#import "ResultsViewController.h"
//#import "PopUpResultsViewController.h"

@interface MainViewController()

@property (nonatomic, strong) TOCViewController *tocViewController;

@end

@implementation MainViewController

// these have to be paired, can't substitute maps?
static NSString *kGeoLocatorURL = @"http://tasks.arcgisonline.com/ArcGIS/rest/services/Locators/ESRI_Places_World/GeocodeServer";

// this is not the right map, but it works with the geocoder
static NSString *kMapServiceURL = @"http://services.arcgisonline.com/ArcGIS/rest/services/ESRI_StreetMap_World_2D/MapServer";

//static NSString *kMapServiceURL = @"http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer";

// http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer
// this is the right satellite map, but the geocoder doesn't return results
//static NSString *kMapServiceURL = @"http://services.arcgisonline.com/ArcGIS/rest/services/USA_Topo_Maps/MapServer";

// this is the right satellite map, but the geocoder doesn't return results
//static NSString *kMapServiceURL = @"http://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer";

// popup
#define kDynamicMapServiceURL @"http://gis2.ers.usda.gov/arcgis/rest/services/foodaccess/MapServer"

@synthesize graphic = _graphic;
@synthesize identifyTask=_identifyTask,identifyParams=_identifyParams;
@synthesize mappoint = _mappoint;

@synthesize infoButton=_infoButton;
@synthesize tocViewController = _tocViewController;
@synthesize popOverController = _popOverController;

@synthesize searchBar = _searchBar;
@synthesize graphicsLayer = _graphicsLayer;
@synthesize locator = _locator;
@synthesize calloutTemplate = _calloutTemplate;

- (void)viewDidLoad {
    [super viewDidLoad];    
    
    //create the toc view controller
    self.tocViewController = [[TOCViewController alloc] initWithMapView:self.mapView]; 
	
    NSURL *mapUrl = [NSURL URLWithString:kMapServiceURL];
    
	AGSTiledMapServiceLayer *tiledLyr = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:mapUrl];
	[self.mapView addMapLayer:tiledLyr withName:@"Base Map"];
    
   // dispatch_queue_t kBgQueue = dispatch_get_global_queue(
                                                          //DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
  //  dispatch_async(kBgQueue, ^{
        // NEW! Food Research Atlas //
        NSURL *mapUrl3 = [NSURL URLWithString:kDynamicMapServiceURL];
        AGSDynamicMapServiceLayer *dynamicLyr3 = [AGSDynamicMapServiceLayer dynamicMapServiceLayerWithURL:mapUrl3];
        [self.mapView addMapLayer:dynamicLyr3 withName:@"Food Research Atlas"];
  //  });
    
    
    //add a feature layer -- this doesn't display
    //AGSFeatureLayer *featureLayer = [AGSFeatureLayer featureServiceLayerWithURL:[NSURL URLWithString:@"http://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer"] mode:AGSFeatureLayerModeOnDemand];
    //[self.mapView addMapLayer:featureLayer withName:@"Satellite"];
    
    //Zooming to an initial envelope with the specified spatial reference of the map.
	AGSSpatialReference *sr = [AGSSpatialReference webMercatorSpatialReference];
    
	AGSEnvelope *env = [AGSEnvelope envelopeWithXmin:-14240548.0734049
                                                ymin:1295233.07890617
                                                xmax:-7106113.23047588
                                                ymax:7754274.75670459 
									spatialReference:sr];
	[self.mapView zoomToEnvelope:env animated:YES];
    
    // current location marker: user's current location as starting point
    [self.mapView.locationDisplay startDataSource];

    // ADDED FOR GEOCODING FIND ADDRESS
    
    //set the delegate on the mapView so we get notifications for user interaction with the callout for geocoding
    self.mapView.callout.delegate = self;
    
    //create the graphics layer that the geocoding result
    //will be stored in and add it to the map
    self.graphicsLayer = [AGSGraphicsLayer graphicsLayer];
    [self.mapView addMapLayer:self.graphicsLayer withName:@"Search Layer"];
    
    // this works but Layer 3 is displayed!
  //  [self.mapView addMapLayer:self.graphicsLayer withName:@""];
    
    // ADDED FOR POPUP BY LOCATION
    _mapView.touchDelegate = self;
    
    //create identify task
	self.identifyTask = [AGSIdentifyTask identifyTaskWithURL:[NSURL URLWithString:kDynamicMapServiceURL]];
	self.identifyTask.delegate = self;
	
	//create identify parameters
	self.identifyParams = [[AGSIdentifyParameters alloc] init];
    
    self.mapView.showMagnifierOnTapAndHold = YES;
}


#pragma mark -

- (IBAction)presentTableOfContents:(id)sender
{
    //If iPad, show legend in the PopOver, else transition to the separate view controller
	if([[AGSDevice currentDevice] isIPad]) {
        if(!self.popOverController) {
            self.popOverController = [[UIPopoverController alloc] initWithContentViewController:self.tocViewController];
            self.tocViewController.popOverController = self.popOverController;
            self.popOverController.popoverContentSize = CGSizeMake(320, 500);
            self.popOverController.passthroughViews = [NSArray arrayWithObject:self.view];
        }        
		[self.popOverController presentPopoverFromRect:self.infoButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES ];		
	}
    else {
		[self presentModalViewController:self.tocViewController animated:YES];
	}    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {

    [super viewDidUnload];
	self.mapView = nil;
	self.infoButton = nil;
    self.tocViewController = nil;
    if([[AGSDevice currentDevice] isIPad])
        self.popOverController = nil;
}

#pragma mark -
#pragma mark FIND ADDRESS FEATURE

- (void)startGeocoding
{
    
    //clear out previous results
    [self.graphicsLayer removeAllGraphics];
    
    //create the AGSLocator with the geo locator URL
    //and set the delegate to self, so we get AGSLocatorDelegate notifications
    self.locator = [AGSLocator locatorWithURL:[NSURL URLWithString:kGeoLocatorURL]];
    self.locator.delegate = self;
    
    //we want all out fields
    //Note that the "*" for out fields is supported for geocode services of
    //ArcGIS Server 10 and above
    //NSArray *outFields = [NSArray arrayWithObject:@"*"];
    
    //for pre-10 ArcGIS Servers, you need to specify all the out fields:
    NSArray *outFields = [NSArray arrayWithObjects:@"Loc_name",
                          @"Shape",
                          @"Score",
                          @"Name",
                          @"Rank",
                          @"Match_addr",
                          @"Descr",
                          @"Latitude",
                          @"Longitude",
                          @"City",
                          @"County",
                          @"State",
                          @"State_Abbr",
                          @"Country",
                          @"Cntry_Abbr",
                          @"Type",
                          @"North_Lat",
                          @"South_Lat",
                          @"West_Lon",
                          @"East_Lon",
                          nil];
    
    //Create the address dictionary with the contents of the search bar
    NSDictionary *addresses = [NSDictionary dictionaryWithObjectsAndKeys:self.searchBar.text, @"PlaceName", nil];
    
    //now request the location from the locator for our address
    [self.locator locationsForAddress:addresses returnFields:outFields];
}

#pragma mark -
#pragma mark AGSCalloutDelegate -- DISPLAYS THE box with related information

- (void) didClickAccessoryButtonForCallout:(AGSCallout *) callout
{
    
    AGSGraphic* graphic = (AGSGraphic*) callout.representedObject;
    //The user clicked the callout button, so display the complete set of results
    ResultsViewController *resultsVC = [[ResultsViewController alloc] initWithNibName:@"ResultsViewController" bundle:nil];
    
    //set our attributes/results into the results VC
    resultsVC.results = [graphic allAttributes];
    
    //display the results vc modally
    [self presentModalViewController:resultsVC animated:YES];
	
}
 

#pragma mark -
#pragma mark AGSLocatorDelegate

- (void)locator:(AGSLocator *)locator operation:(NSOperation *)op didFindLocationsForAddress:(NSArray *)candidates
{
    //check and see if we didn't get any results
	if (candidates == nil || [candidates count] == 0)
	{
        //show alert if we didn't get results
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Results"
                                                        message:@"No Results Found By Locator"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        
        [alert show];
	}
	else
	{
        //use these to calculate extent of results
        double xmin = DBL_MAX;
        double ymin = DBL_MAX;
        double xmax = -DBL_MAX;
        double ymax = -DBL_MAX;
		
		//create the callout template, used when the user displays the callout
		self.calloutTemplate = [[AGSCalloutTemplate alloc]init];
        
        //loop through all candidates/results and add to graphics layer
		for (int i=0; i<[candidates count]; i++)
		{
			AGSAddressCandidate *addressCandidate = (AGSAddressCandidate *)[candidates objectAtIndex:i];
            
            //get the location from the candidate
            AGSPoint *pt = addressCandidate.location;
            
            //accumulate the min/max
            if (pt.x  < xmin)
                xmin = pt.x;
            
            if (pt.x > xmax)
                xmax = pt.x;
            
            if (pt.y < ymin)
                ymin = pt.y;
            
            if (pt.y > ymax)
                ymax = pt.y;
            
			//create a marker symbol to use in our graphic
            AGSPictureMarkerSymbol *marker = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImageNamed:@"BluePushpin.png"];
            marker.offset = CGPointMake(9,16);
            marker.leaderPoint = CGPointMake(-9, 11);
            
            //set the text and detail text based on 'Name' and 'Descr' fields in the attributes
            self.calloutTemplate.titleTemplate = @"${Name}";
            self.calloutTemplate.detailTemplate = @"${Descr}";
			
            //create the graphic
			AGSGraphic *graphic = [[AGSGraphic alloc] initWithGeometry: pt
																symbol:marker
															attributes:[addressCandidate.attributes mutableCopy]
                                                  infoTemplateDelegate:self.calloutTemplate];
            
            
            //add the graphic to the graphics layer
			[self.graphicsLayer addGraphic:graphic];
            
            if ([candidates count] == 1)
            {
                //we have one result, center at that point
                [self.mapView centerAtPoint:pt animated:NO];
                
				// set the width of the callout
				self.mapView.callout.width = 250;
                
                //show the callout
                [self.mapView.callout showCalloutAtPoint:(AGSPoint*)graphic.geometry forGraphic:graphic animated:YES];
            }
			
			//release the graphic bb
		}
        
        //if we have more than one result, zoom to the extent of all results
        int nCount = [candidates count];
        if (nCount > 1)
        {
            AGSMutableEnvelope *extent = [AGSMutableEnvelope envelopeWithXmin:xmin ymin:ymin xmax:xmax ymax:ymax spatialReference:self.mapView.spatialReference];
            [extent expandByFactor:1.5];
			[self.mapView zoomToEnvelope:extent animated:YES];
        }
	}
    
}

- (void)locator:(AGSLocator *)locator operation:(NSOperation *)op didFailLocationsForAddress:(NSError *)error
{
    //The location operation failed, display the error
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Locator Failed"
                                                    message:[NSString stringWithFormat:@"Error: %@", error.description]
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    
    [alert show];
}

#pragma mark _
#pragma mark UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	
	//hide the callout
	self.mapView.callout.hidden = YES;
	
    //First, hide the keyboard, then starGeocoding
    [searchBar resignFirstResponder];
    [self startGeocoding];
}


- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    //hide the keyboard
    [searchBar resignFirstResponder];
}

#pragma mark - AGSCalloutDelegate methods

- (void)mapView:(AGSMapView *)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint graphics:(NSDictionary *)graphicsDict {
    
    //store for later use
    self.mappoint = mappoint;
    
	//the layer we want is layer ‘5’ (from the map service doc)
	self.identifyParams.layerIds = [NSArray arrayWithObjects:[NSNumber numberWithInt:1], nil];
	self.identifyParams.tolerance = 3;
	self.identifyParams.geometry = self.mappoint;
	self.identifyParams.size = self.mapView.bounds.size;
	self.identifyParams.mapEnvelope = self.mapView.visibleArea.envelope;
	self.identifyParams.returnGeometry = YES;
	self.identifyParams.layerOption = AGSIdentifyParametersLayerOptionAll;
	self.identifyParams.spatialReference = self.mapView.spatialReference;
    
	//execute the task
	[self.identifyTask executeWithParameters:self.identifyParams];
}


#pragma mark - AGSIdentifyTaskDelegate methods
//results are returned
- (void)identifyTask:(AGSIdentifyTask *)identifyTask operation:(NSOperation *)op didExecuteWithIdentifyResults:(NSArray *)results {
    
    //clear previous results
    [self.graphicsLayer removeAllGraphics];
    
    if ([results count] > 0) {
        
        //add new results
        AGSSymbol* symbol = [AGSSimpleFillSymbol simpleFillSymbol];
        symbol.color = [UIColor colorWithRed:0 green:0 blue:1 alpha:0.5];
        
        NSString *title = nil;
        NSUInteger layerID = 0;
        
        @try {
            
            // for each result, set the symbol and add it to the graphics layer
            for (AGSIdentifyResult* result in results) {
                result.feature.symbol = symbol;
                [self.graphicsLayer addGraphic:result.feature];
                _graphic = result.feature;
                title = result.layerName;
                layerID = result.layerId; // can this be a filter? not used
            }
            
            self.mapView.callout.title = title; // this is just the title
            self.mapView.callout.detail = @"Click for details";
            
            //show callout
            //[self.mapView.callout showCalloutAt:self.mappoint pixelOffset:CGPointZero animated:YES];
            
            // Show callout for graphic
            [self.mapView.callout showCalloutAtPoint:self.mappoint forGraphic:_graphic animated:YES];
        }
        @catch (NSException * e) {
            NSLog(@"Exception: %@", e);
        }
        @finally {
            NSLog(@"finally");
        }
    }
}

//if there's an error with the query display it to the user
- (void)identifyTask:(AGSIdentifyTask *)identifyTask operation:(NSOperation *)op didFailWithError:(NSError *)error {
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
													message:[error localizedDescription]
												   delegate:nil
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];
}
@end
