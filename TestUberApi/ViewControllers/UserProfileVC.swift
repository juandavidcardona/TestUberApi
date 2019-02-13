//
//  UserProfileVC.swift
//  TestUberApi
//
//  Created by Juan David Cardona on 2/13/19.
//  Copyright © 2019 Juan David Cardona. All rights reserved.
//

import Foundation
import UIKit
import UberRides

class UserProfileVC: UIViewController{

    @IBOutlet weak var imageProfile: UIImageView!
    @IBOutlet weak var viewContent: UIView!
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPromoCode: UILabel!
    @IBOutlet weak var progress: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewContent.backgroundColor = UIColor.clear
        imageProfile.layer.masksToBounds = true
        imageProfile.layer.cornerRadius = imageProfile.frame.height / 2
        setupViewBackground()
        getData()
    }
    
    func getData(){
        
        progress.startAnimating()
        
        let ridesClient = RidesClient()
        ridesClient.fetchUserProfile { (user, response) in
            
            guard user != nil else{
                DispatchQueue.main.async {
                    self.progress.stopAnimating()
                }
                return
            }
            DispatchQueue.main.async {
                self.progress.stopAnimating()
                self.txtName.text = (user?.firstName ?? "") + " " + (user?.lastName ?? "")
                self.txtEmail.text = user?.email
                self.txtPromoCode.text = user?.promoCode
                
                if let url = URL(string: (user?.picturePath!)!) {
                    self.imageProfile.contentMode = .scaleAspectFit
                    self.downloadImage(from: url)
                }
            }
            
        }
    
        
    }
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    func downloadImage(from url: URL) {
        getData(from: url) { data, response, error in
            guard let data = data, error == nil else { return }
            print(response?.suggestedFilename ?? url.lastPathComponent)
            DispatchQueue.main.async() {
                self.imageProfile.image = UIImage(data: data)
            }
        }
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

