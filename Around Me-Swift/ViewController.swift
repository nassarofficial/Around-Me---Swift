//
//  ViewController.swift
//  Around Me-Swift
//
//  Created by Nio Nguyen on 6/5/15.
//  nio.huynguyen@gmail.com
//  Copyright (c) 2015 Nio Nguyen. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    let locationManager = CLLocationManager()
    var updatingLocation = false
    @IBOutlet weak var _mapView: MKMapView!
    var locations = [Place]()
    var currentLocation : CLLocation?
    var datas: [JSON] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        let authStatus : CLAuthorizationStatus = CLLocationManager.authorizationStatus()
        if authStatus == .NotDetermined {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        
        if authStatus == .Denied || authStatus == .Restricted {
            showLocationServicesDeniedAlert()
            return
        }
        
        if updatingLocation {
            stopLocationManager()
        } else {
            startLocationManager()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func showLocationServicesDeniedAlert() {
        let alert = UIAlertController(title: "Location Services Disabled", message: "Please enable location services for this app in Settings.", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(okAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func startLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
        }
    }
    
    func stopLocationManager() {
        if updatingLocation {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        
        var lastLocation = locations.last as! CLLocation
        if (currentLocation == nil) {
            randomLocation(lastLocation, number: 10)
        }
        currentLocation = lastLocation

        var accuracy:CLLocationAccuracy = lastLocation.horizontalAccuracy
        if(accuracy < 100.0) {
            var span:MKCoordinateSpan = MKCoordinateSpanMake(0.14 / 10, 0.14 / 10);
            var region:MKCoordinateRegion = MKCoordinateRegionMake(lastLocation.coordinate,span)
            self._mapView.setRegion(region, animated: true)
        }
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        self._mapView.showsUserLocation = true
    }
    
    func randomLocation(location:CLLocation, number:Int) {
        Alamofire.request(.GET, "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(location.coordinate.latitude),\(location.coordinate.longitude)&radius=1000&key=APIKEY").responseJSON { (request, response, json, error) in
            if json != nil {
                var jsonObj = JSON(json!)
                if let data = jsonObj["results"].arrayValue as [JSON]?{
                    self.datas = data
                }
                for var i = 0; i < self.datas.count; i++
                {
                    let data = self.datas[i]

                  // var MomentaryLatitude = (self.datas[i]["location"]["lat"].string! as NSString).doubleValue
                    
                    var newLocation = CLLocation(latitude: self.datas[i]["geometry"]["location"]["lat"].doubleValue, longitude: self.datas[i]["geometry"]["location"]["lng"].doubleValue)
                    var place = Place(_location: newLocation!, _reference: "_reference", _placeName: data["name"].string!, _address: "test", _phoneNumber: "_phoneNumber", _website: "_website")
                    self.locations.append(place)
                    
                }
                self.showLocations()

            }
        }

      
    }

    @IBAction func addLoctionAction() {
        if (currentLocation != nil) {
            var place = Place(_location: currentLocation!, _reference: "_reference", _placeName: "Nio Nguyen's home", _address: "_address", _phoneNumber: "_phoneNumber", _website: "_website")
            locations.append(place)
        }
        showLocations()
    }
    
    func showLocations() {
        _mapView.addAnnotations(locations)
    }
    
    @IBAction func cameraAction () {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        
        let flipsideViewController = storyBoard.instantiateViewControllerWithIdentifier("FlipsideViewController") as! FlipsideViewController
        flipsideViewController.locations = locations
        flipsideViewController.userLocation = _mapView.userLocation
        self.presentViewController(flipsideViewController, animated:true, completion:nil)
    }
}

