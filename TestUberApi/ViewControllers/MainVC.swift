//
//  MainVC.swift
//  TestUberApi
//
//  Created by Juan David Cardona on 2/12/19.
//  Copyright © 2019 Juan David Cardona. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import UberCore
import UberRides

class MainVC : UIViewController {
    
    @IBOutlet weak var btnTaxi: UIButton!
    
    let accessToken = "JA.VUNmGAAAAAAAEgASAAAABwAIAAwAAAAAAAAAEgAAAAAAAAG8AAAAFAAAAAAADgAQAAQAAAAIAAwAAAAOAAAAkAAAABwAAAAEAAAAEAAAAAJBpBRLBuM98y9H9oBVV49sAAAA2Z_mEIkH7yqZqQgh3oDffNQ7jwaEL-oXsONWATgHZHLy3UehrlzbhMyT8GbnRULAUr0rKDXu6FFtsxC7u0B8mzA68WkGLaZ5cqXCcgo6X1bKAov1_GJrrAbobhs45ROQxsweaPR8PXSzadOuDAAAAAvZde7R3x9LEDeUzCQAAABiMGQ4NTgwMy0zOGEwLTQyYjMtODA2ZS03YTRjZjhlMTk2ZWU"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        setupViews()
        
        let token = AccessToken(tokenString: accessToken)
        if TokenManager.save(accessToken: token) {
            // Success
            print("success")
        } else {
            print("error")
            // Unable to save
        }
        
        
        getData()
    }
  
    func getData(){
    
    }
    
    func setupViews(){
        btnTaxi.layer.masksToBounds = true
        btnTaxi.layer.cornerRadius = 10
        setupViewBackground()
    }
    
    func setupViewBackground() {
       
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [
            UIColor(red:100/255, green:100/255, blue:100/255, alpha:1.0).cgColor,
            UIColor(red:200/255, green:200/255, blue:200/255, alpha:1.0).cgColor
        ]
        gradient.locations = [0.0, 0.5]
        view.layer.insertSublayer(gradient, at: 0)
    }
}
