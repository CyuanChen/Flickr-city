//
//  Utilities.swift
//  Pixel city
//
//  Created by PeterChen on 2017/8/31.
//  Copyright © 2017年 PeterChen. All rights reserved.
//

import Foundation


let apiKey = "db1c23ffa724bcfd950bde9c9729ab0c"

func flickrUrl(forAPIKey key: String, withAnnotation annotation: DroppablePin, andNumberOfPhotos number: Int ) -> String {
    return "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=km&per_page=\(number)&format=json&nojsoncallback=1"
}



//https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=a4b3a628d83dff3ea81678a09ca65900&lat=42.8&lon=122.8&radius=1&radius_units=km&page=40&format=json&nojsoncallback=1&auth_token=72157685457929001-efbd14f72adfa857&api_sig=ab65c76f3ccf25fdb9dc5cc478da200e
