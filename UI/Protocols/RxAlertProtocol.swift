//
//  RxAlertProtocol.swift
//  goeurotest
//
//  Created by Andras Kadar on 2017. 10. 16..
//  Copyright © 2017. andraskadar. All rights reserved.
//

import UIKit
import RxSwift

struct AlertMessage {
  var title: String?
  var message: String?
  var actions: [AlertAction]
  var needsCancelAction: Bool
  var needsOkAction: Bool
}

struct AlertAction {
  var title: String
  var isDestructive: Bool
  var callback: (() -> Void)?
}

protocol AlertProtocol { }

protocol AlertSignalProtocol {
  var showAlert: Observable<AlertMessage> { get }
}

extension AlertProtocol where Self: DisposableProtocol, Self: UIViewController {
  
  func handleAlerts(for signal: AlertSignalProtocol) {
    handleAlerts(observable: signal.showAlert)
  }
  
  func handleAlerts(observable: Observable<AlertMessage>) {
    observable
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [weak self] message in
        self?.present(message: message)
      })
      .addDisposableTo(disposeBag)
  }
  
  func present(message: AlertMessage, style: UIAlertControllerStyle = .alert) {
    let controller = UIAlertController(
      title: message.title,
      message: message.message,
      preferredStyle: style)
    
    message.actions.forEach { action in
      controller.addAction(
        UIAlertAction(
          title: action.title,
          style: action.isDestructive ? .destructive : .default,
          handler: { (_) in
            action.callback?()
        })
      )
    }
    
    if message.needsCancelAction {
      controller.addAction(
        UIAlertAction(
          title: "general.cancel".localized,
          style: .cancel,
          handler: nil)
      )
    }
    
    if message.needsOkAction {
      controller.addAction(
        UIAlertAction(
          title: "general.ok".localized,
          style: .cancel,
          handler: nil)
      )
    }
    
    present(controller, animated: true, completion: nil)
  }
  
}
