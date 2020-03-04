//
//  ViewController.m
//  FindPlacesNearMe
//
//  Copyright © 2020 Amor Rio. All rights reserved.
//

#import "ViewController.h"
#import "CoreDataHelper.h"
#import "Place+CoreDataProperties.h"
#import "AppDelegate.h"

@interface ViewController ()
//views
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *searchingIndicator;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;
@property (weak, nonatomic) IBOutlet UIButton *refreshButton;

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSArray *currentAnnotations;
@property (strong, nonatomic) NSString *currentSearchString;
@property (strong, nonatomic) CoreDataHelper *dbHelper;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([CLLocationManager locationServicesEnabled])
    {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [self.locationManager requestWhenInUseAuthorization];
        
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways ||
            [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)
        {
            self.mapView.showsUserLocation = YES;
        }
    }
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.dbHelper = [[CoreDataHelper alloc] initWithManagedObjectContext:appDelegate.persistentContainer.viewContext];
}

- (IBAction)refreshButtonHit:(id)sender {
    [self performSearch];
}

- (IBAction)resetButonHit:(id)sender {
    if ([self.currentAnnotations count] > 0){
        
        for (id<MKAnnotation> annotation in self.mapView.selectedAnnotations)
        {
            [self.mapView deselectAnnotation:annotation animated:NO];
        }
        
        [self.mapView showAnnotations:self.currentAnnotations animated:YES];
    }

}
#pragma mark MKMapViewDelegate Methods

- (MKAnnotationView *)mapView:(MKMapView *)mapView 
            viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]])
    {
        //use system view for user's current location
        return nil;
    }
    
    NSString *identifier = @"MyAnnotation";
    MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
    
    if (annotationView == nil)
    {
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        annotationView.canShowCallout = YES;
    }
    else
    {
        [annotationView setAnnotation:annotation];
    }
    
    return annotationView;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray<MKAnnotationView *> *)views
{
    //when the annotations are already shown in map, stop the searching indicator
    //and enable user interaction
    [self didEndSearch];
    self.resetButton.enabled = YES;
}


#pragma mark - CLLocationManagerDelegate Methods

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)
    {
        self.mapView.showsUserLocation = YES;
    }
}


#pragma mark - UISearchBarDelegate Methods

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    //hide the keyboard
    [searchBar resignFirstResponder];

    //remove leading and trailing white spaces
    NSString *textToSearch = [searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (textToSearch == nil || [textToSearch length] == 0)
    {
        self.currentSearchString = nil;
        return;
    }

    self.currentSearchString = textToSearch;
    
    [self performSearch];
    

}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    //if the search is cancelled, hide the keyboard
    [searchBar resignFirstResponder];
}

#pragma mark - Utility Methods

-(void)addAnnotationsToMapView:(NSArray *)annotations
{
    if (annotations == nil || [annotations count]  == 0)
    {
        [self showErrorSearchAlertWithMessage:@"Place with name is not found within the area"];
        [self didEndSearch];
        return;
    }
    
    self.currentAnnotations = annotations;
    [self.mapView addAnnotations:annotations];
    //this adjusts the view to visibly show all annotations in the map
    [self.mapView showAnnotations:annotations animated:YES];
}

- (void)performSearchForSearchString:(NSString *) searchString
{
    NSURL *requestURL = [self createPlaceRestAPIRequestURLForSearchString:searchString coordinate:self.mapView.userLocation.coordinate];
    
    NSMutableURLRequest *request= [NSMutableURLRequest requestWithURL:requestURL];
    
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200)
        {
            NSError *error;
            NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            
            NSArray *annotations = [self annotationsForSearchResult:result];
            if (annotations != nil)
            {
                //perform in main queue
                [self performSelectorOnMainThread:@selector(addAnnotationsToMapView:) withObject:annotations waitUntilDone:NO];
            }
        }
        else {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showErrorSearchAlertWithMessage:@"Searching failed"];
                [self didEndSearch];
            });
        }
    }];
    
    [dataTask resume];
}

- (void)performSearch
{
    if (self.currentSearchString == nil)
    {
        return;
    }
    
    [self.mapView removeAnnotations:self.currentAnnotations];
    self.currentAnnotations = nil;
    NSArray *places = [self.dbHelper placesForSearchString:self.currentSearchString coordinate:self.mapView.userLocation.location.coordinate];
    if (places && [places count] > 0){
        self.currentAnnotations = [self annotationsForPlaces:places];
        [self addAnnotationsToMapView:self.currentAnnotations];
        return;
    }
    
    self.refreshButton.enabled = NO;
    self.resetButton.enabled = NO;
    //show activity indicator while searching
    [self.searchingIndicator startAnimating];
    //disable interaction with the search bar and the map
    self.mapView.userInteractionEnabled = NO;
    self.searchBar.userInteractionEnabled = NO;
    
    [self performSearchForSearchString:self.currentSearchString];
}

- (NSURL *)createPlaceRestAPIRequestURLForSearchString:(NSString *)searchString coordinate:(CLLocationCoordinate2D)coordinate
{
    //build request URL using NSURLComponents
    //initialize with the Places Search Rest API URL
    NSURLComponents *restAPIURLComponents = [NSURLComponents componentsWithString:@"https://places.demo.api.here.com/places/v1/discover/search"];
    //add search parameters
    NSURLQueryItem *searchItem = [[NSURLQueryItem alloc] initWithName:@"q" value:searchString];
    //maximum of 10 results
    NSURLQueryItem *searchSize = [[NSURLQueryItem alloc] initWithName:@"size" value:@"10"];
    //search area within 5km around the current location
    NSString *areaSpecification = [NSString stringWithFormat:@"%lf,%lf;r=5000", coordinate.latitude, coordinate.longitude];
    NSURLQueryItem *searchArea = [[NSURLQueryItem alloc] initWithName:@"in" value:areaSpecification];
    
    //authentication credentials for demo account
    NSURLQueryItem *app_id = [[NSURLQueryItem alloc] initWithName:@"app_id" value:@"DemoAppId01082013GAL"];
    NSURLQueryItem *app_code = [[NSURLQueryItem alloc] initWithName:@"app_code" value:@"AJKnXv84fjrb0KIHawS0Tg"];
    
    //add the parameters
    NSArray *queryItems = [NSArray arrayWithObjects:searchItem, searchSize, searchArea, app_id, app_code, nil];
    [restAPIURLComponents setQueryItems:queryItems];
    
    return [restAPIURLComponents URL];
}

-(NSArray *)annotationsForPlaces:(NSArray *)places
{
    NSMutableArray *annotations = [[NSMutableArray alloc] init];
    
    for (Place *place in places){
         CLLocationCoordinate2D coordinate;
        coordinate.latitude = place.latitude;
        coordinate.longitude =place.longitude;
        
   
        NSString *distanceUnit = @"meters";
        double distanceDivisor = 1.0f;
        if ((place.distance - 1000.0f) > 0.0001f )
        {
            distanceDivisor = 1000;
            distanceUnit = @"km";
            
        }
        //set subtitle to distance description from location of user
        NSString *subTitle = [NSString stringWithFormat:@"%g %@ away", place.distance/distanceDivisor, distanceUnit];
        
        MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
        annotation.coordinate = coordinate;
        //title and subtitle will show in callout when pins are tapped
        annotation.title = [NSString stringWithFormat:@"%@ %@", place.title, place.vicinity];
        annotation.subtitle = subTitle;
        
        
        [annotations addObject:annotation];
    }
    return annotations;
}

- (NSArray*)annotationsForSearchResult:(NSDictionary *)searchResult
{
    NSArray *places = [self.dbHelper placesForSearchResult:searchResult searchString:self.currentSearchString coordinate:self.mapView.userLocation.location.coordinate];
    
    return [self annotationsForPlaces:places];
}

-(void)showErrorSearchAlertWithMessage:(NSString *)errorMessage
{
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:appName message:errorMessage preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    [alertController addAction:action];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}

- (void)didEndSearch
{
    [self.searchingIndicator stopAnimating];
    self.refreshButton.enabled = YES;
    self.mapView.userInteractionEnabled = YES;
    self.searchBar.userInteractionEnabled = YES;
}

@end
