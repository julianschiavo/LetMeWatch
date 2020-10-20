//
//  LetMeWatchConfiguration.swift
//  LetMeWatch
//

import LetMeIn

/// The configuration object for the package
public struct LetMeWatchConfiguration {
    private static var _certificateFile: CertificateFile?
    
    /// The client certificate file to use for authentication
    public static var certificateFile: CertificateFile {
        get {
            guard let file = _certificateFile else {
                fatalError("[LetMeWatch] You must configure the client certificate file before creating a `SignedAsset`")
            }
            return file
        }
        set {
            _certificateFile = newValue
            ClientCertificateAuthenticator.packageInstance = ClientCertificateAuthenticator(certificateFile: newValue)
        }
    }
}
