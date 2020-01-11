//
//  SettingsViewModel.swift
//  SpotifyDaily
//
//  Created by Kevin Li on 11/29/19.
//  Copyright © 2019 Kevin Li. All rights reserved.
//

import Foundation
import RxSwift

class SettingsViewModel {
    
    let sessionService: SessionService
    let dataManager: DataManager
    private let disposeBag = DisposeBag()
    
    let user: Observable<User>
    
    let title = "Settings"
    
    init(sessionService: SessionService, dataManager: DataManager) {
        self.sessionService = sessionService
        self.dataManager = dataManager
        self.user = sessionService.getUserProfile()
    }
    
    deinit {
        Logger.info("SettingsViewModel dellocated")
    }
    
    func logout(){
        sessionService.signOut()
    }
}
