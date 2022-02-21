//
//  ViewController.swift
//  CercacorHomeExercise
//
//  Created by Marko Polietaiev on 2022-02-18.
//

import UIKit

class MainViewController: UIViewController {

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var returnButton: UIButton!
    @IBOutlet weak var pinningSwitch: UISwitch!
    @IBOutlet weak var certificatePinningSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pinningSwitch.isOn = false
        self.certificatePinningSwitch.onTintColor = .clear
        self.certificatePinningSwitch.tintColor = .clear
        self.certificatePinningSwitch.isEnabled = false
        self.textField.text = "https://www.google.com"
    }
    
    private func presentAlert(_ message: String) {
        let alert = UIAlertController(title: "Response", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func performCertificateValidation() {
        self.textField.resignFirstResponder()
        guard let text = textField.text, let url = URL(string: text) else { return }
        PinningManager.shared.callApi(url: url, isPinning: self.pinningSwitch.isOn, isCertificatePinning: !self.certificatePinningSwitch.isOn) { response in
            DispatchQueue.main.sync {
                self.presentAlert(response)
            }
        }
    }
    
    @IBAction func pinningChanged(_ sender: Any) {
        self.certificatePinningSwitch.isEnabled = self.pinningSwitch.isOn
    }
    

    @IBAction func returnButtonPressed(_ sender: Any) {
        self.performCertificateValidation()
    }
}

extension MainViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.performCertificateValidation()
        textField.resignFirstResponder()
        return true
    }
}
