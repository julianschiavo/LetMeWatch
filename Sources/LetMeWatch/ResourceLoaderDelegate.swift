//
//  ResourceLoaderDelegate.swift
//  LetMeWatch
//
//  Adapted from https://github.com/jaredsinclair/sodes-audio-example
//

import AVFoundation
import LetMeIn

/// An `AVAssetResourceLoaderDelegate` that performs client certificate authentication on requests when required by the server
class ResourceLoaderDelegate: NSObject, HasLogger, AVAssetResourceLoaderDelegate {
    
    /// Called when an error occurs
    private var errorHandler: ((Error) -> Void)?
    
    /// A serial queue used for delegate methods called by `AVAssetResourceLoader`
    private let loaderQueue = DispatchQueue(label: "ResourceLoaderDelegate.loaderQueue")
    
    /// The request wrapper object containg references to all the info needed
    /// to process the current AVAssetResourceLoadingRequest.
    private var currentRequest: Request? {
        didSet {
            // Under conditions that I don't know how to reproduce, AVFoundation
            // sometimes fails to cancel previous requests that cover ~90% of
            // of the previous. It seems to happen when repeatedly seeking, but
            // it could have been programmer error. Either way, in my testing, I
            // found that cancelling (by finishing early w/out data) the
            // previous request, I can keep the activity limited to a single
            // request and vastly improve loading times, especially on poor
            // networks.
            oldValue?.cancel()
        }
    }
    
    // MARK: - Init
    
    /// Creates a new resource loader delegate for a `SignedAsset`
    /// - Parameters:
    ///   - asset: The asset for which to handle loading requests
    ///   - errorHandler: Called when an error occurs
    init(for asset: SignedAsset, errorHandler: ((Error) -> Void)? = nil) {
        self.errorHandler = errorHandler
        super.init()
        logger.info("Created (Resource: \(asset.url.lastPathComponent))")
        asset.resourceLoader.setDelegate(self, queue: loaderQueue)
    }
    
    // MARK: - Content Info Request
    
    /// Handles a content info request
    private func handleContentInfoRequest(for avRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let avContentInfoRequest = avRequest.contentInformationRequest,
              let url = avRequest.request.url?.withDefaultScheme
        else { return false }
        
        logger.info("Received Content Info Request (Resource: \(url.lastPathComponent))")
        
        let request = ContentInfoRequest(url: url, avRequest: avRequest, contentInfoRequest: avContentInfoRequest, queue: loaderQueue)
        request.completionHandler = { [weak self] error in
            guard let self = self else { return }
            if self.currentRequest === request {
                // Release `currentRequest` since we're done with it, but
                // only if the value of self.currentRequest didn't change
                // (since we just called `avRequest.finishLoading()`).
                self.currentRequest = nil
            }
            if let error = error {
                self.errorHandler?(error)
            }
        }
        
        currentRequest = request
        request.start()
        
        return true
    }
    
    // MARK: - Data Requests
    
    /// Convenience method for handling a data request. Uses a DataRequestLoader
    /// to load data from either the scratch file or the network, optimizing for
    /// the former to prevent unnecessary network usage.
    private func handleDataRequest(for loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let dataRequest = loadingRequest.dataRequest,
              let url = loadingRequest.request.url?.withDefaultScheme
        else { return false }
        
        logger.info("Received Data Request (Resource: \(url.lastPathComponent))")
        
        let request = DataRequest(url: url, avRequest: loadingRequest, dataRequest: dataRequest, queue: loaderQueue)
        request.completionHandler = { [weak self] error in
            guard let self = self else { return }
            if self.currentRequest === request {
                // Release `currentRequest` since we're done with it, but
                // only if the value of self.currentRequest didn't change
                // (since we just called `avRequest.finishLoading()`).
                self.currentRequest = nil
            }
            if let error = error {
                self.errorHandler?(error)
            }
        }
        
        currentRequest = request
        request.start()
        
        return true
    }
    
    // MARK: - AVAssetResourceLoaderDelegate
    
    /// Loads the requested resource, either a content info or data request. 
    /// - Parameters:
    ///   - resourceLoader: The `AVAssetResourceLoader` for which the request is being made
    ///   - avRequest: An `AVAssetResourceLoadingRequest` providing information about the request
    /// - Returns: Whether the request can be handled by this object
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        if loadingRequest.contentInformationRequest != nil {
            return handleContentInfoRequest(for: loadingRequest)
        } else if loadingRequest.dataRequest != nil {
            return handleDataRequest(for: loadingRequest)
        } else {
            logger.error("Received Invalid Request (Resource: \(loadingRequest.description))")
            return false
        }
    }
    
    /// Cancels the current request
    /// - Parameters:
    ///   - resourceLoader: The `AVAssetResourceLoader` for which the request is being made
    ///   - avRequest: The request to cancel
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        guard let currentRequest = currentRequest, loadingRequest === currentRequest.avRequest else { return }
        logger.info("Cancelling Request (Resource: \(loadingRequest.description))")
        currentRequest.cancel()
        self.currentRequest = nil
    }
    
    /// Handles an authentication challenge
    /// - Parameters:
    ///   - resourceLoader:The `AVAssetResourceLoader` for which the challenge is being made
    ///   - authenticationChallenge: The authentication challenge
    /// - Returns: Whether the challenge will be handled
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForResponseTo authenticationChallenge: URLAuthenticationChallenge) -> Bool {
        logger.info("Received Authentication Challenge")
        return ClientCertificateAuthenticator.packageInstance.resourceLoader(resourceLoader, shouldWaitForResponseTo: authenticationChallenge)
    }
}
