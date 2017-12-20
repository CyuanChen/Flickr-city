//
//  MapViewController.swift
//  Pixel city
//
//  Created by PeterChen on 2017/8/31.
//  Copyright © 2017年 PeterChen. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Alamofire
import AlamofireImage

class MapViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var pullUpViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var pullUpView: UIView!
    
    var locationManager = CLLocationManager()
    let autherizationStatus = CLLocationManager.authorizationStatus()
    let regionRadius: Double = 1000
    
    var screenSize = UIScreen.main.bounds
    
    var spinner: UIActivityIndicatorView?
    var progressLbl: UILabel?
    var flowLayout = UICollectionViewFlowLayout()
    var collectionView: UICollectionView?
    
    var imageUrlArray = [String]()
    var imageArray = [UIImage]()
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        configureLocationService()
        addDoubleTap()
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "photoCell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        registerForPreviewing(with: self, sourceView: collectionView!)
        
        pullUpView.addSubview(collectionView!)
        

        // Do any additional setup after loading the view.
    }

    @IBAction func centerMapBtnWasPressed(_ sender: Any) {
        if autherizationStatus == .authorizedAlways || autherizationStatus == .authorizedWhenInUse {
            centerMapOnUserLocation()
        }
    }
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin(sender:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        mapView.addGestureRecognizer(doubleTap)
    }

    func addSwipe() {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(animateViewDown))
        swipe.direction = .down
        pullUpView.addGestureRecognizer(swipe)
    }
    
    func animateViewUp() {
        pullUpViewHeightConstraint.constant = 300
        UIView.animate(withDuration: 0.3) {
            // let view height from 1 to 300
            self.view.layoutIfNeeded()
        }
    }
    
    @objc  func animateViewDown() {
        pullUpViewHeightConstraint.constant = 1
        UIView.animate(withDuration: 0.3) { 
            self.view.layoutIfNeeded()
        }
        
    }
    
    func addSpinner() {
        spinner = UIActivityIndicatorView()
        spinner?.center = CGPoint(x: (screenSize.width / 2) - ((spinner?.frame.width)! / 2), y: 150)
        spinner?.activityIndicatorViewStyle = .whiteLarge
        spinner?.color = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        spinner?.startAnimating()
        collectionView?.addSubview(spinner!)
        
    }
    
    func removeSpinner() {
        if spinner != nil {
            spinner?.removeFromSuperview()
        }
    }
    
    func addProgressLbl() {
        progressLbl = UILabel()
        progressLbl?.frame = CGRect(x: (screenSize.width / 2) - 120, y: 175, width: 240, height: 40)
        progressLbl?.font = UIFont(name: "Avenir Next", size: 14)
        progressLbl?.textColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        progressLbl?.textAlignment = .center
        collectionView?.addSubview(progressLbl!)
    }
    
    func removeProgressLbl() {
        if progressLbl != nil {
            progressLbl?.removeFromSuperview()
        }
    }

  

}

extension MapViewController: MKMapViewDelegate
{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // User location doesn't need drop an annotation
        if annotation is MKUserLocation {
            return nil
        }
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
        pinAnnotation.pinTintColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
        pinAnnotation.animatesDrop = true
        return pinAnnotation
    }
    
    func centerMapOnUserLocation() {
        guard let coordinate = locationManager.location?.coordinate else { return
    }
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
   @objc func dropPin(sender: UIGestureRecognizer) {
        removePin()
        removeSpinner()
        removeProgressLbl()
        cancelAllSessions()
        
        collectionView?.reloadData()
        
        imageArray = []
        imageUrlArray = []
        
        let touchPoint = sender.location(in: mapView)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = DroppablePin(coordinate: touchCoordinate, identifier: "droppablePin")
        mapView.addAnnotation(annotation)
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(touchCoordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
        
        
        
        animateViewUp()
        addSwipe()
        addSpinner()
        addProgressLbl()
        
        print(flickrUrl(forAPIKey: apiKey, withAnnotation: annotation, andNumberOfPhotos: 40))
        retrieveUrls(forAnnotation: annotation) { (finished) in
            if finished {
                self.retrieveImages(handler: { (finished) in
                    if finished {
                        self.removeSpinner()
                        self.removeProgressLbl()
                        self.collectionView?.reloadData()
                    }
                })
            }
        }
        
        
        
    }
    
    func removePin() {
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
    }
    
    
    func retrieveUrls(forAnnotation annotation: DroppablePin, handler: @escaping (_ status: Bool) -> ()) {
        Alamofire.request(flickrUrl(forAPIKey: apiKey, withAnnotation: annotation, andNumberOfPhotos: 40)).responseJSON { (response) in
            guard let json = response.result.value as? Dictionary<String, AnyObject> else { return }
            let photosDict = json["photos"] as! Dictionary<String, AnyObject>
            let photosDictArray = photosDict["photo"] as! [Dictionary<String, AnyObject>]
            for photo in photosDictArray {
                let postUrl = "https://farm\(photo["farm"]!).staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!)_h_d.jpg"
                
                self.imageUrlArray.append(postUrl)
            }
            handler(true)
        }
    }
    
    func retrieveImages(handler: @escaping (_ status: Bool) -> ()) {
        for url in imageUrlArray {
            Alamofire.request(url).responseImage(completionHandler: { (response) in
                guard let image = response.result.value else { return }
                self.imageArray.append(image)
                self.progressLbl?.text = "\(self.imageArray.count)/40 IMAGES DOWNLOADED"
                
                if self.imageArray.count == self.imageUrlArray.count {
                    handler(true)
                }
            })
        }
    }
    
    
    
    
    func cancelAllSessions() {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
            sessionDataTask.forEach({ $0.cancel()})
            downloadData.forEach({ $0.cancel()})
        }
    }
    
    
    
}

extension MapViewController: CLLocationManagerDelegate
{
    func configureLocationService() {
        if autherizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else {
            return
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnUserLocation()
    }
}

extension MapViewController: UICollectionViewDelegate, UICollectionViewDataSource
{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArray.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoCell else { return UICollectionViewCell() }
        let imageFromIndex = imageArray[indexPath.row]
        let imageView = UIImageView(image: imageFromIndex)
        cell.addSubview(imageView)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let popViewController = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopViewController else { return }
        popViewController.initData(forImage: imageArray[indexPath.row])
        present(popViewController, animated: true, completion: nil)
        
        
    }
}

extension MapViewController: UIViewControllerPreviewingDelegate
{
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = collectionView?.indexPathForItem(at: location), let cell = collectionView?.cellForItem(at: indexPath) else { return nil}
        guard let popVC = self.storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopViewController  else { return nil}
        popVC.initData(forImage: imageArray[indexPath.row])
        previewingContext.sourceRect = cell.contentView.frame
        return popVC
    }
}










