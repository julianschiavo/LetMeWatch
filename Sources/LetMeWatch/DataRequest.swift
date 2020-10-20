//
//  DataRequest.swift
//  LetMeWatch
//
//  Adapted from https://github.com/jaredsinclair/sodes-audio-example
//

import AVFoundation
import LetMeIn
import OSLog

/// A concrete subclass of `Request` representing a data request
class DataRequest: NSObject, Request, HasLogger, URLSessionDataDelegate {
   
    /// The URL of the resource to load
    let resourceURL: URL
    
    /// The original `AVAssetResourceLoadingRequest` object from the `AVAssetResourceLoader`
    let avRequest: AVAssetResourceLoadingRequest
    
    /// The object representing the request for data for a resource
    let dataRequest: AVAssetResourceLoadingDataRequest
    
    /// The dispatch queue to execute the request on
    let queue: DispatchQueue
    
    /// A completion handler called when the request completes
    var completionHandler: ((Error?) -> Void)?
    
    /// The range of bytes requested
    private var requestedRange: ByteRange
    
    /// The current byte offset
    private var currentOffset: Int
    
    /// The response to the request
    private var response: HTTPURLResponse?
    
    /// The data task for the request
    private var task: URLSessionDataTask?
    
    /// The URL session used for requests
    private var session: URLSession!
    
    /// Whether the request has been cancelled
    private var isCancelled = false
    
    init(url: URL, avRequest: AVAssetResourceLoadingRequest, dataRequest: AVAssetResourceLoadingDataRequest, queue: DispatchQueue) {
        self.resourceURL = url
        self.avRequest = avRequest
        self.dataRequest = dataRequest
        self.queue = queue
        
        let lowerBound = Int(dataRequest.requestedOffset)   // e.g. 0, for Range(0..<4)
        let length = dataRequest.requestedLength            // e.g. 3, for Range(0..<4)
        let upperBound = Int(lowerBound) + length           // e.g. 4, for Range(0..<4)
        self.requestedRange = (lowerBound..<upperBound)
        self.currentOffset = requestedRange.lowerBound
        
        super.init()
        
        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }
    
    func start() {
        logger.info("Starting (Resource: \(self.resourceURL.lastPathComponent))")
        let request = createURLRequest()
        task = session.dataTask(with: request)
        task?.resume()
    }
    
    func cancel() {
        logger.info("Cancelling (Resource: \(self.resourceURL.lastPathComponent))")
        isCancelled = true
        task?.cancel()
        if !avRequest.isCancelled && !avRequest.isFinished {
            avRequest.finishLoading()
        }
        session.invalidateAndCancel()
    }
    
    // MARK: - Private Methods
    
    /// Creates a URL request for the data request
    /// - Returns: The URL request
    private func createURLRequest() -> URLRequest {
        var request = URLRequest(url: resourceURL)
        request.setByteRange(requestedRange)
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
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard !isCancelled else { return }
        
        logger.info("Received Data (Resource: \(self.resourceURL.lastPathComponent))")
        
        queue.async { [weak self] in
            guard let self = self, !self.isCancelled else { return }
            let range: ByteRange = self.currentOffset ..< (self.currentOffset + data.count)
            self.currentOffset = range.upperBound
            self.dataRequest.respond(with: data)
        }
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
