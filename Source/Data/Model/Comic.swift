//
//  Comic.swift
//  xkcd
//
//  Created by Thanh Huy Nguyen on 5/10/22.
//

import Foundation

struct Comic: Decodable {
    let id: Int
    let title: String
    let imageURL: URL
    let alternativeText: String
    
    enum CodingKeys: String, CodingKey {
        case id = "num"
        case title
        case imageURL = "img"
        case alternativeText = "alt"
    }
}
