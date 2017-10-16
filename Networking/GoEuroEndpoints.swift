//
//  GoEuroEndpoints.swift
//  goeurotest
//
//  Created by Andras Kadar on 2017. 10. 16..
//  Copyright © 2017. andraskadar. All rights reserved.
//

import Foundation
import Moya
import Alamofire
import ObjectMapper

//typealias GoEuropeNetworkProvider = RxMoyaProvider<GoEuropeEndpoints>
//
extension RxMoyaProvider {
  static func defaultProvider() -> RxMoyaProvider<Target> {
    return RxMoyaProvider<Target>(plugins: [
      NetworkActivityPlugin(networkActivityClosure: { (change) in
        UIApplication.shared.isNetworkActivityIndicatorVisible
          = change == .began
      }),
      NetworkLoggerPlugin(
        verbose: true,
        cURL: false,
        output: nil,
        requestDataFormatter: nil,
        responseDataFormatter: nil)
      ])
  }
}

enum GoEuropeEndpoints {
  case getDirections(Vehicle)
  
  // MARK: - Directions
  enum Vehicle {
    case bus, train, flight
  }
}

extension GoEuropeEndpoints: TargetType {
  
  var baseURL: URL {
    return URL(string: "https://api.myjson.com/bins")!
  }
  
  var path: String {
    switch self {
    case .getDirections(let vehicle):
      switch vehicle {
      case .bus: return "37yzm"
      case .train: return "3zmcy"
      case .flight: return "w60i"
      }
    }
  }
  
  var method: Moya.Method {
    return .get
  }
  
  var sampleData: Data { return Data() }
  
  var task: Task {
    return .requestPlain
  }
  
  var headers: [String : String]? {
    return nil
  }
  
}
