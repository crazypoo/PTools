//
//  PTChatMapCell.swift
//  LiXinCEO
//
//  Created by 邓杰豪 on 2024/4/1.
//

import UIKit
import MapKit
import SnapKit

public class PTChatMapCell: PTChatBaseCell {
    public static let ID = "PTChatMapCell"

    public var cellModel:PTChatListModel! {
        didSet {
            setBaseSubsViews(cellModel: cellModel)
            dataContentSets(cellModel: cellModel)
        }
    }
        
    lazy var appleMap:UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
        
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func dataContentSets(cellModel:PTChatListModel) {

        dataContent.viewCorner(radius: PTChatConfig.share.mapMessageImageCorner)
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
            dataContent.addSubviews([appleMap])
            appleMap.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        
            let location2D = CLLocationCoordinate2D(latitude: lat.double()!, longitude: lng.double()!)
            setBaseMapView(location2D: location2D)
        }
        
        resetSubsFrame(cellModel: cellModel)
    }
    
    func setBaseMapView(location2D:CLLocationCoordinate2D) {
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
            self.appleMap.image = composedImage
        }

    }
}
