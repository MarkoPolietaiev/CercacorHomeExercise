//
//  PinningManager.swift
//  CercacorHomeExercise
//
//  Created by Marko Polietaiev on 2022-02-18.
//

import Foundation
import Security
import CommonCrypto

class PinningManager: NSObject, URLSessionDelegate {
    
    static let shared = PinningManager()
    
    var isCertificatePinning: Bool = false
    var hardcodedPublicKey: String = "EumkTYs+nSg5q/mGi38Fjyg/I7lBU59PhayJy7/fx5k="
    
    let rsa2048Asn1Header:[UInt8] = [
            0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
            0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
        ]
        
        private func sha256(data : Data) -> String {
            var keyWithHeader = Data(rsa2048Asn1Header)
            keyWithHeader.append(data)
            
            var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
            
            keyWithHeader.withUnsafeBytes {
                _ = CC_SHA256($0, CC_LONG(keyWithHeader.count), &hash)
            }
            return Data(hash).base64EncodedString()
        }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Check if we want pinning via certificate or public key
        if self.isCertificatePinning {
            // Compare remote and local certificates
            
            let certificate = SecTrustGetCertificateAtIndex(serverTrust, 2)
            
            let policy = NSMutableArray()
            policy.add(SecPolicyCreateSSL(true, challenge.protectionSpace.host as CFString))
            
            // Let swift Security library check if caertificate is trusted
            let isSecuredServer = SecTrustEvaluateWithError(serverTrust, nil)
            
            // Get data from certificate we got
            let remoteCertData: NSData = SecCertificateCopyData(certificate!)
            
            // Init path to our local certificate
            guard let pathToCertificate = Bundle.main.path(forResource: "GTS Root R1", ofType: "cer") else {
                fatalError("No local certificate found")
            }
            let localCertData = NSData(contentsOfFile: pathToCertificate)
            
            // If certificate is trusted and remote data is equal to local then validation was successful
            if isSecuredServer, remoteCertData.isEqual(to: localCertData! as Data) {
                completionHandler(.useCredential, URLCredential.init(trust: serverTrust))
            } else {
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        } else {
            // Compare public keys
            if let certificate =  SecTrustGetCertificateAtIndex(serverTrust, 2) {
                // Get public key from certificate we got
                let serverPublicKey = SecCertificateCopyKey(certificate)
                let serverPublicKeyData = SecKeyCopyExternalRepresentation(serverPublicKey!, nil)
                let data:Data = serverPublicKeyData! as Data
                let serverHashKey = sha256(data: data)
                
                // If remote public key and our local hardcoded public keys are equal then validation was successful
                if serverHashKey == self.hardcodedPublicKey {
                    print("public key Pinning Completed Successfully")
                    completionHandler(.useCredential, URLCredential.init(trust: serverTrust))
                } else {
                    completionHandler(.cancelAuthenticationChallenge,nil)
                }
            }
        }
    }
    
    func callApi(url: URL, isCertificatePinning: Bool, completion: @escaping ((String) -> () )) {
        let session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: nil)
        self.isCertificatePinning = isCertificatePinning
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                if error.localizedDescription == "canceled" {
                    completion("Pinning failed")
                } else {
                    completion("Something went wrong")
                }
            }
            if let data = data {
                
//                let str = String(decoding: data, as: UTF8.self)
//                print(str)
                
                if self.isCertificatePinning {
                    completion("Pinning successful with Certificate")
                } else {
                    completion("Pinning successful with Public Key")
                }
                
            }
        }.resume()
    }
}
