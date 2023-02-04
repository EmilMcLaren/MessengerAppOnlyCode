//
//  ProfileViewModel.swift
//  MessengerApp
//
//  Created by Emil on 04.02.2023.
//

import Foundation

enum ProfileViewModelType {
    case info, logout
}

struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let handler: (() -> Void)?
}
