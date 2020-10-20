//
//  ContentInfoRequest.swift
//  LetMeWatch
//
//  Adapted from https://github.com/jaredsinclair/sodes-audio-example
//

import AVFoundation
import LetMeIn

/// A concrete subclass of `Request` representing a content information request
class ContentInfoRequest: NSObject, Request, HasLogger, URLSessionDelegate, URLSessionTaskDelegate {
    
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
    
    /// Whether the request has been cancelled
    private var isCancelled = false
    
    /// The task for the request
    private var task: URLSessionDownloadTask?
    
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
        task = session.downloadTask(with: request) { _, response, error in
            let result = Result<URLResponse, Error>(success: response, failure: error)
            self.queue.async { [weak self] in
                guard let self = self else { return }
                self.requestDidFinish(result: result)
            }
        }
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
    
    /// Completes the request, updating the necessary objects and calling handlers
    /// - Parameter result: The result of the request
    private func requestDidFinish(result: Result<URLResponse, Error>) {
        switch result {
        case let .success(response):
            logger.info("Completed (Resource: \(self.resourceURL.lastPathComponent))")
            contentInfoRequest.update(with: response)
            avRequest.finishLoading()
            completionHandler?(nil)
        case let .failure(error):
            logger.error("Failed with error: \(error.localizedDescription) (Resource: \(self.resourceURL.lastPathComponent))")
            avRequest.finishLoading(with: error)
            completionHandler?(error)
        }
        session.invalidateAndCancel()
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        logger.info("Received Auth Challenge (Resource: \(self.resourceURL.lastPathComponent))")
        ClientCertificateAuthenticator.packageInstance.urlSession(session, didReceive: challenge, completionHandler: completionHandler)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        logger.info("Received Auth Challenge for Data Task (Resource: \(self.resourceURL.lastPathComponent))")
        ClientCertificateAuthenticator.packageInstance.urlSession(session, task: task, didReceive: challenge, completionHandler: completionHandler)
    }
}
