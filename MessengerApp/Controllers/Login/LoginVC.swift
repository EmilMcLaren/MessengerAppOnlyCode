//
//  LoginVC.swift
//  MessengerApp
//
//  Created by Emil on 11.01.2023.
//

import UIKit
import FirebaseAuth
import Firebase
import FacebookLogin
import FacebookCore
import GoogleSignIn
import GoogleUtilities_AppDelegateSwizzler
import JGProgressHUD


//let loginButton = FBLoginButton()
//        loginButton.center = view.center
//        view.addSubview(loginButton)

class LoginVC: UIViewController {

    private let spinner = JGProgressHUD(style: .dark )

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "clear")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email address..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        field.isSecureTextEntry = true
        return field
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    //private let loginButtonFB = FBLoginButton()
    
    private let loginButtonFB: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["public_profile","email"]
        return button
    }()
    
    private let loginButtonGoogle = GIDSignInButton()
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.navigationController?.dismiss(animated: true)
        })
        
        
        title = "Log In"
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTapRegister))
        
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        loginButtonGoogle.addTarget(self, action: #selector(loginButtonTappedGoogle), for: .touchUpInside)
        
        loginButtonFB.delegate = self
        
        emailField.delegate = self
        passwordField.delegate = self
        
        //add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(loginButtonFB)
        scrollView.addSubview(loginButtonGoogle)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        let size = view.width/3
        
        imageView.frame = CGRect(x: (scrollView.width - size)/2,
                                 y: 30,
                                 width: size,
                                 height: size)
        
        emailField.frame = CGRect(x: 30,
                                  y: imageView.buttom+10,
                                  width: scrollView.width-60,
                                 height: 52)
        
        passwordField.frame = CGRect(x: 30,
                                  y: emailField.buttom+10,
                                  width: scrollView.width-60,
                                 height: 52)
        loginButton.frame = CGRect(x: 30,
                                  y: passwordField.buttom+10,
                                  width: scrollView.width-60,
                                 height: 52)
        
        loginButtonFB.frame = CGRect(x: 30,
                                  y: loginButton.buttom+10,
                                  width: scrollView.width-60,
                                 height: 52)
        
        loginButtonGoogle.frame = CGRect(x: 30,
                                  y: loginButtonFB.buttom+10,
                                  width: scrollView.width-60,
                                 height: 52)
        //loginButtonFB.frame.origin.y = loginButton.buttom+20
        
}
    //firebase login
    @objc private func loginButtonTapped() {
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text, let password = passwordField.text,
              !email.isEmpty, !password.isEmpty, password.count >= 6 else {
                  alertUserLoginError()
                  return
              }
        
        spinner.show(in: view)
        
        //firebase login
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let strongSelf = self else {return}
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }

            guard let result = authResult, error == nil else {
                print("Failed to log in user with email: \(email)")
                return
            }
            let user = result.user
            
            let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
            
            DatabaseManager.shared.getDataFor(path: safeEmail) { [weak self] result in
                switch result {
                case .success(let data):
                    guard let userData = data as? [String: Any],
                          let firstName = userData["first_name"],
                          let lastName = userData["last_name"] else {
                              return
                          }
                    UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                case .failure(let error):
                    print("Failed to read data with error \(error)")
                }
            }
            
            //let safeEmailTo = DatabaseManager.safeEmail(emailAddress: email)
            DatabaseManager.shared.getDataFor(path: safeEmail) { [weak self] result in
                switch result {
                case .success(let data):
                    guard let userData = data as? [String: Any],
                          let firstName = userData["first_name"],
                          let lastName = userData["last_name"] else {
                              return
                          }
                    UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                case .failure(let error):
                    print("Failed to get and read fata with error \(error)")
                }
            }
            
            UserDefaults.standard.set(email, forKey: "email")
            
            
            print("Logged  in user \(user)")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
    
    //google login
    @objc private func loginButtonTappedGoogle() {
 
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { signInResult, error in
        guard error == nil else { return }

           
            print("here")
            signInResult?.user.refreshTokensIfNeeded { user, error in
                   guard error == nil else { return }
                   guard let user = user else { return }

                guard let idToken = user.idToken?.tokenString else {return}
                let accessToken = user.accessToken.tokenString
                
                print("Did sign with id toke: \(idToken)")
                print("Did sign with Google: \(user)")

                guard let email = user.profile?.email,
                      let firstName = user.profile?.givenName,
                      let lastName = user.profile?.familyName else {
                          return
                      }

                
                UserDefaults.standard.set(email, forKey: "email")
                UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                
                DatabaseManager.shared.userExist(with: email) { exist in
                    if !exist {
                        let chatUser = ChatAppUser(firstName: firstName,
                                                   lastName: lastName,
                                                   emailAddress: email)
                        DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                            if success {
                                guard let url = user.profile?.imageURL(withDimension: 200) else {return }
                                
                                URLSession.shared.dataTask(with: url) { data, _, _ in
                                    guard let data = data else {
                                        return
                                    }
                                    //upload image
                                    let fileName = chatUser.profilePictureFileName
                                    
                                    StorageManager.shared.uploadPictureProfile(with: data, fileName: fileName, completion: { result in
                                        switch result {
                                        case .success(let downloadUrl):
                                            UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                            print(downloadUrl)
                                        case .failure(let error):
                                            print("Storage manager error:  \(error)")
                                        }
                                    })
                                }.resume()
                            }
                        })
                    }
                }
                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
                FirebaseAuth.Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                    guard let strongSelf = self else {return}
                    
                    guard authResult != nil, error == nil else {
                        print("Failed to log in with google credential")
                        return
                    }
                    print("Successfully to log in with google credential")
                    strongSelf.navigationController?.dismiss(animated: true, completion: nil)
                }
                
//                let cter = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: idToken)
//
//               }

                
            
    }
        }
        
        
//        GIDSignIn.sharedInstance.signIn(withPresenting: self) { signInResult, error in
//            guard error == nil else { return }
//
//
//            // If sign in succeeded, display the app's main content View.
//          }
    }
    
    
    func alertUserLoginError() {
        let alert = UIAlertController(title: "Error", message: "Please enter all information", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }
    
    
    @objc func didTapRegister() {
        let vc = RegisterVC()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension LoginVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            loginButtonTapped()
        }
        return true
    }
}


//MARK: Facebook loginButtonFB delegate
extension LoginVC: LoginButtonDelegate {

    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        //none action
    }

    
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {

        guard let token = result?.token?.tokenString else {
            print("Failed log in with Facebook")
            return
        }
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields":
                                                                        "email, first_name, last_name, picture.type(large)"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        
        facebookRequest.start { _, result, error in
            guard let result = result as? [String: Any],
                  error == nil else {
                      print("Failed to make facebook graph request")
                      return
                  }
            
            //print("\(result)")
            guard let firstName = result["first_name"] as? String,
                  let lastName = result["last_name"] as? String,
                  let  email = result["email"] as? String,
                  let  picture = result["picture"] as? [String: Any],
                  let  data = picture["data"] as? [String: Any],
                  let  pictureUrl = data["url"] as? String
            else {
                print("Failed to get email and name from FB")
                return
            }
            
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
            
            
            
            
            //not delete please
//            let nameConponents = userName.components(separatedBy: " ")
//            guard nameConponents.count == 2 else {return}
//            let firstName = nameConponents[0]
//            let lastName = nameConponents[1]
            
            
            DatabaseManager.shared.userExist(with: email) { exists in
                if !exists {
                    let chatUser = ChatAppUser(firstName: firstName,
                                               lastName: lastName,
                                               emailAddress: email)
                    DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                        if success {
                            print("Download data from facebook image")
                            
                            guard let url = URL(string: pictureUrl) else {return}
                            
                            URLSession.shared.dataTask(with: url) { data, _, _ in
                                guard let data = data else {
                                    print("Failed to get data from FB")
                                    return
                                }
                                
                                print("got data from facebook, loading...")
                                //upload image
                                let fileName = chatUser.profilePictureFileName

                                StorageManager.shared.uploadPictureProfile(with: data, fileName: fileName, completion: { result in
                                    switch result {
                                    case .success(let downloadUrl):
                                        UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                        print(downloadUrl)
                                    case .failure(let error):
                                        print("Storage manager error:  \(error)")
                                    }
                                })
                            }.resume()
                        }
                    })
            }
            
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            FirebaseAuth.Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                guard let strongSelf = self else {return}

                guard authResult != nil, error == nil else {
                    if let error = error {
                        print("Facebook credential login failed - \(error)")
                    }
                    return
                }
                print("Sucsessfuly facebook credential login")
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            }
        }

       
    }
    }
}

