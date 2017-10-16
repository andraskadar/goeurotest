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
import Moya
import Moya_ObjectMapper
import RealmSwift

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
    
    let provider = RxMoyaProvider<GoEuropeEndpoints>.defaultProvider()
    let selectedTab = selectedTabIndex
      .asObservable()
      .map { VehicleTab(rawValue: $0) }
      .filterNil()
    
    func saveDirections(directions: [DirectionModel], tab: VehicleTab) {
      // Store the new directions
      do {
        let realm = try Realm()
        
        // Delete old ones
        let oldObjects = realm.objects(DirectionModel.self)
          .filter("vehicleTypeRaw = %d", tab.rawValue)
        
        try realm.write {
          realm.delete(oldObjects)
        }
        
        try realm.write {
          realm.add(directions)
        }
      } catch {}
    }
    
    func loadSavedDirections(for tab: VehicleTab) -> [DirectionModel] {
      do {
        let realm = try Realm()
        
        // Delete old ones
        return Array(
          realm.objects(DirectionModel.self)
            .filter("vehicleTypeRaw = %d", tab.rawValue)
        )
      } catch {
        // If still failing, return empty list
        return []
      }
    }
    
    let selectedDirections = selectedTab.flatMapLatest { vehicleTab in
      return provider.request(.getDirections(vehicleTab.networkEndpoint))
        .mapArray(DirectionModel.self)
        .asObservable()
        .do(onNext: { directions in
          // Set the vehicle type (for later queries)
          directions.forEach {
            $0.vehicleTypeRaw = vehicleTab.rawValue
          }
          
          saveDirections(directions: directions, tab: vehicleTab)
        })
        .catchError { (_) -> Observable<[DirectionModel]> in
          // On error return db objects
          return Observable.just(loadSavedDirections(for: vehicleTab))
        }
    }
    
    items = Observable.combineLatest(
      selectedDirections,
      sortType) {
        (directions, sortType) -> [TravelCellViewModelProtocol] in
        return directions
          .sorted {
            switch sortType {
            case .arrivalTime:
              return isOrderedBefore(t1: $0.arrivalTime, t2: $1.arrivalTime)
            case .departureTime:
              return isOrderedBefore(t1: $0.departureTime, t2: $1.departureTime)
            case .duration:
              return isOrderedBefore(t1: $0.distanceTime, t2: $1.distanceTime)
            }
          }
          .map(TravelCellViewModel.init)
      }
      .catchErrorJustReturn([])
    
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

fileprivate enum VehicleTab: Int {
  case train, bus, flight
  
  var networkEndpoint: GoEuropeEndpoints.Vehicle {
    switch self {
    case .train: return .train
    case .bus: return .bus
    case .flight: return .flight
    }
  }
}

fileprivate struct TravelCellViewModel: TravelCellViewModelProtocol {
  var image: Observable<URL?> = Observable.just(nil)
  var price: Observable<String?> = Observable.just("$19.00")
  var travelTimeRange: Observable<String?> = Observable.just("17:00 - 23:50")
  var travelTimeDuration: Observable<String?> = Observable.just("8:15h")
  var connectionType: Observable<String?> = Observable.just("Direct")
  
  init(model: DirectionModel) {
    let omodel = Observable.just(model)
    price = omodel.map { $0.priceInEuros.displayEuro }
    travelTimeRange = Observable.combineLatest([
      omodel.map { $0.departureTime?.displayTime },
      omodel.map { $0.arrivalTime?.displayTime }])
      .map { $0.filter { $0 != nil }.map { $0! } }
      .map { $0.joined(separator: " - ") }
    travelTimeDuration = omodel.map { $0.distanceTime?.displayDuration }
    connectionType = omodel.map {
      return $0.numberOfStops == 0
        ? "direction.connectiontype.direct".localized
        : String(format: "direction.connectiontype.xstops".localized,
                 $0.numberOfStops)
    }
    image = omodel.map { $0.providerLogoUrl(for: 63) }
  }
}

fileprivate func isOrderedBefore(t1: Date?, t2: Date?) -> Bool {
  guard let t1 = t1 else { return false }
  guard let t2 = t2 else { return true }
  return t1.timeIntervalSince1970 < t2.timeIntervalSince1970
}

fileprivate extension Double {
  var displayEuro: String? {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale(identifier:"de_DE")
    return formatter.string(from: NSNumber(value: self))
  }
}

fileprivate extension Date {
  var displayTime: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter.string(from: self)
  }
  var displayDuration: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter.string(from: self)
  }
}
