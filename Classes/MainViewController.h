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
// ESRI sources: Geocoding Sample, TableOfContentsSample

// DESCRIPTION: Food Research Atlas - search bar, table of contents, popup location for iPad and iPhone

#import <UIKit/UIKit.h>
#import <ArcGIS/ArcGIS.h>

@interface MainViewController : UIViewController <AGSMapViewLayerDelegate, UISearchBarDelegate, AGSLocatorDelegate, AGSCalloutDelegate, AGSMapViewTouchDelegate, AGSIdentifyTaskDelegate > {
	AGSMapView *_mapView;
	UIButton* _infoButton;
    
    // find adddress feature
    UISearchBar *_searchBar;
    AGSGraphicsLayer *_graphicsLayer;
	AGSLocator *_locator;
	AGSCalloutTemplate *_calloutTemplate;
    
    //Only used with iPad
	UIPopoverController* _popOverController;
    
    // location popup
    //AGSMapView *_mapView;
	//AGSGraphicsLayer *_graphicsLayer;
    AGSGraphic *_graphic;
	AGSIdentifyTask *_identifyTask;
	AGSIdentifyParameters *_identifyParams;
    AGSPoint* _mappoint;
}

@property (nonatomic, strong) IBOutlet AGSMapView *mapView;
@property (nonatomic, strong) IBOutlet UIButton* infoButton;
@property (nonatomic, strong) UIPopoverController *popOverController;

// find address feature
@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) AGSGraphicsLayer *graphicsLayer;
@property (nonatomic, strong) AGSLocator *locator;
@property (nonatomic, strong) AGSCalloutTemplate *calloutTemplate;

// location popup
//@property (nonatomic, retain) IBOutlet AGSMapView *mapView;
//@property (nonatomic, retain) AGSGraphicsLayer *graphicsLayer;
@property (nonatomic, retain) AGSIdentifyTask *identifyTask;
@property (nonatomic, retain) AGSIdentifyParameters *identifyParams;
@property (nonatomic, retain) AGSPoint* mappoint;
@property (nonatomic, retain) AGSGraphic *graphic;

- (IBAction)presentTableOfContents:(id)sender;

//This is the method that starts the geocoding operation
- (void)startGeocoding;

@end

