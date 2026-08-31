//
//  PTChatMapCell.swift
//  LiXinCEO
//
//  Created by 邓杰豪 on 2024/4/1.
//

import UIKit
import MapKit
import SnapKit

@MainActor
public class PTChatMapCell: PTChatBaseCell {
    public static let ID = "PTChatMapCell"

    private var mapGeneration = 0
    private var snapshotter: MKMapSnapshotter?

    public var cellModel:PTChatListModel! {
        didSet {
            guard let cellModel else { return }
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
        super.init(coder: coder)
        setupSubviews()
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        mapGeneration += 1
        snapshotter?.cancel()
        snapshotter = nil
        appleMap.image = PTAppBaseConfig.share.defaultEmptyImage
        cellModel = nil
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
        mapGeneration += 1
        snapshotter?.cancel()
        snapshotter = nil
        appleMap.image = PTAppBaseConfig.share.defaultEmptyImage
        setBaseSubviews(cellModel: cellModel)
        updateConstraintsForCellModel(cellModel)
        configureMapContent(cellModel: cellModel, generation: mapGeneration)
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
    
    private func configureMapContent(cellModel: PTChatListModel, generation: Int) {
        let location: CLLocationCoordinate2D
        switch cellModel.msgContent {
        case let dictionary as NSDictionary:
            location = coordinate(from: dictionary) ?? .init(latitude: 0, longitude: 0)
        case let string as String:
            if let coordinates = string.asCoordinates {
                location = coordinates
            } else if let dictionary = string.jsonStringToDic() {
                location = coordinate(from: dictionary) ?? .init(latitude: 0, longitude: 0)
            } else {
                location = .init(latitude: 0, longitude: 0)
            }
        default:
            location = .init(latitude: 0, longitude: 0)
        }
        setBaseMapView(location2D: location, generation: generation)
    }

    private func coordinate(from dictionary: NSDictionary) -> CLLocationCoordinate2D? {
        func value(for key: String) -> Double? {
            if let number = dictionary[key] as? NSNumber {
                return number.doubleValue
            }
            if let string = dictionary[key] as? String {
                return Double(string)
            }
            return nil
        }

        guard let latitude = value(for: "lat"),
              let longitude = value(for: "lng"),
              latitude.isFinite, longitude.isFinite,
              (-90...90).contains(latitude),
              (-180...180).contains(longitude) else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    private func setBaseMapView(location2D:CLLocationCoordinate2D, generation: Int) {
        let pinImage = PTChatConfig.share.mapCellPinImage
        let annotationView = MKAnnotationView(annotation: nil, reuseIdentifier: nil)
        annotationView.image = pinImage
        annotationView.centerOffset = CGPoint(x: 0,y: -pinImage.size.height / 2)
        
        let snapshotOptions = MKMapSnapshotter.Options()
        snapshotOptions.region = MKCoordinateRegion(center: location2D, span: PTChatConfig.share.span)
        snapshotOptions.showsBuildings = PTChatConfig.share.showBuilding
        snapshotOptions.pointOfInterestFilter = PTChatConfig.share.showsPointsOfInterest ? .includingAll : .excludingAll
        snapshotOptions.size = CGSize(width: PTChatConfig.share.mapMessageImageWidth,
                                      height: PTChatConfig.share.mapMessageImageHeight)
        let snapShotter = MKMapSnapshotter(options: snapshotOptions)
        snapshotter = snapShotter
        snapShotter.start { [weak self] snapshot, error in
            guard let self,
                  self.mapGeneration == generation,
                  let snapshot,
                  error == nil else {
              return
            }

            var point = snapshot.point(for: location2D)
            point.x -= annotationView.bounds.size.width / 2
            point.y -= annotationView.bounds.size.height / 2
            point.x += annotationView.centerOffset.x
            point.y += annotationView.centerOffset.y

            let renderer = UIGraphicsImageRenderer(size: snapshotOptions.size)
            self.appleMap.image = renderer.image { _ in
                snapshot.image.draw(at: .zero)
                annotationView.image?.draw(at: point)
            }
            if self.snapshotter === snapShotter {
                self.snapshotter = nil
            }
        }
    }
}
