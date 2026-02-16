import Foundation

struct RemoteTagSyncInfo {
    let name: String
    let type: String
    let color: String?
}

struct RemoteSongSyncInfo {
    let id: String
    let appleMusicId: String?
    let artworkUrl: String?
    let tags: [RemoteTagSyncInfo]
}
