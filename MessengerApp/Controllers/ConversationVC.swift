//
//  ViewController.swift
//  MessengerApp
//
//  Created by Emil on 11.01.2023.
//

import UIKit
import FirebaseAuth

class ConversationVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad ()
        view.backgroundColor = .green
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        validateAuth()
    }
    
    //let isLoggedIN = UserDefaults.standard.bool(forKey: "logged_in")
    
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc = LoginVC()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }
}

