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


#import "IdentifyTaskDemoViewController.h"
//#define kDynamicMapServiceURL @"http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Demographics/ESRI_Census_USA/MapServer"

#define kDynamicMapServiceURL @"http://gis2.ers.usda.gov/ArcGIS/rest/services/snap_Benefits/MapServer"

@implementation IdentifyTaskDemoViewController
@synthesize mapView=_mapView;
@synthesize graphicsLayer=_graphicsLayer;
@synthesize graphic = _graphic;
@synthesize identifyTask=_identifyTask,identifyParams=_identifyParams; 
@synthesize mappoint = _mappoint;


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	
	_mapView.touchDelegate = self;
    _mapView.callout.delegate = self;
    
    //add a tiled layer
    NSURL *mapUrl5 = [NSURL URLWithString:@"http://gis2.ers.usda.gov/ArcGIS/rest/services/Background_Cache/MapServer"];
	AGSTiledMapServiceLayer *tiledLyr5 = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:mapUrl5];
	[self.mapView addMapLayer:tiledLyr5 withName:@"Background"];
    
    NSURL *mapUrl3 = [NSURL URLWithString:@"http://gis2.ers.usda.gov/ArcGIS/rest/services/Reference2/MapServer"];
	AGSDynamicMapServiceLayer *dynamicLyr2 = [AGSDynamicMapServiceLayer dynamicMapServiceLayerWithURL:mapUrl3];
	[self.mapView addMapLayer:dynamicLyr2 withName:@"Reference"];
  
	// create a dynamic map service layer
	AGSDynamicMapServiceLayer *dynamicLayer = [[AGSDynamicMapServiceLayer alloc] initWithURL:[NSURL URLWithString:kDynamicMapServiceURL]];
	
	// set the visible layers on the layer
	dynamicLayer.visibleLayers = [NSArray arrayWithObjects:[NSNumber numberWithInt:5], nil];
    dynamicLayer.opacity=.8;
	
	// add the layer to the map
	[self.mapView addMapLayer:dynamicLayer withName:@"Dynamic Layer"];
	
	// create and add the graphics layer to the map
	self.graphicsLayer = [AGSGraphicsLayer graphicsLayer];
	[self.mapView addMapLayer:self.graphicsLayer withName:@"Graphics Layer"];
    
    AGSSpatialReference *sr = [AGSSpatialReference spatialReferenceWithWKID:102100];
    
	AGSEnvelope *env = [AGSEnvelope envelopeWithXmin:-14314526
                                                ymin:2616367
                                                xmax:-7186578
                                                ymax:6962565
									spatialReference:sr];
	[self.mapView zoomToEnvelope:env animated:YES];
	
	//create identify task
	self.identifyTask = [AGSIdentifyTask identifyTaskWithURL:[NSURL URLWithString:kDynamicMapServiceURL]];
	self.identifyTask.delegate = self;
	
	//create identify parameters
	self.identifyParams = [[AGSIdentifyParameters alloc] init];
    
    self.mapView.showMagnifierOnTapAndHold = YES;
	
    [super viewDidLoad];
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
        self.mapView.callout.detail = @"Click for more detail..";
        
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


// NEW!
- (void) didClickAccessoryButtonForCallout:(AGSCallout *)callout{
    
    // callout.representedObject is CALayer - is that AGSMapViewLayer? does that still exist? Need the graphic instead cast it?
    
    /*
    if([callout.representedObject isKindOfClass:[CALayer class]]){
        NSLog(@"it's a layer!!"); // how to get the graphic?
    }
    
    if([callout.representedObject isKindOfClass: [AGSPoint class]]){
        AGSPoint* point = (AGSPoint*) callout.representedObject;
        //...
    }
    else if([callout.representedObject isKindOfClass: [AGSLocationDisplay class]]){
        AGSLocationDisplay* ld = (AGSLocationDisplay*) callout.representedObject;
        //...
    }
    */
    if([callout.representedObject isKindOfClass: [AGSGraphic class]]){
        
        AGSGraphic* mapGraphic = (AGSGraphic*) callout.representedObject;
        //The user clicked the callout button, so display the complete set of results
    
        ResultsViewController *resultsVC = [[ResultsViewController alloc] initWithNibName:@"ResultsViewController" bundle:nil];
        
        //set our attributes/results into the results VC
       // resultsVC.results = mapGraphic.allAttributes; // NSDictionary -- this returns the extra attributes that should not be included such as Shape
        
        // loop through and only pull out what you need and then re-pack the dictionary and pass to resultsVC
        // can't use the fieldname only the alias
        
        NSDictionary *finalAttributesDict = [[NSDictionary alloc]initWithObjectsAndKeys:
                                         [mapGraphic.allAttributes objectForKey:@"FIPSTXT"],  @"FIPSTXT",
                                         [mapGraphic.allAttributes objectForKey:@"State"], @"State",
                                         [mapGraphic.allAttributes objectForKey:@"County"], @"County",
                                         [mapGraphic.allAttributes objectForKey:@"2010 total SNAP benefits"], @"2010 total SNAP benefits",
                                         [mapGraphic.allAttributes objectForKey:@"2009 total SNAP benefits"], @"2009 total SNAP benefits",
                                         [mapGraphic.allAttributes objectForKey:@"2008 total SNAP benefits"], @"2008 total SNAP benefits",
                                         [mapGraphic.allAttributes objectForKey:@"2007 total SNAP benefits"], @"2007 total SNAP benefits",
                                         [mapGraphic.allAttributes objectForKey:@"2006 total SNAP benefits"], @"2006 total SNAP benefits",
                                         [mapGraphic.allAttributes objectForKey:@"2000 total SNAP benefits"], @"2000 total SNAP benefits",
                                        [mapGraphic.allAttributes objectForKey:@"2000 total SNAP benefits"], @"2000 total SNAP benefits",    
                                        [mapGraphic.allAttributes objectForKey:@"2010 average monthly SNAP benefit per resident"], @"2010 average monthly SNAP benefit per resident",                                        
                                        [mapGraphic.allAttributes objectForKey:@"2008 average monthly SNAP benefit per resident"], @"2008 average monthly SNAP benefit per resident",                                        
                                        [mapGraphic.allAttributes objectForKey:@"2006 average monthly SNAP benefit per resident"], @"2006 average monthly SNAP benefit per resident",
                                        [mapGraphic.allAttributes objectForKey:@"2000 average monthly SNAP benefit per resident"], @"2000 average monthly SNAP benefit per resident",                                             
                                        [mapGraphic.allAttributes objectForKey:@"2010 average monthly SNAP benefit per participant"],@"2010 average monthly SNAP benefit per participant",                                             
                                        [mapGraphic.allAttributes objectForKey:@" 2009 average monthly SNAP benefit per participant"], @" 2009 average monthly SNAP benefit per participant",                                             
                                        [mapGraphic.allAttributes objectForKey:@" 2008 average monthly SNAP benefit per participant"], @" 2008 average monthly SNAP benefit per participant",                                            
                                        [mapGraphic.allAttributes objectForKey:@"2007 average monthly SNAP benefit per resident"], @"2007 average monthly SNAP benefit per participant",                                             
                                        [mapGraphic.allAttributes objectForKey:@"2006 average monthly SNAP benefit per resident"], @"2006 average monthly SNAP benefit per participant",
                                        [mapGraphic.allAttributes objectForKey:@"2000 average monthly SNAP benefit per resident"], @"2000 average monthly SNAP benefit per participant",
                                         nil];
        
     //   NSDictionary *attributesDict = [[NSDictionary alloc]initWithObjectsAndKeys:
     //                                        [mapGraphic.allAttributes objectForKey:@"FIPSTXT"],  @"FIPSTXT", nil];
        
    //    NSDictionary *attributesDict1 = [[NSDictionary alloc]initWithObjectsAndKeys:
    //                                    [mapGraphic.allAttributes objectForKey:@"County"],  @"County", nil];
 //
        
    //    NSArray *attributesArray = [NSArray arrayWithObjects:attributesDict, attributesDict1, nil];
    //    resultsVC.resultsArray = attributesArray;

    resultsVC.results = finalAttributesDict;
        
        // you want to filter the results so only 1 sub-layer is shown instead of all the titles
        // TODO: how to sort the items so they display correctly?
        
        //display the results vc modally -- everything in the dictionary will be displayed
        
        // TODO: try this again, or use class where one instance equals a datapoint??
        /*
       NSMutableArray *objectArray = [[NSMutableArray alloc] init];
        
        NSMutableDictionary *object1 = [[NSMutableDictionary alloc] init];
        [object1 setObject:@"Apple" forKey:@"thing"];
        [object1 setObject:@"Alex" forKey:@"person"];
        [object1 setObject:@"Alabama" forKey:@"place"];
        [object1 setObject:@"Azure" forKey:@"color"];
        [objectArray addObject:object1];
        
        NSMutableDictionary *object2 = [[NSMutableDictionary alloc] init];
        [object2 setObject:@"Banana" forKey:@"thing"];
        [object2 setObject:@"Bill" forKey:@"person"];
        [object2 setObject:@"Boston" forKey:@"place"];
        [object2 setObject:@"Blue" forKey:@"color"];
        [objectArray addObject:object2];
        
        NSArray *datasourceArray = [NSArray arrayWithArray:objectArray];
        resultsVC.resultsArray = datasourceArray;
        // what is datasource? - must be an array
        [self presentViewController:datasourceArray animated:YES completion:NULL];
        */
        [self presentViewController:resultsVC animated:YES completion:NULL];
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

#pragma mark 

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	return YES;
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
	
	self.graphicsLayer = nil;
	self.identifyTask = nil;
	self.identifyParams = nil;
	self.mapView = nil;
	
    [super dealloc];
}

@end
