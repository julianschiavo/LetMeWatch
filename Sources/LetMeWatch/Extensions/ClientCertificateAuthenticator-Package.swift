//
//  ClientCertificateAuthenticator-Package.swift
//  LetMeWatch
//

import LetMeIn

extension ClientCertificateAuthenticator {
    private static var _packageInstance: ClientCertificateAuthenticator?
    
    /// The shared instance of `ClientCertificateAuthenticator` for this package
    static var packageInstance: ClientCertificateAuthenticator {
        get {
            guard let instance = _packageInstance else {
                fatalError("[LetMeWatch] You must configure the client certificate file before creating a `SignedAsset`")
            }
            return instance
        }
        set {
            _packageInstance = newValue
        }
    }
}
