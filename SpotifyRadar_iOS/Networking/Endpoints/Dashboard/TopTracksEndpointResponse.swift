//
//  TopTracksEndpointResponse.swift
//  SpotifyDaily
//
//  Created by Kevin Li on 12/7/19.
//  Copyright © 2019 Kevin Li. All rights reserved.
//

import Foundation

fileprivate struct TopTracksEndpointModel: Decodable {
    // MARK: - Item
    struct Item: Codable {
        let album: Album
        let artists: [Artist]
        let durationMS: Int
        let externalUrls: ExternalUrls
        let id: String
        let name: String
        let previewURL: String?

        enum CodingKeys: String, CodingKey {
            case album, artists
            case durationMS = "duration_ms"
            case externalUrls = "external_urls"
            case name
            case id
            case previewURL = "preview_url"
        }
    }

    // MARK: - Album
    struct Album: Codable {
        let artists: [Artist]
        let images: [Image]

        enum CodingKeys: String, CodingKey {
            case artists
            case images
        }
    }

    // MARK: - Artist
    struct Artist: Codable {
        let name: String

        enum CodingKeys: String, CodingKey {
            case name
        }
    }

    // MARK: - ExternalUrls
    struct ExternalUrls: Codable {
        let spotify: String
    }

    // MARK: - Image
    struct Image: Codable {
        let url: String
    }
    
    var items: [Item]
}

struct TopTracksEndpointResponse: Decodable {
    var tracks = [Track]()
    
    init(from decoder: Decoder) throws {
        let response = try TopTracksEndpointModel(from: decoder)
        
        for item in response.items {
            let trackName = item.name
            let trackId = item.id
            let trackDuration = item.durationMS.msToSeconds.minuteSecondMS
            let externalURL = URL(string: item.externalUrls.spotify)!
            
            var artistNames = ""
            for artist in item.artists {
                artistNames += "\(artist.name), "
            }
            artistNames.removeLast(2)
            
            let albumImage = item.album.images.count > 0 ? URL(string: item.album.images.first!.url) : nil
            
            let track = Track(name: trackName, id: trackId, duration: trackDuration, artistNames: artistNames, albumImage: albumImage, externalURL: externalURL)
            
            tracks.append(track)
        }
    }
}
