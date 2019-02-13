//
//  LoginVC.swift
//  TestUberApi
//
//  Created by Juan David Cardona on 2/12/19.
//  Copyright © 2019 Juan David Cardona. All rights reserved.
//

import Foundation
import UberCore

class LoginVC : UIViewController, LoginButtonDelegate{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scopes: [UberScope] = [.profile, .request]
        let loginManager = LoginManager(loginType: .native)
        
        let loginButton = LoginButton(frame: CGRect.zero, scopes: scopes, loginManager: loginManager)
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginButton)

    NSLayoutConstraint.activate([ loginButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor) ])
    NSLayoutConstraint.activate([ loginButton.centerYAnchor.constraint(equalTo: self.view.centerYAnchor) ])

        loginButton.presentingViewController = self
        loginButton.delegate = self
        
    }
    
    func loginButton(_ button: LoginButton, didLogoutWithSuccess success: Bool) {
        // success is true if logout succeeded, false otherwise
    }
    
    func loginButton(_ button: LoginButton, didCompleteLoginWithToken accessToken: AccessToken?, error: NSError?) {
        if let _ = accessToken {
        } else if error != nil {
        }
    }
    
}
