//
//  DirectionModel.swift
//  goeurotest
//
//  Created by Andras Kadar on 2017. 10. 16..
//  Copyright © 2017. andraskadar. All rights reserved.
//

import Foundation
import Realm
import RealmSwift
import ObjectMapper

final class DirectionModel: Object, ImmutableMappable {
  @objc dynamic var id: Int = 0
  @objc dynamic var providerLogoUrl: String?
  @objc dynamic var priceInEuros: Double = 0
  @objc dynamic var departureTime: Date?
  @objc dynamic var arrivalTime: Date?
  @objc dynamic var distanceTime: Date?
  @objc dynamic var numberOfStops: Int = 0
  @objc dynamic var vehicleTypeRaw: Int = 0
  
  init(map: Map) throws {
    super.init()
    
    id = try map.value("id")
    providerLogoUrl = try? map.value("provider_logo")
    
    // Price can be a number or a string
    if let valueString: String = try? map.value("price_in_euros"),
      let value = valueString.euroValue {
      priceInEuros = value
    } else if let value: Double = try? map.value("price_in_euros") {
      priceInEuros = value
    }
    
    if let valueString: String = try? map.value("departure_time"),
      let value = valueString.timeValue {
      departureTime = value
    }
    
    if let valueString: String = try? map.value("arrival_time"),
      let value = valueString.timeValue {
      arrivalTime = value
    }
    
    if let arrivalTime = arrivalTime,
      let departureTime = departureTime {
      distanceTime = Date(timeIntervalSince1970:
        arrivalTime.timeIntervalSince(departureTime))
    }
    
    numberOfStops = try map.value("number_of_stops")
  }
  
  func mapping(map: Map) { }
  
  func providerLogoUrl(for size: Int) -> URL? {
    guard let urlString = providerLogoUrl?
      .replacingOccurrences(of: "{size}", with: "\(size)"),
      let url = URL(string: urlString) else { return nil }
    return url
    
  }
  
  // MARK: Required realm initializers
  required init() {
    super.init()
  }
  
  required init(value: Any, schema: RLMSchema) {
    super.init(value: value, schema: schema)
  }
  
  required init(realm: RLMRealm, schema: RLMObjectSchema) {
    super.init(realm: realm, schema: schema)
  }
}

fileprivate extension String {
  var euroValue: Double? {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter.number(from: self)?.doubleValue
  }
  
  var timeValue: Date? {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter.date(from: self)
  }
}

