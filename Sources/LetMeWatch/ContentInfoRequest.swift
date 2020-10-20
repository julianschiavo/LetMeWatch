//
//  ContentInfoRequest.swift
//  LetMeWatch
//
//  Adapted from https://github.com/jaredsinclair/sodes-audio-example
//

import AVFoundation
import LetMeIn

/// A concrete subclass of `Request` representing a content information request
class ContentInfoRequest: NSObject, Request, HasLogger, URLSessionDataDelegate {
    
    /// The URL of the resource to load
    let resourceURL: URL
    
    /// The original `AVAssetResourceLoadingRequest` object from the `AVAssetResourceLoader`
    let avRequest: AVAssetResourceLoadingRequest
    
    /// The object representing the request for information about a resource
    let contentInfoRequest: AVAssetResourceLoadingContentInformationRequest
    
    /// The dispatch queue to execute the request on
    let queue: DispatchQueue
    
    /// A completion handler called when the request completes
    var completionHandler: ((Error?) -> Void)?
    
    /// The response to the request
    private var response: HTTPURLResponse?
    
    /// Whether the request has been cancelled
    private var isCancelled = false
    
    /// The data task for the request
    private var task: URLSessionDataTask?
    
    /// The URL session used for requests
    private var session: URLSession!
    
    /// Creates a new content info request for the specified resource
    /// - Parameters:
    ///   - url: The URL of the resource to load
    ///   - avRequest: An `AVAssetResourceLoadingRequest` object from an `AVAssetResourceLoader`
    ///   - contentInfoRequest: An object representing the request for information about a resource
    ///   - queue: The dispatch queue to execute the request on
    init(url: URL, avRequest: AVAssetResourceLoadingRequest, contentInfoRequest: AVAssetResourceLoadingContentInformationRequest, queue: DispatchQueue) {
        self.resourceURL = url
        self.avRequest = avRequest
        self.contentInfoRequest = contentInfoRequest
        self.queue = queue
        
        super.init()
        
        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }
    
    // MARK: - Public Methods
    
    /// Starts the request and network request
    func start() {
        logger.info("Starting (Resource: \(self.resourceURL.lastPathComponent))")
        let request = createURLRequest()
        task = session.dataTask(with: request)
        task?.resume()
    }
    
    /// Cancels the request
    func cancel() {
        logger.info("Cancelling (Resource: \(self.resourceURL.lastPathComponent))")
        isCancelled = true
        task?.cancel()
        if !avRequest.isCancelled, !avRequest.isFinished {
            avRequest.finishLoading()
        }
        session.invalidateAndCancel()
    }
    
    // MARK: - Private Methods
    
    /// Creates a URL request for the content info request
    /// - Returns: The URL request
    private func createURLRequest() -> URLRequest {
        var request = URLRequest(url: resourceURL)
        if let dataRequest = avRequest.dataRequest {
            // Nota Bene: Even though the content info request is often
            // accompanied by a data request, **do not** invoke the data
            // requests `respondWithData()` method as this will put the
            // asset loading request into an undefined state. This isn't
            // documented anywhere, but beware.
            request.setByteRange(dataRequest.byteRange)
        }
        return request
    }
    
    // MARK: - URLSessionDataDelegate
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        logger.info("Received Response (Resource: \(self.resourceURL.lastPathComponent))")
        
        guard !isCancelled,
              let response = response as? HTTPURLResponse
        else {
            completionHandler(.cancel)
            return
        }
        
        guard response.statusCode >= 200,
              response.statusCode <= 299
        else {
            logger.error("Invalid status code, task cancelled (Resource: \(self.resourceURL.lastPathComponent))")
            completionHandler(.cancel)
            return
        }
        
        self.response = response
        completionHandler(.allow)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard !isCancelled else { return }
        
        if let error = error {
            logger.error("Failed with error: \(error.localizedDescription) (Resource: \(self.resourceURL.lastPathComponent))")
        } else {
            logger.info("Completed (Resource: \(self.resourceURL.lastPathComponent))")
        }
        
        queue.async { [weak self] in
            guard let self = self, !self.isCancelled else { return }
            if let response = self.response {
                self.contentInfoRequest.update(with: response)
            }
            self.avRequest.finishLoading(with: error)
            self.completionHandler?(error)
            self.session.invalidateAndCancel()
        }
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        logger.info("Received Auth Challenge (Resource: \(self.resourceURL.lastPathComponent))")
        ClientCertificateAuthenticator.packageInstance.urlSession(session, didReceive: challenge, completionHandler: completionHandler)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        logger.info("Received Auth Challenge for Data Task (Resource: \(self.resourceURL.lastPathComponent))")
        ClientCertificateAuthenticator.packageInstance.urlSession(session, task: task, didReceive: challenge, completionHandler: completionHandler)
    }
}
