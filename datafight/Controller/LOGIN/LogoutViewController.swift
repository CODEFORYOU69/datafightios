//
//  LogoutViewController.swift
//  datafight
//
//  Created by younes ouasmi on 15/08/2024.
//

import UIKit

class LogoutViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        performLogout()
    }

    func performLogout() {
        if let sceneDelegate = UIApplication.shared.connectedScenes.first?
            .delegate as? SceneDelegate
        {
            sceneDelegate.logout()
        }
    }
}
