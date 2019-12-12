import Foundation
import RxSwift

// MARK: Constants

internal let apiTokenEndpointURL = "https://accounts.spotify.com/api/token"
internal let profileServiceEndpointURL = "https://api.spotify.com/v1/me"
internal let topArtistsEndpointURL = "https://api.spotify.com/v1/me/top/artists"
internal let topTracksEndpointURL = "https://api.spotify.com/v1/me/top/tracks"
internal let recentlyPlayedEndpointURL = "https://api.spotify.com/v1/me/player/recently-played"

class Networking {
    internal func createSignInResponse(code: String,
                                       redirectURL: URL,
                                       clientID: String,
                                       clientSecret: String,
                                       completion: @escaping (SignInResponse?, Error?) -> Void) {
        let requestBody = "code=\(code)&grant_type=authorization_code&redirect_uri=\(redirectURL.absoluteString)"
        authRequest(requestBody: requestBody,
                    clientID: clientID,
                    clientSecret: clientSecret) { response, error in
                        if let response = response, error == nil {
                            let signInResponse = SignInResponse(accessToken: response.accessToken, refreshToken: response.refreshToken, expirationDate: Date(timeIntervalSinceNow: response.expiresIn))
                            completion(signInResponse, error)
                        } else {
                            DispatchQueue.main.async {
                                completion(nil, error)
                            }
                        }
        }
    }
    
    internal func renewSession(session: Session?,
                               clientID: String,
                               clientSecret: String,
                               completion: @escaping (Session?, Error?) -> Void) {
        guard let session = session, let refreshToken = session.token.refreshToken else {
            DispatchQueue.main.async {
                completion(nil, LoginError.noSession)
            }
            return
        }
        let requestBody = "grant_type=refresh_token&refresh_token=\(refreshToken)"
        
        Logger.info("Request body created: \(requestBody)")
        
        authRequest(requestBody: requestBody,
                    clientID: clientID,
                    clientSecret: clientSecret) { response, error in
                        if let response = response, error == nil {
                            let session = Session(
                                token: Token(accessToken: response.accessToken,
                                             refreshToken: session.token.refreshToken,
                                             expirationDate: Date(timeIntervalSinceNow: response.expiresIn)),
                                user: session.user)
                            
                            Logger.info("New session was created with access token: \(response.accessToken)")
                            
                            DispatchQueue.main.async {
                                completion(session, nil)
                            }
                        } else {
                            DispatchQueue.main.async {
                                completion(nil, error)
                            }
                        }
        }
    }
    
    internal func artistRequest(accessToken: String?, artistURL: URL) -> Observable<ArtistEndpointResponse> {
        guard let accessToken = accessToken else {
            fatalError("Unable to retrieve artist due to invalid access token")
        }
        
        return Observable<ArtistEndpointResponse>.create { observer in
            var urlRequest = URLRequest(url: artistURL)
            let authHeaderValue = "Bearer \(accessToken)"
            urlRequest.addValue(authHeaderValue, forHTTPHeaderField: "Authorization")
            
            let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
                do {
                    let artistResponse = try JSONDecoder().decode(ArtistEndpointResponse.self, from: data ?? Data())
                    observer.onNext(artistResponse)
                } catch let error {
                    observer.onError(error)
                }
                observer.onCompleted()
            }
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    internal func userRecentlyPlayedRequest(accessToken: String?, limit: Int) -> Observable<RecentlyPlayedTracksEndpointResponse> {
        guard let accessToken = accessToken else {
            fatalError("Unable to retrieve recently played due to invalid access token")
        }
        
        return Observable<RecentlyPlayedTracksEndpointResponse>.create { observer in
            var recentlyPlayedURL = URL(string: recentlyPlayedEndpointURL)!
            let queryItems = [URLQueryItem(name: "limit", value: String(limit))]
            recentlyPlayedURL.appending(queryItems)
            
            Logger.info("URL created: \(recentlyPlayedURL.absoluteString)")
            
            var urlRequest = URLRequest(url: recentlyPlayedURL)
            let authHeaderValue = "Bearer \(accessToken)"
            urlRequest.addValue(authHeaderValue, forHTTPHeaderField: "Authorization")
            
            let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
                do {
                    let trackResponse = try JSONDecoder().decode(RecentlyPlayedTracksEndpointResponse.self, from: data ?? Data())
                    observer.onNext(trackResponse)
                } catch let error {
                    observer.onError(error)
                }
                observer.onCompleted()
            }
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    internal func userTopArtistsRequest(accessToken: String?, timeRange: String, limit: Int) -> Observable<TopArtistsEndpointResponse> {
        guard let accessToken = accessToken else {
            fatalError("Unable to retrieve top artists due to invalid access token")
        }
        
        return Observable<TopArtistsEndpointResponse>.create { observer in
            var topArtistsURL = URL(string: topArtistsEndpointURL)!
            let queryItems = [URLQueryItem(name: "time_range", value: timeRange),
            URLQueryItem(name: "limit", value: String(limit))]
            topArtistsURL.appending(queryItems)
            
            Logger.info("URL created: \(topArtistsURL.absoluteString)")
            
            var urlRequest = URLRequest(url: topArtistsURL)
            let authHeaderValue = "Bearer \(accessToken)"
            urlRequest.addValue(authHeaderValue, forHTTPHeaderField: "Authorization")
            
            let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
                do {
                    let artistResponse = try JSONDecoder().decode(TopArtistsEndpointResponse.self, from: data ?? Data())
                    observer.onNext(artistResponse)
                } catch let error {
                    observer.onError(error)
                }
                observer.onCompleted()
            }
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    internal func userTopTracksRequest(accessToken: String?, timeRange: String, limit: Int) -> Observable<TopTracksEndpointResponse> {
        guard let accessToken = accessToken else {
            fatalError("Unable to retrieve top tracks due to invalid access token")
        }
        
        return Observable<TopTracksEndpointResponse>.create { observer in
            var topTracksURL = URL(string: topTracksEndpointURL)!
            let queryItems = [URLQueryItem(name: "time_range", value: timeRange),
            URLQueryItem(name: "limit", value: String(limit))]
            topTracksURL.appending(queryItems)
            
            Logger.info("URL created: \(topTracksURL.absoluteString)")
            
            var urlRequest = URLRequest(url: topTracksURL)
            let authHeaderValue = "Bearer \(accessToken)"
            urlRequest.addValue(authHeaderValue, forHTTPHeaderField: "Authorization")
            
            let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
                do {
                    let trackResponse = try JSONDecoder().decode(TopTracksEndpointResponse.self, from: data ?? Data())
                    observer.onNext(trackResponse)
                } catch let error {
                    observer.onError(error)
                }
                observer.onCompleted()
            }
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    internal func userProfileRequest(accessToken: String?) -> Observable<ProfileEndpointResponse> {
        guard let accessToken = accessToken else {
            fatalError("Unable to retrieve user profile due to invalid access token")
        }
        
        return Observable<ProfileEndpointResponse>.create { observer in
            let profileURL = URL(string: profileServiceEndpointURL)!
            var urlRequest = URLRequest(url: profileURL)
            let authHeaderValue = "Bearer \(accessToken)"
            urlRequest.addValue(authHeaderValue, forHTTPHeaderField: "Authorization")
            
            let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
                do {
                    let profileResponse = try JSONDecoder().decode(ProfileEndpointResponse.self, from: data ?? Data())
                    observer.onNext(profileResponse)
                } catch let error {
                    observer.onError(error)
                }
                observer.onCompleted()
            }
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        }
        .observeOn(MainScheduler.instance)
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
    }
    
    internal func getUserFromEndpoint(profileResponse: ProfileEndpointResponse) -> Observable<User> {
        
        return Observable<User>.create { observer in
            let user = User(country: profileResponse.country,
                            displayName: profileResponse.displayName,
                            email: profileResponse.email,
                            filterEnabled: profileResponse.filterEnabled,
                            profileUrl: profileResponse.profileUrl,
                            numberOfFollowers: profileResponse.numberOfFollowers,
                            endpointUrl: profileResponse.endpointUrl,
                            id: profileResponse.id,
                            avatarUrl: profileResponse.avatarUrl,
                            subscriptionLevel: profileResponse.subscriptionLevel,
                            uriUrl: profileResponse.uriUrl)
            
            observer.onNext(user)
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    private func authRequest(requestBody: String,
                             clientID: String,
                             clientSecret: String,
                             completion: @escaping (TokenEndpointResponse?, Error?) -> Void) {
        guard let authString = "\(clientID):\(clientSecret)"
            .data(using: .ascii)?.base64EncodedString(options: .endLineWithLineFeed) else {
                DispatchQueue.main.async {
                    completion(nil, LoginError.configurationMissing)
                }
                return
        }
        let endpoint = URL(string: apiTokenEndpointURL)!
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "content-type")
        urlRequest.httpMethod = "POST"
        
        let authHeaderValue = "Basic \(authString)"
        urlRequest.addValue(authHeaderValue, forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = requestBody.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: urlRequest,
                                              completionHandler: { (data, _, error) in
                                                if let data = data,
                                                    let authResponse = try? JSONDecoder().decode(TokenEndpointResponse.self, from: data), error == nil {
                                                    DispatchQueue.main.async {
                                                        completion(authResponse, error)
                                                    }
                                                } else {
                                                    DispatchQueue.main.async {
                                                        completion(nil, error)
                                                    }
                                                }
        })
        task.resume()
    }
    
}

public enum EndpointError: Error {
    case missingAccessToken
}