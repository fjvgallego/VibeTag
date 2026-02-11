import Foundation
import MusicKit
import Observation
import MediaPlayer

@Observable
@MainActor
class AppleMusicSongRepositoryImpl: SongRepository {
    
    func fetchAnalysis(for song: VTSong) async throws -> [AnalyzedTag] {
        let endpoint = SongEndpoint.analyze(id: song.id, appleMusicId: song.appleMusicId, artist: song.artist, title: song.title, artworkUrl: song.artworkUrl)
        do {
            let response: AnalyzeResponseDTO = try await APIClient.shared.request(endpoint)
            return response.tags.map { AnalyzedTag(name: $0.name, description: $0.description) }
        } catch let apiError as APIError {
            throw apiError.toAppError
        } catch {
            throw AppError.networkError(original: error)
        }
    }
    
    func fetchBatchAnalysis(for songs: [VTSong]) async throws -> [SongAnalysisResult] {
        let songInputs = songs.map { song in
            BatchAnalyzeRequestDTO.SongInput(
                songId: song.id,
                appleMusicId: song.appleMusicId,
                title: song.title,
                artist: song.artist,
                album: song.album,
                genre: song.genre,
                artworkUrl: song.artworkUrl
            )
        }
        
        let dto = BatchAnalyzeRequestDTO(songs: songInputs)
        let endpoint = SongEndpoint.analyzeBatch(dto: dto)
        
        do {
            let response: BatchAnalyzeResponseDTO = try await APIClient.shared.request(endpoint)
            
            return response.results.compactMap { result in
                guard let songId = result.songId else { return nil }
                return SongAnalysisResult(
                    songId: songId,
                    tags: result.tags.map { AnalyzedTag(name: $0.name, description: $0.description) }
                )
            }
        } catch let apiError as APIError {
            throw apiError.toAppError
        } catch {
            throw AppError.networkError(original: error)
        }
    }
    
    func fetchSongs(limit: Int) async throws -> [VTSong] {
        let maxSafetyLimit = 1000
        let effectiveLimit = limit <= 0 ? maxSafetyLimit : limit
        
        // Step A: The Bridge (MPMediaQuery)
        let query = MPMediaQuery.songs()
        guard let items = query.items else { return [] }
        
        let itemsToProcess = Array(items.prefix(effectiveLimit))
        var vtSongs: [VTSong] = []
        var catalogIDsToFetch: [MusicItemID] = []
        var idMapping: [MusicItemID: String] = [:] // catalogID -> persistentID
        
        for item in itemsToProcess {
            let persistentID = String(item.persistentID)
            
            // Fallback / Initial Data
            let song = VTSong(
                id: persistentID,
                appleMusicId: nil,
                title: item.title ?? "Unknown Title",
                artist: item.artist ?? "Unknown Artist",
                album: item.albumTitle,
                genre: item.genre,
                artworkUrl: nil,
                dateAdded: item.dateAdded
            )
            
            vtSongs.append(song)
            
            let storeID = item.playbackStoreID
            if storeID != "0" && !storeID.isEmpty {
                let musicItemID = MusicItemID(storeID)
                catalogIDsToFetch.append(musicItemID)
                idMapping[musicItemID] = persistentID
            }
        }
        
        // Step B: Async Resolution (MusicKit)
        if !catalogIDsToFetch.isEmpty {
            // Process in chunks to avoid URL length limits or timeouts
            let chunkSize = 50
            for i in stride(from: 0, to: catalogIDsToFetch.count, by: chunkSize) {
                let end = min(i + chunkSize, catalogIDsToFetch.count)
                let chunk = Array(catalogIDsToFetch[i..<end])
                
                do {
                    let request = MusicCatalogResourceRequest<Song>(matching: \.id, memberOf: chunk)
                    let response = try await request.response()
                    
                    for catalogSong in response.items {
                        if let persistentID = idMapping[catalogSong.id],
                           let vtSong = vtSongs.first(where: { $0.id == persistentID }) {
                            
                            vtSong.appleMusicId = catalogSong.id.rawValue
                            // Resolve fresh high-res artwork
                            if let artwork = catalogSong.artwork {
                                vtSong.artworkUrl = artwork.url(width: 500, height: 500)?.absoluteString
                            }
                        }
                    }
                } catch {
                    print("MusicKit enrichment chunk failed: \(error.localizedDescription)")
                    // Fallback is already handled: vtSongs has local metadata
                }
            }
        }
        
        return vtSongs
    }

    func searchSongs(query: String) async throws -> [VTSong] {
        var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
        request.limit = 25
        let response = try await request.response()
        return response.songs.map { mapToVTSong($0) }
    }
    
    private func mapToVTSong(_ song: Song) -> VTSong {
        return VTSong(
            id: song.id.rawValue,
            appleMusicId: song.id.rawValue,
            title: song.title,
            artist: song.artistName,
            album: song.albumTitle,
            genre: song.genreNames.first,
            artworkUrl: song.artwork?.url(width: 500, height: 500)?.absoluteString,
            dateAdded: song.libraryAddedDate ?? Date()
        )
    }
}
