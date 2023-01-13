//
//  LoginVC.swift
//  MessengerApp
//
//  Created by Emil on 11.01.2023.
//

import UIKit
import FirebaseAuth
import FacebookLogin
import FacebookCore


//let loginButton = FBLoginButton()
//        loginButton.center = view.center
//        view.addSubview(loginButton)

class LoginVC: UIViewController {

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
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
        field.backgroundColor = .white
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
        field.backgroundColor = .white
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Log In"
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTapRegister))
        
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        
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
        loginButtonFB.frame.origin.y = loginButton.buttom+20
}
    
    @objc private func loginButtonTapped() {
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text, let password = passwordField.text,
              !email.isEmpty, !password.isEmpty, password.count >= 6 else {
                  alertUserLoginError()
                  return
              }
        
        //firebase login
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let strongSelf = self else {return}
            guard let result = authResult, error == nil else {
                print("Failed to log in user with email: \(email)")
                return
            }
            let user = result.user
            print("Logged  in user \(user)")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        }
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

//Facebook loginButtonFB delegate
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
                                                         parameters: ["fields": "email, name"],
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
            guard let userName = result["name"] as? String,
                 let  email = result["email"] as? String else {
                print("Faile to get email and name from FB")
                return
            }
            
            let nameConponents = userName.components(separatedBy: " ")
            guard nameConponents.count == 2 else {return}
            
            let firtName = nameConponents[0]
            let lastName = nameConponents[1]
            
            
            DatabaseManager.shared.userExist(with: email) { exists in
                if !exists {
                    DatabaseManager.shared.insertUser(with: ChatAppUser(firstName: firtName,
                                                                        lastName: lastName,
                                                                        emailAddress: email))
                }
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
