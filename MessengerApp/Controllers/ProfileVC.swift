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
import SDWebImage

//enum ProfileViewModelType {
//    case info, logout
//}
//
//struct ProfileViewModel {
//    let viewModelType: ProfileViewModelType
//    let title: String
//    let handler: (() -> Void)?
//}



final class ProfileVC: UITableViewController {

    private var data = [ProfileViewModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Profile"
        
        tableView.register(ProfileTableViewCell.self,
                           forCellReuseIdentifier: ProfileTableViewCell.identifier)
        
        data.append(ProfileViewModel(viewModelType: .info,
                                     title: "Name: \(UserDefaults.standard.value(forKey: "name") as? String ?? "No name")",
                                     handler: nil))
        data.append(ProfileViewModel(viewModelType: .info,
                                     title: "Email: \(UserDefaults.standard.value(forKey: "email") as? String ?? "No email")",
                                     handler: nil))
        
        data.append(ProfileViewModel(viewModelType: .logout, title: "Log out", handler: { [weak self] in
            
            guard let strongSelf = self else {return}
            let actionSheet = UIAlertController(title: "",
                                                message: "Do you want to log out?",
                                                preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Log out",
                                                style: .destructive,
                                                handler: { [weak self]_ in
                guard let strongSelf = self else {return}
                
                
                UserDefaults.standard.setValue(nil, forKey: "email")
                UserDefaults.standard.setValue(nil, forKey: "name")
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

            strongSelf.present(actionSheet, animated: true)
        }))
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.tableHeaderView = createTableHeader
        navBarAppearance()
        
        view.backgroundColor = .white
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let imageViewForHeader = imageViewForHeader {
            imageViewForHeader.frame = CGRect(x: (view.width-150)/2,
                                     y: 75,
                                     width: 150,
                                     height: 150)
            
            imageViewForHeader.layer.cornerRadius = imageViewForHeader.width/2
            
        }
        
//        imageViewForHeader?.frame = CGRect(x: (view.width-150)/2,
//                                 y: 75,
//                                 width: 150,
//                                 height: 150)
//
//        imageViewForHeader?.layer.cornerRadius = imageViewForHeader!.width/2
//
        createTableHeader = UIView(frame: CGRect(x: 0,
                                        y: 0,
                                        width: self.view.width,
                                        height: 300))
    }
    

    func  navBarAppearance() {
       navigationController?.navigationBar.prefersLargeTitles = true
       navigationController?.hidesBarsOnTap = false
       
       let appearance = UINavigationBarAppearance()
       //appearance.backgroundColor = #colorLiteral(red: 0.8496792912, green: 0.9519454837, blue: 1, alpha: 1)
        
        if traitCollection.userInterfaceStyle == .light {
            appearance.backgroundColor = #colorLiteral(red: 0.8496792912, green: 0.9519454837, blue: 1, alpha: 1)
        } else {
            appearance.backgroundColor = .secondarySystemBackground
        }
       navigationController?.navigationBar.scrollEdgeAppearance = appearance
       navigationController?.navigationBar.standardAppearance = appearance
   }
    
    
    lazy var createTableHeader: UIView? =  {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else { return nil }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let fileName = safeEmail + "_profile_picture.png"
        let path = "image/"+fileName
        
        let headerView = UIView(frame: CGRect(x: 0,
                                        y: 0,
                                        width: self.view.width,
                                        height: 300))
        headerView.backgroundColor = .link
        headerView.addSubview(imageViewForHeader!)
        return headerView
    }()
    
    
    lazy var imageViewForHeader: UIImageView? = {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else { return nil }

        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let fileName = safeEmail + "_profile_picture.png"
        let path = "images/"+fileName

        let imageView = UIImageView()
        imageView.backgroundColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageView.width/2
        
        StorageManager.shared.downloadUrl(for: path) {  result in
            switch result {
            case .success(let url):
                print("This url: \(url)")
                imageView.sd_setImage(with: url, completed: nil)
                //self?.downloadImage(imageView: imageView, url: url)
            case .failure(let error):
                print("Failed to get download url: \(error)")
            }
        }

        return imageView
    }()
    
    
//    func downloadImage(imageView: UIImageView, url: URL) {
//        imageView.sd_setImage(with: url, completed: nil)
////        URLSession.shared.dataTask(with: url) { data, _, error in
////            guard let data = data, error == nil else {
////                return
////            }
////            DispatchQueue.main.async {
////                let image = UIImage(data: data)
////                imageView.image = image
////            }
////        }.resume()
//    }
    
    
    
    
    
    //MARK: TableView DataSource
//    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 0
//    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return data.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifier,
                                                 for: indexPath) as! ProfileTableViewCell
        cell.setUP(with: viewModel)
//        cell.textLabel?.text = data[indexPath.row]
//        cell.textLabel?.textColor = .red
//        cell.textLabel?.textAlignment = .center
        
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        data[indexPath.row].handler?()
}
}

class ProfileTableViewCell: UITableViewCell {
    
    static let identifier = "ProfileTableViewCell"
    
    public func setUP(with viewModel: ProfileViewModel) {
        self.textLabel?.text = viewModel.title
        switch viewModel.viewModelType {
        case .info:
            self.textLabel?.textAlignment = .left
            self.selectionStyle = .none
        case .logout:
            self.textLabel?.textColor = .red
            self.textLabel?.textAlignment = .center
        }
    }
}

