//
//  PTDebugLocationMapViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/31.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import SafeSFSymbols
import MapKit

class PTDebugLocationMapViewController: PTBaseViewController {

    var locationCallBack:((CLLocation)->Void)?
    
    lazy var fakeNav:UIView = {
        let view = UIView()
        return view
    }()

    private var mapView: MKMapView?

    private var selectedLocationAnnotation: MKPointAnnotation?
    private var selectedLocation: CLLocation?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }

    // Handle back button press
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            // If the user is navigating back, but not pressing "Done", remove the selected location annotation
            selectedLocationAnnotation.map { mapView?.removeAnnotation($0) }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        selectedLocation = PTDebugLocationKit.shared.simulatedLocation
        
        setupMapView()
        setupGestureRecognizer()
        
        view.addSubviews([fakeNav,mapView!])
        fakeNav.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(20)
            make.height.equalTo(CGFloat.kNavBarHeight)
        }
        
        let button = UIButton(type: .custom)
        button.setImage(UIImage(.arrow.uturnLeftCircle), for: .normal)

        let doneButton = UIButton(type: .custom)
        doneButton.setImage(UIImage(.checkmark), for: .normal)

        fakeNav.addSubviews([button,doneButton])
        button.snp.makeConstraints { make in
            make.size.equalTo(34)
            make.top.equalToSuperview().inset(5)
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
        }
        button.addActionHandlers { sender in
            self.navigationController?.popViewController()
        }

        doneButton.snp.makeConstraints { make in
            make.size.centerY.equalTo(button)
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
        }
        
        doneButton.addActionHandlers { sender in
            if let selectedLocationCoordinate = self.selectedLocationAnnotation?.coordinate {
                let selectedLocation = CLLocation(latitude: selectedLocationCoordinate.latitude, longitude: selectedLocationCoordinate.longitude)
                self.locationCallBack?(selectedLocation)
            }
            self.navigationController?.popViewController()
        }
        
        mapView!.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(self.fakeNav.snp.bottom)
        }
    }
    
    private func setupMapView() {
        mapView = MKMapView()

        if let initialLocation = selectedLocation {
            let initialCoordinate = initialLocation.coordinate
            let annotation = MKPointAnnotation()
            annotation.coordinate = initialCoordinate
            mapView?.addAnnotation(annotation)

            let region = MKCoordinateRegion(
                center: initialCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30)
            )

            mapView?.setRegion(region, animated: true)
            mapView?.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private func setupGestureRecognizer() {
        let tapGesture = UITapGestureRecognizer() { sender in
            let gestureRecognizer = sender as! UITapGestureRecognizer
            guard let mapView  = self.mapView else { return }
            let locationInView = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(locationInView, toCoordinateFrom: mapView)

            if let selectedLocationAnnotation = self.selectedLocationAnnotation {
                selectedLocationAnnotation.coordinate = coordinate
            } else {
                self.selectedLocationAnnotation = MKPointAnnotation()
                self.selectedLocationAnnotation?.coordinate = coordinate
                self.selectedLocationAnnotation.map { mapView.removeAnnotation($0) }
                mapView.addAnnotation(self.selectedLocationAnnotation!)
            }
        }
        mapView?.addGestureRecognizer(tapGesture)
    }
}
