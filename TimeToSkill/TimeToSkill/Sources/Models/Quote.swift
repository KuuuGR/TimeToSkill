//
//  Quote.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 10/04/2025.
//

import Foundation

struct Quote: Decodable, Identifiable {
    var id: UUID { UUID() }  // computed unique ID each time (fine for random display)
    let quote: String
    let author: String
}
