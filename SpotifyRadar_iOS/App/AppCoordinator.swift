//
//  AppCoordinator.swift
//  SpotifyDaily
//
//  Created by Kevin Li on 11/25/19.
//  Copyright © 2019 Kevin Li. All rights reserved.
//

import Foundation
import RxSwift
import SideMenu

class AppCoordinator: BaseCoordinator {
    
    private let disposeBag = DisposeBag()
    private let sessionService: SessionService
    
    var window = UIWindow(frame: UIScreen.main.bounds)
    
    private var drawerMenu: SideMenuNavigationController? {
        return SideMenuManager.default.leftMenuNavigationController
    }
    
    init(sessionService: SessionService) {
        self.sessionService = sessionService
    }
    
    override func start() {
        
        // Uncomment this line out if you are getting problems with the root view controller not being set by the time appdelegate returns.
//        ViewControllerUtils.setRootViewController(
//        window: self.window,
//        viewController: StartupViewController(),
//        withAnimation: true)
        
        self.sessionService.loadSession()
            .bind(onNext: { [unowned self] session in
                session == nil ? self.showSignIn() : self.showDashboard()
                self.window.makeKeyAndVisible()
            })
            .disposed(by: disposeBag)
        
        self.subscribeToSessionChanges()
    }
    
    //MARK: Helper methods
    
    private func showSignIn() {
        self.removeChildCoordinators()
        
        let coordinator = AppDelegate.container.resolve(SignInCoordinator.self)!
        self.start(coordinator: coordinator)
        
        ViewControllerUtils.setRootViewController(
            window: self.window,
            viewController: coordinator.navigationController,
            withAnimation: true)
    }
    
    private func showDashboard() {
        self.removeChildCoordinators()
        
        let coordinator = AppDelegate.container.resolve(DrawerMenuCoordinator.self)!
        coordinator.navigationController = BaseNavigationController()
        self.start(coordinator: coordinator)
        
        ViewControllerUtils.setRootViewController(
            window: self.window,
            viewController: coordinator.navigationController,
            withAnimation: true)
    }
    
    private func subscribeToSessionChanges() {
        self.sessionService.didSignIn
            .subscribe(onNext: { [weak self] in self?.showDashboard() })
            .disposed(by: self.disposeBag)
        
        self.sessionService.didSignOut
            .subscribe(onNext: { [weak self] in
                guard let `self` = self else { return }
                
                if self.drawerMenu?.isHidden ?? true {
                    self.showSignIn()
                } else {
                    self.drawerMenu?.dismiss(animated: true, completion: self.showSignIn)
                }
            })
            .disposed(by: self.disposeBag)
    }
}
