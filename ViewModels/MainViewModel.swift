//
//  MainViewModel.swift
//  goeurotest
//
//  Created by Andras Kadar on 2017. 10. 16..
//  Copyright © 2017. andraskadar. All rights reserved.
//

import Foundation
import RxSwift
import RxOptional

final class MainViewModel: MainViewModelProtocol {
  let destinationTitle: Observable<String>
  let dateTitle: Observable<String>
  let items: Observable<[TravelCellViewModelProtocol]>
  let sortTitle: Observable<String>
  
  let changeSort: BehaviorSubject<Void> = BehaviorSubject(value: ())
  var itemSelected: BehaviorSubject<Int?> = BehaviorSubject(value: nil)
  let selectedTabIndex: BehaviorSubject<Int> = BehaviorSubject(value: 0)
  
  private let sortType: BehaviorSubject<SortType> = BehaviorSubject(
    value: .departureTime)
  
  private let _showAlert: PublishSubject<AlertMessage> = PublishSubject()
  var showAlert: Observable<AlertMessage> {
    return _showAlert.asObservable()
  }
  
  private let disposeBag = DisposeBag()
  
  init() {
    // TODO: Replace when implemented
    destinationTitle = Observable.just("Berlin - Munich")
    // TODO: Replace when implemented
    dateTitle = Observable.just("Jun 07")
    
    sortTitle = sortType.map {
      ["sort.sortingby".localized, $0.title].joined(separator: " ")
    }
    
    items = Observable.just([TravelCellViewModel(), TravelCellViewModel(), TravelCellViewModel()])
    
    changeSort
      .flatMap { [unowned self] in
        return self.sortType.asObservable().take(1)
      }
      .map { $0.next }
      .bind(to: self.sortType)
      .addDisposableTo(disposeBag)
    
    itemSelected
      .filterNil()
      .map { _ in
        // TODO: Replace when implemented
        return AlertMessage(
          title: "offer.notimplemented.title".localized,
          message: "offer.notimplemented.message".localized,
          actions: [],
          needsCancelAction: false,
          needsOkAction: true)
      }
      .bind(to: _showAlert)
      .addDisposableTo(disposeBag)
  }
}

fileprivate enum SortType: Int {
  case departureTime
  case arrivalTime
  case duration
  
  var next: SortType {
    return SortType(rawValue: (self.rawValue + 1) % 3) ?? .departureTime
  }
  
  var title: String {
    switch self {
    case .departureTime: return "sort.type.departureTime".localized
    case .arrivalTime: return "sort.type.arrivalTime".localized
    case .duration: return "sort.type.duration".localized
    }
  }
}

fileprivate enum Tabs: Int {
  case train, bus, flight
}

fileprivate struct TravelCellViewModel: TravelCellViewModelProtocol {
  var image: Observable<UIImage?> = Observable.just(#imageLiteral(resourceName: "iconDummyCompanyLogo"))
  var price: Observable<String?> = Observable.just("$19.00")
  var travelTimeRange: Observable<String?> = Observable.just("17:00 - 23:50")
  var travelTimeDuration: Observable<String?> = Observable.just("8:15h")
  var connectionType: Observable<String?> = Observable.just("Direct")
}
