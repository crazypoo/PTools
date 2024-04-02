//
//  PTChatMapCell.swift
//  LiXinCEO
//
//  Created by 邓杰豪 on 2024/4/1.
//

import UIKit
#if canImport(GoogleMaps)
import GoogleMaps
#endif
import MapKit

public class PTChatMapCell: PTChatBaseCell {
    public static let ID = "PTChatMapCell"

    public var cellModel:PTChatListModel! {
        didSet {
            setBaseSubsViews(cellModel: cellModel)
            dataContentSets(cellModel: cellModel)
        }
    }
        
#if canImport(GoogleMaps)
    lazy var googleMap:GMSMapView = {
        let view = GMSMapView()
        view.isMyLocationEnabled = false
        view.settings.myLocationButton = false
        view.settings.scrollGestures = false
        view.settings.zoomGestures = false
        view.setMinZoom(16, maxZoom: 18)
        view.mapType = .normal
        view.isUserInteractionEnabled = false
        return view
    }()
#endif

    lazy var appleMap:UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    var mapContent:UIView!
    var locationPin:UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.image = PTChatConfig.share.mapCellPinImage
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func dataContentSets(cellModel:PTChatListModel) {
        userIcon.snp.remakeConstraints { make in
            make.size.equalTo(PTChatConfig.share.messageUserIconSize)
            if cellModel.belongToMe {
                make.right.equalToSuperview().inset(PTChatConfig.share.userIconFixelSpace)
            } else {
                make.left.equalToSuperview().inset(PTChatConfig.share.userIconFixelSpace)
            }
            make.top.equalTo(self.messageTimeLabel.snp.bottom).offset(PTChatBaseCell.TimeTopSpace)
        }

        senderNameLabel.snp.remakeConstraints { make in
            make.top.equalTo(self.userIcon)
            if cellModel.belongToMe {
                make.right.equalTo(self.userIcon.snp.left).offset(-PTChatBaseCell.DataContentUserIconFixel)
            } else {
                make.left.equalTo(self.userIcon.snp.right).offset(PTChatBaseCell.DataContentUserIconFixel)
            }
            
            make.height.equalTo(PTChatConfig.share.showSenderName ? PTChatBaseCell.NameHeight : 0)
        }

        dataContent.viewCorner(radius: PTChatConfig.share.mapMessageImageCorner)
        switch PTChatConfig.share.mapKit {
        case .Google:
#if canImport(GoogleMaps)
            mapContent = googleMap
#endif
        case .MapKit:
            mapContent = appleMap
        }
        dataContent.snp.makeConstraints { make in
            if cellModel.belongToMe {
                make.right.equalTo(self.userIcon.snp.left).offset(-PTChatBaseCell.DataContentUserIconFixel)
            } else {
                make.left.equalTo(self.userIcon.snp.right).offset(PTChatBaseCell.DataContentUserIconFixel)
            }
            make.top.equalTo(self.senderNameLabel.snp.bottom)
            make.height.equalTo(PTChatConfig.share.mapMessageImageHeight)
            make.width.equalTo(PTChatConfig.share.mapMessageImageWidth)
        }
        
        var dic:NSDictionary?
        if cellModel.msgContent is NSDictionary {
            dic = (cellModel.msgContent as! NSDictionary)
        } else if cellModel.msgContent is String {
            let addressString = cellModel.msgContent as! String
            dic = addressString.jsonStringToDic()
        }
        
        if dic != nil {
            let lat = dic!["lat"] as! String
            let lng = dic!["lng"] as! String
            dataContent.addSubviews([mapContent])
            mapContent.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        
            let location2D = CLLocationCoordinate2D(latitude: lat.double()!, longitude: lng.double()!)
            switch PTChatConfig.share.mapKit {
            case .Google:
#if canImport(GoogleMaps)
                let camera = GMSCameraPosition(target: location2D, zoom: 18)
                (mapContent as! GMSMapView).camera = camera
                
                mapContent.addSubviews([locationPin])
                locationPin.snp.makeConstraints { make in
                    make.size.equalTo(40)
                    make.centerY.centerX.equalToSuperview()
                }
#endif
            case .MapKit:
                let pinImage = PTChatConfig.share.mapCellPinImage
                let annotationView = MKAnnotationView(annotation: nil, reuseIdentifier: nil)
                annotationView.image = pinImage
                annotationView.centerOffset = CGPoint(x: 0,y: -pinImage.size.height / 2)
                
                let snapshotOptions = MKMapSnapshotter.Options()
                snapshotOptions.region = MKCoordinateRegion(center: location2D, span: PTChatConfig.share.span)
                snapshotOptions.showsBuildings = PTChatConfig.share.showBuilding
                snapshotOptions.pointOfInterestFilter = PTChatConfig.share.showsPointsOfInterest ? .includingAll : .excludingAll
                let snapShotter = MKMapSnapshotter(options: snapshotOptions)
                snapShotter.start { snapShot, error in
                    guard let snapshot = snapShot, error == nil else {
                      // show an error image?
                      return
                    }
                    
                    UIGraphicsBeginImageContextWithOptions(snapshotOptions.size, true, 0)

                    snapshot.image.draw(at: .zero)

                    var point = snapshot.point(for: location2D)
                    // Move point to reflect annotation anchor
                    point.x -= annotationView.bounds.size.width / 2
                    point.y -= annotationView.bounds.size.height / 2
                    point.x += annotationView.centerOffset.x
                    point.y += annotationView.centerOffset.y

                    annotationView.image?.draw(at: point)
                    let composedImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    (self.mapContent as! UIImageView).image = composedImage
                }
            }
        }
        
        waitImageView.snp.remakeConstraints { make in
            make.size.equalTo(PTChatBaseCell.WaitImageSize)
            if cellModel.belongToMe {
                make.right.equalTo(self.dataContent.snp.left).offset(-PTChatBaseCell.DataContentWaitImageFixel)
            } else {
                make.left.equalTo(self.dataContent.snp.right).offset(PTChatBaseCell.DataContentWaitImageFixel)
            }
            make.centerY.equalToSuperview()
        }
        waitImageView.addActionHandlers { sender in
            self.sendMesageError?(cellModel)
        }
        checkCellSendStatus(cellModel: cellModel)
    }
}
