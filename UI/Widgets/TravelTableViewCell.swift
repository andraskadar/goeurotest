//
//  TravelTableViewCell.swift
//  goeurotest
//
//  Created by Andras Kadar on 2017. 10. 16..
//  Copyright © 2017. andraskadar. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import AlamofireImage

protocol TravelCellViewModelProtocol {
  var image: Observable<URL?> { get }
  var price: Observable<String?> { get }
  var travelTimeRange: Observable<String?> { get }
  var connectionType: Observable<String?> { get }
  var travelTimeDuration: Observable<String?> { get }
}

final class TravelTableViewCell: UITableViewCell {
  @IBOutlet fileprivate weak var logoImageView: UIImageView!
  @IBOutlet fileprivate weak var priceLabel: UILabel!
  @IBOutlet fileprivate weak var travelTimeRangeLabel: UILabel!
  @IBOutlet fileprivate weak var travelTimeDurationLabel: UILabel!
  @IBOutlet fileprivate weak var connectionTypeLabel: UILabel!
  
  private var disposeBag = DisposeBag()
  
  func updateUI(with model: TravelCellViewModelProtocol) {
    model.image.asDriver(onErrorJustReturn: nil)
      .drive(onNext: { [weak self] url in
        guard let url = url else { self?.logoImageView.image = nil; return }
        self?.logoImageView.af_setImage(withURL: url)
      })
      .addDisposableTo(disposeBag)
    
    model.price.asDriver(onErrorJustReturn: nil)
      .drive(priceLabel.rx.text)
      .addDisposableTo(disposeBag)
    
    model.travelTimeRange.asDriver(onErrorJustReturn: nil)
      .drive(travelTimeRangeLabel.rx.text)
      .addDisposableTo(disposeBag)
    
    model.travelTimeDuration.asDriver(onErrorJustReturn: nil)
      .drive(travelTimeDurationLabel.rx.text)
      .addDisposableTo(disposeBag)
    
    model.connectionType.asDriver(onErrorJustReturn: nil)
      .drive(connectionTypeLabel.rx.text)
      .addDisposableTo(disposeBag)
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    
    disposeBag = DisposeBag()
  }
}
