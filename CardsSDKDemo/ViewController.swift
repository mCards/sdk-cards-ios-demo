//
//  ViewController.swift
//  CardsSDKDemo
//
//  Created by Mukhtar Yusuf on 1/24/25.
//

import UIKit
import AuthSDK
import CoreSDK
import CardsSDK

class ViewController: UIViewController {
    private var accessToken = ""
    private var isLoggedIn: Bool { !accessToken.isEmpty }
    private var userFullName = ""
    private var card: Card!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAuthSDK()
    }

    private func setupAuthSDK() {
        let auth0ClientID = "DL8XpUmzegVl9dR8QpO9djDifTY7nGyd" // Auth0 client ID gotten from the mCards team
        let auth0Domain = "mcards-test.au.auth0.com" // Auth0 Domain gotten from the mCards team
        let auth0Audience = "https://staging.mcards.com/api" // Auth0 audience gotten from the mCards team
        
        let args = Auth0Args(
            auth0ClientID: auth0ClientID,
            auth0Domain: auth0Domain,
            auth0Audience: auth0Audience)
        
        // Configure the SDK
        AuthSdkProvider.shared.configure(args: args)
        
        // Set logging to the console and/or Firebase
        AuthSdkProvider.shared.setLogging(debugMode: true, loggingCallback: LoggingHandler())
    }
    
    private func login() {
        let savedPhoneNumber = "" // Save phone number used to pre-populate the login form
        let loginArgs = LoginArgs(savedPhoneNumber: savedPhoneNumber)
        
        AuthSdkProvider.shared.login(args: loginArgs) { [weak self] result in
            switch result {
            case .success(let authSuccess):
                // Get any required data
                self?.accessToken = authSuccess.jwts.accessToken
                self?.userFullName = authSuccess.user.fullName
                
                self?.setupCardsSDK()
                self?.getCards()
            case .failure(let error):
                // Handle error
                print(error.localizedDescription)
            }
        }
    }
    
    private func setupCardsSDK() {
        CardsSdkProvider.shared.configure(
            accessToken: accessToken,
            debugMode: true, // Set to true to print logs in the console, false otherwise
            tokenRefreshCallback: self, // Used to refresh the tokens upon expiration or when invalid
            loggingCallback: LoggingHandler()) // Used to log messages and non-fatals to Firebase
    }
    
    private func getCards() {
        CardsSdkProvider.shared.getCards { [weak self] result in
            switch result {
            case .success(let cards):
                guard !cards.isEmpty else {
                    print("User has no cards")
                    return
                }
                
                self?.card = cards[0]
                self?.getCardWalletStatus()
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    private func getCardWalletStatus() {
        let status = CardsSdkProvider.shared.getCardWalletStatus(card: card)
        handleCardWalletStatus(status: status)
    }
    
    private func addCardToWallet() {
        CardsSdkProvider.shared.addCardToWallet(
            card: card,
            userDisplayName: userFullName
        ) { [weak self] result in
            switch result {
            case .success(let status):
                self?.handleCardWalletStatus(status: status)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    private func handleCardWalletStatus(status: CSDKWalletStatus) {
        switch status {
        case .notAdded:
            print(status)
//            addToWalletButton.isHidden = false
        case .added:
            print(status)
//            addToWalletButton.isHidden = true
        case .notActivated:
            print(status)
//            addToWalletButton.isHidden = true
            /*
             Take any required additional action like showing a status text to the user
             prompting them to open the wallet app to activate the card.
             */
        default:
            break
        }
    }
}

// MARK: - CSDKTokenRefreshCallback
extension ViewController: CSDKTokenRefreshCallback {
    func refreshJWTs(completion: @escaping (JWTs) -> Void) {
        AuthSdkProvider.shared.refreshTokens { result in
            switch result {
            case .success(let jwts):
                completion(jwts)
            case .failure(let error):
                print(error.localizedDescription)
                // Log the user out if the refresh fails
            }
        }
    }
}

fileprivate class LoggingHandler: LoggingCallback {
    func log(message: String) {
        // Log Firebase message
    }
    
    func logNonFatal(nsError: NSError) {
        // Log Firebase non-fatal
    }
}
