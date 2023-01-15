//
//  ProfileVC1.swift
//  MessengerApp
//
//  Created by Emil on 12.01.2023.
//

import UIKit
import FirebaseAuth
import FacebookLogin
import GoogleSignIn


class ProfileVC: UITableViewController {

    private let data = ["Log out"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Profile"
        
        navBarAppearance()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        view.backgroundColor = .white
    }
    

    func  navBarAppearance() {
       navigationController?.navigationBar.prefersLargeTitles = true
       navigationController?.hidesBarsOnTap = false
       
       let appearance = UINavigationBarAppearance()
       appearance.backgroundColor = #colorLiteral(red: 0.8496792912, green: 0.9519454837, blue: 1, alpha: 1)
       
       navigationController?.navigationBar.scrollEdgeAppearance = appearance
       navigationController?.navigationBar.standardAppearance = appearance
   }
    
    
    
    
//    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 0
//    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return data.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        cell.textLabel?.text = data[indexPath.row]
        cell.textLabel?.textColor = .red
        cell.textLabel?.textAlignment = .center
        
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        
        let actionSheet = UIAlertController(title: "",
                                            message: "Do you want to log out?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Log out",
                                            style: .destructive,
                                            handler: { [weak self]_ in
            guard let strongSelf = self else {return}
            
            //log out Facebook
            FBSDKLoginKit.LoginManager().logOut()
            print("Sign out from FB")
            //log out google
            GIDSignIn.sharedInstance.signOut()
            print("Sign out from Google")
            
            do {
                try FirebaseAuth.Auth.auth().signOut()
                
                let vc = LoginVC()
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                strongSelf.present(nav, animated: true)
            } catch  {
                print("Failed to log out")
            }
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel",
                                            style: .cancel,
                                            handler: nil))

        present(actionSheet, animated: true)
    }
}

