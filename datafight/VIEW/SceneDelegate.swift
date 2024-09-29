//
//  SceneDelegate.swift
//  datafight
//
//  Created by younes ouasmi on 28/07/2024.
//

import UIKit
import FirebaseAuth


class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


   
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
           guard let windowScene = (scene as? UIWindowScene) else { return }
           window = UIWindow(windowScene: windowScene)
           configureInitialViewController()
           window?.makeKeyAndVisible()
       }

       func configureInitialViewController() {
           let storyboard = UIStoryboard(name: "Main", bundle: nil)
           
           if Auth.auth().currentUser != nil {
               // L'utilisateur est déjà connecté
               if let mainTabBarController = storyboard.instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController {
                   window?.rootViewController = mainTabBarController
               }
           } else {
               // L'utilisateur n'est pas connecté, on le dirige vers la page de login
               if let loginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
                   let navigationController = UINavigationController(rootViewController: loginViewController)
                   window?.rootViewController = navigationController
               }
           }
       }

       func logout() {
           do {
               try Auth.auth().signOut()
               configureInitialViewController()
           } catch {
               print("Error during logout: \(error.localizedDescription)")
           }
       }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

