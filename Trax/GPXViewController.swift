//
//  GPXViewController.swift
//  Trax
//
//  Created by CS193p Instructor.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//
//  Adapted to Swift 5

import UIKit
import MapKit

class GPXViewController: UIViewController, MKMapViewDelegate, UIPopoverPresentationControllerDelegate {
    
    
    var gpxURL: URL? {
        didSet {
            clearWaypoints()
            if let url = gpxURL {
                print("url = gpxURL")
                GPX.parse(url: url) { gpx in
                    if gpx != nil {
                        self.addWaypoints(waypoints: gpx!.waypoints)
                        print (gpx!.waypoints)
                    }
                }
            }
        }
    }
    
    private func clearWaypoints() {
        mapView?.removeAnnotations(mapView.annotations)
    }
    
    private func addWaypoints(waypoints: [GPX.Waypoint]) {
        for n in 0 ... (waypoints.count - 1) {
          mapView?.addAnnotation(waypoints[n]) }
        mapView?.showAnnotations(waypoints, animated: true)
       // print(waypoints)
    }
    
    // MARK: MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var view: MKAnnotationView! = mapView.dequeueReusableAnnotationView(withIdentifier: Constants.AnnotationViewReuseIdentifier)
        if view == nil {
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: Constants.AnnotationViewReuseIdentifier)
            view.canShowCallout = true
        } else {
            view.annotation = annotation
        }
        
        view.isDraggable = annotation is EditableWaypoint
        
        view.leftCalloutAccessoryView = nil
        view.rightCalloutAccessoryView = nil
        if let waypoint = annotation as? GPX.Waypoint {
            if waypoint.thumbnailURL != nil {
                view.leftCalloutAccessoryView = UIButton(frame: Constants.LeftCalloutFrame)
            }
            if waypoint is EditableWaypoint {
                view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            }
        }
        return view
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let thumbnailImageButton = view.leftCalloutAccessoryView as? UIButton,
            let url = (view.annotation as? GPX.Waypoint)?.thumbnailURL,
            let imageData = NSData(contentsOf: url),
            let image = UIImage(data: imageData as Data) {
            thumbnailImageButton.setImage(image, for: .normal)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        gpxURL = URL(string: "http://cs193p.stanford.edu/Vacation.gpx")
    }

    @IBOutlet weak var mapView: MKMapView! {
        didSet {
        mapView.mapType = .satellite
        mapView.delegate = self
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.leftCalloutAccessoryView {
            performSegue(withIdentifier: Constants.ShowImageSegue, sender: view)
        } else if control == view.rightCalloutAccessoryView {
            mapView.deselectAnnotation(view.annotation, animated: true)
            performSegue(withIdentifier: Constants.EditUserWaypoint, sender: view)
        }
    }
    
    // MARK: Navigation
    
    @IBAction func updatedUserWaypoint(segue: UIStoryboardSegue) {
        selectWaypoint(waypoint: (segue.source.contentViewController as? EditWaypointViewController)?.waypointToEdit)
    }
    
    private func selectWaypoint(waypoint: GPX.Waypoint?) {
        if waypoint != nil {
            mapView.selectAnnotation(waypoint!, animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination.contentViewController
        let annotationView = sender as? MKAnnotationView
        let waypoint = annotationView?.annotation as? GPX.Waypoint
        
        if segue.identifier == Constants.ShowImageSegue {
            if let ivc = destination as? ImageViewController {
                ivc.imageURL = waypoint?.imageURL
                ivc.title = waypoint?.name
            }
        } else if segue.identifier == Constants.EditUserWaypoint {
            if let editableWaypoint = waypoint as? EditableWaypoint,
                let ewvc = destination as? EditWaypointViewController {
                if let ppc = ewvc.popoverPresentationController {
                    ppc.sourceRect = annotationView!.frame
                    ppc.delegate = self
                }
                ewvc.waypointToEdit = editableWaypoint
            }
        }
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        selectWaypoint(waypoint: (popoverPresentationController.presentedViewController as? EditWaypointViewController)?.waypointToEdit)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return traitCollection.horizontalSizeClass == .compact ? .overFullScreen: .none
    }
    
    func presentationController(_ controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        if style == .fullScreen || style == .overFullScreen {
            let navcon = UINavigationController(rootViewController: controller.presentedViewController)
            let visualEffectsView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
            visualEffectsView.frame = navcon.view.bounds
            visualEffectsView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
            navcon.view.insertSubview(visualEffectsView, at: 0)
            return navcon
        } else {
            return nil
        }
    }
    
    @IBAction func addWaypoint(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let coordinate = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)
            let waypoint = EditableWaypoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
            waypoint.name = "Dropped"
            mapView.addAnnotation(waypoint)
        }
    }
    
    // MARK: - Constants
    
    private struct Constants {
        static let LeftCalloutFrame = CGRect(x: 0, y: 0, width: 59, height: 59)
        static let AnnotationViewReuseIdentifier = "waypoint"
        static let ShowImageSegue = "Show Image"
        static let EditUserWaypoint = "Edit Waypoint"
    }
    
}

extension UIViewController {
    var contentViewController: UIViewController {
        if let navcon = self as? UINavigationController {
            return navcon.visibleViewController ?? navcon
        } else {
            return self
        }
    }
}
