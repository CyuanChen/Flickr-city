//
//  DroppablePin.swift
//  Pixel city
//
//  Created by PeterChen on 2017/8/31.
//  Copyright © 2017年 PeterChen. All rights reserved.
//

import UIKit
import MapKit

class DroppablePin: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var identifier: String
    
    
    init(coordinate: CLLocationCoordinate2D, identifier: String) {
        self.coordinate = coordinate
        self.identifier = identifier
        // after set coordinate and id, super init
        super.init()
    }
}
