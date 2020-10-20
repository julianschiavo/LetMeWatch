# 👁 LetMeWatch

**LetMeWatch** is a Swift Package that allows playing and loading `AVAsset`s with a server which requires client certificate authentication. Client certificate authentication (CCA) allows servers to authenticate that the client is legitimate and authorized to access the resources. This allows the server to avoid unwanted requests and costs.

An example of this is [Cloudflare's new API Shield](https://blog.cloudflare.com/introducing-api-shield/) feature, which makes it easy to require CCA to access resources on your server, avoiding other clients or browsers from loading the resources, which could result in costs to you.

This package contains code adapted from [Jared's great blog post on creating a custom `AVAssetResourceLoaderDelegate`](https://jaredsinclair.com/2016/09/03/implementing-avassetresourceload.html), available [on Github under the MIT License](https://github.com/jaredsinclair/sodes-audio-example).

<br>

## Requirements

**LetMeWatch** requires **iOS 14+** or **macOS 11+**. It depends on [LetMeIn](https://github.com/julianschiavo/letmein), a package by the same author which performs client certificate authentication. 

<br>

## Installation

You can use **LetMeWatch** as a Swift Package, or add it manually to your project. 

### Swift Package Manager (SPM)

Swift Package Manager is a way to add dependencies to your app, and is natively integrated with Xcode.

To add **LetMeWatch** with SPM, click `File` ► `Swift Packages` ► `Add Package Dependency...`, then type in the URL to this Github repo. Xcode will then add the package to your project and perform all the necessary work to build it.

```
https://github.com/julianschiavo/LetMeWatch
```

Alternatively, add the package to your `Package.swift` file.

```swift
let package = Package(
    // ...
    dependencies: [
        .package(url: "https://github.com/julianschiavo/LetMeWatch.git", from: "1.0.0")
    ],
    // ...
)
```

*See [SPM documentation](https://github.com/apple/swift-package-manager/tree/master/Documentation) to learn more.*

### Manually

If you prefer not to use SPM, you can also add **LetMeWatch** as a normal framework by building the Xcode project from this repository. (See other sources for instructions on doing this.)

<br>

## Usage

Create an instance of an authenticator, then use it as the delegate when performing `URLSession` requests.

First, set up the global configuration object for the package.

```swift
// Create a certificate file representation
let certificateFile = CertificateFile(fileName: "certificate", password: "12345678")

// Update the global configuration object
LetMeWatchConfiguration.certificateFile = certificateFile
```

*(See the [documentation for LetMeIn](https://github.com/julianschiavo/letmein) for more details about supported certificate types and creating `CertificateFile` objects.)*

Then, use `SignedAsset` instead of `AVAsset`—and you're done! **LetMeWatch** will handle loading the asset (byte-by-byte if supported by the server, allowing quicker playback) using client certificate authentication.

```swift
// Remote URL to the asset
let url = ...

// Create a signed asset
let asset = SignedAsset(url: url)

// Use the signed asset in place of an `AVAsset`
// For example, with `VideoPlayer` in SwiftUI
let playerItem = AVPlayerItem(asset: asset)
let avPlayer = AVPlayer(playerItem: playerItem)
let player = VideoPlayer(player: avPlayer)
```

<br>

## Examples

### Handling Loading Errors

You can provide an optional error handler to handle errors thrown when loading the asset info or data.

```swift
// Remote URL to the asset
let url = ...

// Create a signed asset
let asset = SignedAsset(url: url) { error in
    // Handle the error
}
```

<br>

## Contributing

Contributions and pull requests are welcomed by anyone! If you find an issue with **LetMeWatch**, file a Github Issue, or, if you know how to fix it, submit a pull request. 

Please review our [Code of Conduct](CODE_OF_CONDUCT.md) and [Contribution Guidelines](CONTRIBUTING.md) before making a contribution.

<br>

## Credit

**LetMeWatch** was created by [Julian Schiavo](https://twitter.com/julianschiavo), and available under the [MIT License](LICENSE). This package contains code adapted from [Jared's great blog post on creating a custom `AVAssetResourceLoaderDelegate`](https://jaredsinclair.com/2016/09/03/implementing-avassetresourceload.html), available [on Github under the MIT License](https://github.com/jaredsinclair/sodes-audio-example).

<br>

## License

Available under the MIT License. See the [License](LICENSE) for more info.
