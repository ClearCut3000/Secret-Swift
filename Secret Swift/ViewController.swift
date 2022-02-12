//
//  ViewController.swift
//  Secret Swift
//
//  Created by Николай Никитин on 11.02.2022.
//

import UIKit

class ViewController: UIViewController {

  //MARK: - Outlats
  @IBOutlet var secretText: UITextView!

  //MARK: - UIView Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    setNotifications()
    title = "Nothing to see here!"
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
    if let text = KeychainWrapper.standard.string(forKey: "SecretMessage") {
      secretText.text = text
    }
  }

  @objc private func saveSecretMessage() {
    guard secretText.isHidden == false else { return }
    KeychainWrapper.standard.set(secretText.text, forKey: "SecretMessage")
    secretText.resignFirstResponder()
    secretText.isHidden = true
    title = "Nothing to see here!"
  }

  //MARK: - Actions
  @IBAction func authenticateTapped(_ sender: Any) {
    unlockSecretText()
  }
}

