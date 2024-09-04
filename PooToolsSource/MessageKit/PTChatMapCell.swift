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
            updateCellModel(cellModel: cellModel)
        }
    }
        
    private lazy var appleMap:UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
        
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 提前设置视图和约束
    private func setupSubviews() {
        dataContent.addSubview(appleMap)
        appleMap.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // 更新 cellModel 时的逻辑
    private func updateCellModel(cellModel: PTChatListModel) {
        setBaseSubviews(cellModel: cellModel)
        updateConstraintsForCellModel(cellModel)
        configureMapContent(cellModel: cellModel)
    }

    private func updateConstraintsForCellModel(_ cellModel: PTChatListModel) {
        dataContent.viewCorner(radius: PTChatConfig.share.mapMessageImageCorner)
        dataContent.snp.remakeConstraints { make in
            if cellModel.belongToMe {
                make.right.equalTo(self.userIcon.snp.left).offset(-PTChatBaseCell.dataContentUserIconInset)
            } else {
                make.left.equalTo(self.userIcon.snp.right).offset(PTChatBaseCell.dataContentUserIconInset)
            }
            make.top.equalTo(self.senderNameLabel.snp.bottom)
            make.height.equalTo(PTChatConfig.share.mapMessageImageHeight)
            make.width.equalTo(PTChatConfig.share.mapMessageImageWidth)
        }
    }
    
    private func configureMapContent(cellModel: PTChatListModel) {
        guard let _ = cellModel.msgContent else { return }

        var dic:NSDictionary?
        if cellModel.msgContent is NSDictionary {
            dic = (cellModel.msgContent as! NSDictionary)
        } else if cellModel.msgContent is String {
            let addressString = cellModel.msgContent as! String
            dic = addressString.jsonStringToDic()
        }
        
        if dic != nil {
            let lat = (dic!["lat"] as? String) ?? "0"
            let lng = (dic!["lng"] as? String) ?? "0"
        
            let location2D = CLLocationCoordinate2D(latitude: lat.double() ?? 0, longitude: lng.double() ?? 0)
            setBaseMapView(location2D: location2D)
        }

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
        snapShotter.start { [weak self] snapshot, error in
            guard let self = self, let snapshot = snapshot, error == nil else {
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
