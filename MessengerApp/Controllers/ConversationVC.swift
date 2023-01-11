//
//  ViewController.swift
//  MessengerApp
//
//  Created by Emil on 11.01.2023.
//

import UIKit

class ConversationVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .green
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let isLoggedIN = UserDefaults.standard.bool(forKey: "logged_in")
        
        if !isLoggedIN {
            let vc = LoginVC()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
        
    }


}

