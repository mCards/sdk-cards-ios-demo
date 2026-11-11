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
import PassKit
import WebKit

class ViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var addToWalletButton: PKAddPassButton!
    
    // MARK: - Properties
    private var accessToken = ""
    private var isLoggedIn: Bool { !accessToken.isEmpty }
    private var userFullName = ""
    private var card: Card?
    private var cards: [Card] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addToWalletButton.addTarget(self, action: #selector(addCardToWallet), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Set / change PIN", style: .plain, target: self, action: #selector(selectPinCard))
        setupAuthSDK()
    }

    // MARK: - Methods
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
        let savedPhoneNumber = "" // Saved phone number used to pre-populate the login form
        let loginArgs = LoginArgs(savedPhoneNumber: savedPhoneNumber)
        
        activityIndicator.startAnimating()
        AuthSdkProvider.shared.auth0Authenticate(args: loginArgs) { [weak self] result in
            self?.activityIndicator.stopAnimating()
            
            switch result {
            case .success(let authSuccess):
                // Get any required data
                self?.accessToken = authSuccess.jwts.accessToken
                self?.userFullName = authSuccess.user.fullName
                self?.cards = []
                self?.card = nil
                
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
        activityIndicator.startAnimating()
        
        CardsSdkProvider.shared.getCards { [weak self] result in
            self?.activityIndicator.stopAnimating()
            
            switch result {
            case .success(let cards):
                self?.cards = cards
                self?.card = cards.first
                guard !cards.isEmpty else {
                    print("User has no cards")
                    return
                }
                
                self?.getCardWalletStatus()
                print("Fetched card: \(self?.card?.details?.title ?? "")")
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    private func getCardWalletStatus() {
        guard let card else { return }
        let status = CardsSdkProvider.shared.getCardWalletStatus(card: card)
        handleCardWalletStatus(status: status)
    }
    
    @objc private func addCardToWallet() {
        guard isLoggedIn, let card else {
            print("Login Required")
            return
        }
        
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
    
    @objc private func selectPinCard() {
        let eligibleCards = cards.filter { $0.cardIssuer == .MARQETA && $0.status == "active" }
        guard !eligibleCards.isEmpty else {
            showMessage("Log in with a UAT user who has an active Marqeta card first.")
            return
        }
        let picker = UIAlertController(title: "Choose a card", message: nil, preferredStyle: .alert)
        for selectedCard in eligibleCards {
            picker.addAction(UIAlertAction(
                title: "\(selectedCard.details?.title ?? "Card") •••• \(selectedCard.details?.last4 ?? "")",
                style: .default
            ) { [weak self] _ in self?.openPinManagement(for: selectedCard) })
        }
        picker.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(picker, animated: true)
    }

    private func openPinManagement(for selectedCard: Card) {
        // A WebView navigation cannot use the SDK's API token-refresh interceptor.
        activityIndicator.startAnimating()
        AuthSdkProvider.shared.refreshTokens { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.activityIndicator.stopAnimating()
                switch result {
                case .success(let jwts):
                    self.accessToken = jwts.accessToken
                    self.setupCardsSDK()
                    let controller = PinViewController(card: selectedCard, jwts: jwts) { [weak self] in
                        // The issuer may still report PIN pending on this first refresh.
                        self?.getCards()
                    }
                    self.present(UINavigationController(rootViewController: controller), animated: true)
                case .failure(let error):
                    self.showMessage(error.localizedDescription)
                }
            }
        }
    }

    private func showMessage(_ message: String) {
        let alert = UIAlertController(title: "Cards SDK Demo", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func handleCardWalletStatus(status: CSDKWalletStatus) {
        switch status {
        case .notAdded:
            addToWalletButton.isHidden = false
        case .added:
            addToWalletButton.isHidden = true
        case .notActivated:
            addToWalletButton.isHidden = true
            /*
             Take any required additional action like showing a status text to the user
             prompting them to open the wallet app to activate the card.
             */
        default:
            break
        }
    }
    
    // MARK: - Actions
    @IBAction func tappedLogin(_ sender: Any) {
        login()
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

// MARK: - LoggingCallback
fileprivate class LoggingHandler: LoggingCallback {
    func log(message: String) {
        // Log Firebase message
    }
    
    func logNonFatal(nsError: NSError) {
        // Log Firebase non-fatal
    }
}

// The SDK installs the UXT bridge. This screen never reads or handles the PIN.
private final class PinViewController: UIViewController, CSDKPinActionListener, WKNavigationDelegate {
    private let card: Card
    private let jwts: JWTs
    private let onComplete: () -> Void
    private let webView = WKWebView()
    private var completed = false

    init(card: Card, jwts: JWTs, onComplete: @escaping () -> Void) {
        self.card = card
        self.jwts = jwts
        self.onComplete = onComplete
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("Use init(card:jwts:onComplete:)") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Set / change PIN"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(close))
        view.backgroundColor = .systemBackground
        webView.navigationDelegate = self
        webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
        CardsSdkProvider.shared.showCardPinManagement(
            card: card, webView: webView, jwts: jwts, listener: self)
    }

    @objc private func close() { dismiss(animated: true) }

    func onPinActionCompleted(_ action: CSDKPinAction) {
        // Activation/reveal events do not mean that PIN setup has completed.
        guard action == .setPin, !completed else { return }
        completed = true
        dismiss(animated: true, completion: onComplete)
    }

    func onPinActionFailed(_ action: CSDKPinAction, error: String?) {
        showError(error ?? "PIN update failed. Retry in the page or close this screen.")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showError(error.localizedDescription)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showError(error.localizedDescription)
    }

    private func showError(_ message: String) {
        guard presentedViewController == nil else { return }
        let alert = UIAlertController(title: "PIN management", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
