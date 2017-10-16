//
//  MainViewController.swift
//  goeurotest
//
//  Created by Andras Kadar on 2017. 10. 16..
//  Copyright © 2017. andraskadar. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol MainViewModelProtocol: AlertSignalProtocol {
  // Inputs
  var destinationTitle: Observable<String> { get }
  var dateTitle: Observable<String> { get }
  var items: Observable<[TravelCellViewModelProtocol]> { get }
  var sortTitle: Observable<String> { get }
  
  // Outputs
  var changeSort: BehaviorSubject<Void> { get }
  var itemSelected: BehaviorSubject<Int?> { get }
  
  // In-out
  var selectedTabIndex: BehaviorSubject<Int> { get }
}

final class MainViewController: UIViewController, DisposableProtocol, AlertProtocol {
  
  // IBOutlets
  @IBOutlet fileprivate weak var navigationTitleLabel: UILabel!
  @IBOutlet fileprivate weak var tableView: UITableView!
  
  @IBOutlet fileprivate weak var tabBackgroundView: UIView!
  @IBOutlet fileprivate var tabButtons: [UIButton]!
  @IBOutlet fileprivate weak var tabUnderlineView: UIView!
  @IBOutlet fileprivate weak var tabUnderlineViewCenterConstraint: NSLayoutConstraint!
  
  @IBOutlet fileprivate weak var sortButton: UIButton!
  
  // DI
  var viewModel: MainViewModelProtocol! = MainViewModel()
  private var viewAppeared: Bool = false
  let disposeBag = DisposeBag()
  
  fileprivate struct Constants {
    static let cellId = "TravelTableViewCell"
    static let tabUnderlineAnimationDuration: TimeInterval = 0.3
    
    static let destinationFont = UIFont.systemFont(ofSize: 16)
    static let dateFont = UIFont.systemFont(ofSize: 15)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupUI()
    setupBindings()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    viewAppeared = true
  }
  
  private func setupUI() {
    // Create 2 lined navigation title label
    do {
      let titleLabel = UILabel()
      titleLabel.numberOfLines = 2
      titleLabel.textAlignment = .center
      titleLabel.textColor = UIColor.white
      navigationItem.titleView = titleLabel
      navigationTitleLabel = titleLabel
    }
    
    navigationController?.navigationBar.setSolidBackgroundColor(
      color: tabBackgroundView.backgroundColor!)
  }
  
  private func setupBindings() {
    guard let viewModel = viewModel else {
      assertionFailure("ViewModel should be set")
      return
    }
    
    handleAlerts(for: viewModel)
    
    // MARK: Input
    // Combine the destination & date titles to create the title required
    Observable.combineLatest(viewModel.destinationTitle, viewModel.dateTitle) {
      (destination, date) -> NSAttributedString? in
      let title = NSMutableAttributedString(
        string: destination + "\n",
        attributes: [.font: Constants.destinationFont])
      title.append(NSAttributedString(
        string: date,
        attributes: [.font: Constants.dateFont]))
      return title
      }
      .asDriver(onErrorJustReturn: nil)
      .drive(onNext: { [weak self] text in
        self?.navigationTitleLabel.attributedText = text
        self?.navigationTitleLabel.sizeToFit()
      })
      .addDisposableTo(disposeBag)
    
    let selectedTabIndex = viewModel.selectedTabIndex.asDriver(onErrorJustReturn: 0)
    selectedTabIndex
      // Selected button state should be changed upon tab index change
      .drive(onNext: { [unowned self] index in
        self.tabButtons.enumerated().forEach {
          $1.isSelected = $0 == index
        }
      })
      .addDisposableTo(disposeBag)
    
    selectedTabIndex
      // Map to the center of the selected button
      .map { [unowned self] index in return self.tabButtons[index].center.x }
      // Bind to underline center
      .drive(onNext: { [unowned self] position in
        self.tabUnderlineViewCenterConstraint.constant = position
        // Animate only if view appeared
        if self.viewAppeared {
          UIView.animate(
            withDuration: Constants.tabUnderlineAnimationDuration,
            animations: {
              self.view.layoutIfNeeded()
          })
        }
      })
      .addDisposableTo(disposeBag)
    
    // Set selected sort title
    viewModel.sortTitle.asDriver(onErrorJustReturn: "?")
      .drive(sortButton.rx.title(for: .normal))
      .addDisposableTo(disposeBag)
    
    // Bind tableView
    viewModel.items
      .asDriver(onErrorJustReturn: [])
      .drive(
        tableView.rx.items(
          cellIdentifier: Constants.cellId,
          cellType: TravelTableViewCell.self)
      ) { row, model, cell in
        cell.updateUI(with: model)
      }
      .addDisposableTo(disposeBag)
    
    // MARK: Output
    tabButtons.enumerated().forEach { (index, button) in
      button.rx.tap
        .map { index }
        .bind(to: viewModel.selectedTabIndex)
        .addDisposableTo(disposeBag)
    }
    
    tableView.rx.itemSelected
      .map { $0.row }
      .bind(to: viewModel.itemSelected)
      .addDisposableTo(disposeBag)
    
    // Trigger sort change
    sortButton.rx.tap.map { _ in return }
      .bind(to: viewModel.changeSort)
      .addDisposableTo(disposeBag)
  }
}

fileprivate extension UINavigationBar {
  func setSolidBackgroundColor(color: UIColor) {
    barStyle = .default
    barTintColor = color
    isTranslucent = false
  }
}
