// The MIT License (MIT)
//
// Copyright (c) 2017 Alexander Grebenyuk (github.com/kean).

import Nuke
import RxSwift

public protocol Loading {
    func loadImage(with request: Nuke.Request) -> RxSwift.Single<Image>
}

public extension Loading {
    /// Loads an image with the given url.
    public func loadImage(with url: URL) -> RxSwift.Single<Image> {
        return loadImage(with: Nuke.Request(url: url))
    }
}

extension Nuke.Loader: Loading {

    /// Loads an image with the given request.
    public func loadImage(with request: Nuke.Request) -> RxSwift.Single<Image> {
        return _loadImage(loader: self, request: request)
    }
}

extension Nuke.Manager: Loading {

    /// Loads an image with the given request.
    public func loadImage(with request: Nuke.Request) -> RxSwift.Single<Image> {
        if let image = cachedImage(for: request) {
            return .just(image) // Return cached image synchronously
        } else {
            return _loadImage(loader: self, request: request)
        }
    }

    private func cachedImage(for request: Request) -> Image? {
        guard request.memoryCacheOptions.readAllowed else { return nil }
        return cache?[request]
    }
}

fileprivate func _loadImage<T: Nuke.Loading>(loader: T, request: Nuke.Request) -> RxSwift.Single<Image> {
    return Single<Image>.create { single in
        let cts = CancellationTokenSource()
        loader.loadImage(with: request, token: cts.token) { result in
            switch result {
            case let .success(image): single(.success(image))
            case let .failure(error): single(.error(error))
            }
        }
        return Disposables.create { cts.cancel() }
    }
}
