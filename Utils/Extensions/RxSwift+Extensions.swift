//
//  RxSwift+Extensions.swift
//  goeurotest
//
//  Created by Andras Kadar on 2017. 10. 16..
//  Copyright © 2017. andraskadar. All rights reserved.
//

import Foundation
import RxSwift

protocol DisposableProtocol {
  var disposeBag: DisposeBag { get }
}
