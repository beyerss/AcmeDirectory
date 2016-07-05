//
//  DetailViewController.swift
//  Acme Directory
//
//  Created by Steven Beyers on 6/29/16.
//  Copyright © 2016 Captech. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!
    @IBOutlet weak var employeeTitleLabel: UILabel!
    @IBOutlet weak var phoneNumberLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var textMessagButton: UIButton!
    @IBOutlet weak var emailMessageButton: UIButton!

    func configureView() {
        // Update the user interface for the detail item.
        if let detail = self.detailItem {
            callButton?.isHidden = false
            textMessagButton?.isHidden = false
            emailMessageButton?.isHidden = false
            
            var name = ""
            if let first = detail.firstName {
                name = first
            }
            if let last = detail.lastName {
                name = "\(name) \(last)"
            }
            detailDescriptionLabel?.text = name
            
            employeeTitleLabel?.text = detail.department
            phoneNumberLabel?.text = detail.phoneNumber
            emailLabel?.text = detail.email
        } else {
            detailDescriptionLabel?.text = ""
            employeeTitleLabel?.text = ""
            phoneNumberLabel?.text = ""
            emailLabel?.text = ""
            callButton?.isHidden = true
            textMessagButton?.isHidden = true
            emailMessageButton?.isHidden = true
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    var detailItem: Employee? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }


}

