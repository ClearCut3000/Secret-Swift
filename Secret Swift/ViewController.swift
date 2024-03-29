//
//  ViewController.swift
//  Secret Swift
//
//  Created by Николай Никитин on 11.02.2022.
//

import LocalAuthentication
import UIKit

class ViewController: UIViewController {

  //MARK: - Outlats
  @IBOutlet var secretText: UITextView!

  //MARK: - UIView Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    setNotifications()
    title = "Nothing to see here!"
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(saveSecretMessage))
    navigationItem.rightBarButtonItem?.isEnabled = false
    navigationItem.rightBarButtonItem?.tintColor = .clear
  }

  //MARK: - Methods
  private func setNotifications() {
    let notificationCenter = NotificationCenter.default
    notificationCenter.addObserver(self, selector: #selector(adjustForKeyBoard), name: UIResponder.keyboardWillHideNotification, object: nil)
    notificationCenter.addObserver(self, selector: #selector(adjustForKeyBoard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    notificationCenter.addObserver(self, selector: #selector(saveSecretMessage), name: UIApplication.willResignActiveNotification, object: nil)
  }

  @objc private func adjustForKeyBoard(notification: Notification) {
    guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
    let keyboardScreenEnd = keyboardValue.cgRectValue
    let keyboardViewEndFrame = view.convert(keyboardScreenEnd, from: view.window)
    if notification.name == UIResponder.keyboardWillHideNotification {
      secretText.contentInset = .zero
    } else {
      secretText.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
    }
    secretText.scrollIndicatorInsets = secretText.contentInset
    let selectedRange = secretText.selectedRange
    secretText.scrollRangeToVisible(selectedRange)
  }

  private func unlockSecretText() {
    secretText.isHidden = false
    title = "Secret stuff!"
    navigationItem.rightBarButtonItem?.isEnabled = true
    navigationItem.rightBarButtonItem?.tintColor = nil
    if let text = KeychainWrapper.standard.string(forKey: "SecretMessage") {
      secretText.text = text
    }
  }

  @objc private func saveSecretMessage() {
    guard secretText.isHidden == false else { return }
    KeychainWrapper.standard.set(secretText.text, forKey: "SecretMessage")
    secretText.resignFirstResponder()
    secretText.isHidden = true
    navigationItem.rightBarButtonItem?.isEnabled = false
    navigationItem.rightBarButtonItem?.tintColor = .clear
    title = "Nothing to see here!"
  }

  private func loginWithPassword() {
    let alert = UIAlertController(title: "Enter your login and password, please", message: nil, preferredStyle: .alert)
    alert.addTextField { login in
      login.placeholder = "Enter your login here"
    }
    alert.addTextField { password in
      password.placeholder = "Enter your password where"
      password.isSecureTextEntry = true
    }
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    alert.addAction(UIAlertAction(title: "Check", style: .default, handler: { [weak self] _ in
      if let login = alert.textFields?[0].text {
        if let storedLogin = KeychainWrapper.standard.string(forKey: "Login") {
          if login == storedLogin {
            if let password = alert.textFields?[1].text {
              if let storedPassword = KeychainWrapper.standard.string(forKey: "Password") {
                if password == storedPassword {
                  self?.unlockSecretText()
                }
              }
            }
          }
        } else {
          self?.nonStoredPassData()
        }
      }
    }))
    present( alert, animated: true)
  }

  private func nonStoredPassData() {
    let alert = UIAlertController(title: "You haven't set your username and password yet.", message: "Please enter your username and password for further authentication.", preferredStyle: .alert)
    alert.addTextField { login in
      login.placeholder = "Your Login..."
    }
    alert.addTextField { password in
      password.placeholder = "Your password..."
      password.isSecureTextEntry = true
    }
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
      guard let login = alert.textFields?[0].text else { return }
      guard let password = alert.textFields?[1].text else { return }
      if !login.isEmpty && !password.isEmpty {
        KeychainWrapper.standard.set(login, forKey: "Login")
        KeychainWrapper.standard.set(password, forKey: "Password")
      }
    }))
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    present(alert, animated: true)
  }

  //MARK: - Actions
  @IBAction func authenticateTapped(_ sender: Any) {
    let context = LAContext()
    var error: NSError?
    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
      let reason = "Identify yourself!"
      context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
        DispatchQueue.main.async {
          if success {
            self?.unlockSecretText()
          } else {
            let alert = UIAlertController(title: "Authentication failed!", message: "You can't be verified. Please, try again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            alert.addAction(UIAlertAction(title: "Use login and password", style: .default, handler: { [weak self] _ in
              self?.loginWithPassword()
            }))
            self?.present(alert, animated: true)
          }
        }
      }
    } else {
      let alert = UIAlertController(title: "Biometry unavailable!", message: "Your device is not configured for biometric authentication.", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default))
      present(alert, animated: true)
    }
  }
}

