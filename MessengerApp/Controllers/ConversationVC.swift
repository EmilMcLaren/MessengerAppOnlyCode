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
        title = "Chats"
        navBarAppearance()
    
        view.backgroundColor = .white
    }
    
    
    
    //Set NavigationBar and SearchController
     func  navBarAppearance() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.hidesBarsOnTap = false
        
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = #colorLiteral(red: 0.8496792912, green: 0.9519454837, blue: 1, alpha: 1)
        
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.standardAppearance = appearance
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

