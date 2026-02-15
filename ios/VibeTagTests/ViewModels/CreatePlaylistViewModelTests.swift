import Testing
import Foundation
@testable import VibeTag

// MARK: - Helpers

@MainActor private func makeSUT(
    generateUseCase: MockGeneratePlaylistUseCase = MockGeneratePlaylistUseCase(),
    exportUseCase: MockExportPlaylistUseCase = MockExportPlaylistUseCase()
) -> (sut: CreatePlaylistViewModel, generate: MockGeneratePlaylistUseCase, export: MockExportPlaylistUseCase) {
    let sut = CreatePlaylistViewModel(
        generatePlaylistUseCase: generateUseCase,
        exportPlaylistUseCase: exportUseCase
    )
    return (sut, generateUseCase, exportUseCase)
}

private func makeResponse(
    title: String = "Chill Evening",
    description: String = "Relaxing vibes",
    songs: [GeneratePlaylistResponseDTO.SongDTO] = []
) -> GeneratePlaylistResponseDTO {
    GeneratePlaylistResponseDTO(playlistTitle: title, description: description, usedTags: [], songs: songs)
}

private func makeSongDTO(id: String, appleMusicId: String?) -> GeneratePlaylistResponseDTO.SongDTO {
    GeneratePlaylistResponseDTO.SongDTO(
        id: id, title: "Song \(id)", artist: "Artist",
        appleMusicId: appleMusicId, artworkUrl: nil, tags: []
    )
}

// MARK: - generatePlaylist

@MainActor
@Suite("CreatePlaylistViewModel.generatePlaylist")
struct GeneratePlaylistTests {

    @Test("Does nothing when prompt is empty")
    func doesNothingForEmptyPrompt() async {
        let (sut, generate, _) = makeSUT()
        sut.prompt = ""
        await sut.generatePlaylist()
        #expect(generate.executeCallCount == 0)
    }

    @Test("Does nothing when prompt is only whitespace")
    func doesNothingForWhitespacePrompt() async {
        let (sut, generate, _) = makeSUT()
        sut.prompt = "   "
        await sut.generatePlaylist()
        #expect(generate.executeCallCount == 0)
    }

    @Test("Sets result on success")
    func setsResultOnSuccess() async {
        let response = makeResponse(title: "Study Session")
        let generate = MockGeneratePlaylistUseCase()
        generate.executeResult = .success(response)
        let (sut, _, _) = makeSUT(generateUseCase: generate)
        sut.prompt = "music for studying"

        await sut.generatePlaylist()

        #expect(sut.result?.playlistTitle == "Study Session")
    }

    @Test("Sets isLoading to false after success")
    func isLoadingFalseAfterSuccess() async {
        let (sut, _, _) = makeSUT()
        sut.prompt = "jazz vibes"
        await sut.generatePlaylist()
        #expect(sut.isLoading == false)
    }

    @Test("Sets isLoading to false after failure")
    func isLoadingFalseAfterFailure() async {
        let generate = MockGeneratePlaylistUseCase()
        generate.executeResult = .failure(AppError.serverError(statusCode: 500))
        let (sut, _, _) = makeSUT(generateUseCase: generate)
        sut.prompt = "jazz vibes"
        await sut.generatePlaylist()
        #expect(sut.isLoading == false)
    }

    @Test("Sets errorMessage on failure")
    func setsErrorMessageOnFailure() async {
        let generate = MockGeneratePlaylistUseCase()
        generate.executeResult = .failure(AppError.serverError(statusCode: 503))
        let (sut, _, _) = makeSUT(generateUseCase: generate)
        sut.prompt = "something"
        await sut.generatePlaylist()
        #expect(sut.errorMessage != nil)
    }

    @Test("Does not set result on failure")
    func doesNotSetResultOnFailure() async {
        let generate = MockGeneratePlaylistUseCase()
        generate.executeResult = .failure(AppError.unknown)
        let (sut, _, _) = makeSUT(generateUseCase: generate)
        sut.prompt = "something"
        await sut.generatePlaylist()
        #expect(sut.result == nil)
    }

    @Test("Clears previous result before a new generation")
    func clearsPreviousResult() async {
        let (sut, _, _) = makeSUT()
        sut.result = makeResponse(title: "Old Playlist")
        sut.prompt = "new prompt"
        await sut.generatePlaylist()
        // result is reset to nil at the start, then set to the new response
        #expect(sut.result?.playlistTitle != "Old Playlist")
    }

    @Test("Clears previous errorMessage before a new generation")
    func clearsPreviousErrorMessage() async {
        let (sut, _, _) = makeSUT()
        sut.errorMessage = "old error"
        sut.prompt = "something"
        await sut.generatePlaylist()
        #expect(sut.errorMessage == nil)
    }
}

// MARK: - exportPlaylist

@MainActor
@Suite("CreatePlaylistViewModel.exportPlaylist")
struct ExportPlaylistTests {

    @Test("Does nothing when result is nil")
    func doesNothingWhenResultIsNil() async {
        let (sut, _, export) = makeSUT()
        sut.result = nil
        await sut.exportPlaylist()
        #expect(export.executeCallCount == 0)
    }

    @Test("Does nothing when already exporting")
    func doesNothingWhenAlreadyExporting() async {
        let (sut, _, export) = makeSUT()
        sut.result = makeResponse()
        sut.isExporting = true
        await sut.exportPlaylist()
        #expect(export.executeCallCount == 0)
    }

    @Test("Does nothing when already exported")
    func doesNothingWhenAlreadyExported() async {
        let (sut, _, export) = makeSUT()
        sut.result = makeResponse()
        sut.isExported = true
        await sut.exportPlaylist()
        #expect(export.executeCallCount == 0)
    }

    @Test("Sets isExported to true on success")
    func setsIsExportedOnSuccess() async {
        let (sut, _, _) = makeSUT()
        sut.result = makeResponse()
        await sut.exportPlaylist()
        #expect(sut.isExported == true)
    }

    @Test("Sets isExporting to false after success")
    func isExportingFalseAfterSuccess() async {
        let (sut, _, _) = makeSUT()
        sut.result = makeResponse()
        await sut.exportPlaylist()
        #expect(sut.isExporting == false)
    }

    @Test("Sets isExporting to false after failure")
    func isExportingFalseAfterFailure() async {
        let export = MockExportPlaylistUseCase()
        export.executeShouldThrow = AppError.unknown
        let (sut, _, _) = makeSUT(exportUseCase: export)
        sut.result = makeResponse()
        await sut.exportPlaylist()
        #expect(sut.isExporting == false)
    }

    @Test("Sets errorMessage on failure")
    func setsErrorMessageOnFailure() async {
        let export = MockExportPlaylistUseCase()
        export.executeShouldThrow = AppError.unknown
        let (sut, _, _) = makeSUT(exportUseCase: export)
        sut.result = makeResponse()
        await sut.exportPlaylist()
        #expect(sut.errorMessage != nil)
    }

    @Test("Does not set isExported on failure")
    func doesNotSetIsExportedOnFailure() async {
        let export = MockExportPlaylistUseCase()
        export.executeShouldThrow = AppError.unknown
        let (sut, _, _) = makeSUT(exportUseCase: export)
        sut.result = makeResponse()
        await sut.exportPlaylist()
        #expect(sut.isExported == false)
    }

    @Test("Passes playlist title and description to the export use case")
    func passesTitleAndDescription() async {
        let export = MockExportPlaylistUseCase()
        let (sut, _, _) = makeSUT(exportUseCase: export)
        sut.result = makeResponse(title: "Morning Run", description: "High energy")
        await sut.exportPlaylist()
        #expect(export.executeLastName == "Morning Run")
        #expect(export.executeLastDescription == "High energy")
    }

    @Test("Passes only non-nil appleMusicIds to the export use case")
    func passesOnlyNonNilAppleMusicIds() async {
        let export = MockExportPlaylistUseCase()
        let (sut, _, _) = makeSUT(exportUseCase: export)
        sut.result = makeResponse(songs: [
            makeSongDTO(id: "s1", appleMusicId: "am-1"),
            makeSongDTO(id: "s2", appleMusicId: nil),       // should be excluded
            makeSongDTO(id: "s3", appleMusicId: "am-3")
        ])
        await sut.exportPlaylist()
        #expect(export.executeLastAppleMusicIds == ["am-1", "am-3"])
    }

    @Test("Passes empty appleMusicIds when no songs have an Apple Music ID")
    func passesEmptyIdsWhenNoneAvailable() async {
        let export = MockExportPlaylistUseCase()
        let (sut, _, _) = makeSUT(exportUseCase: export)
        sut.result = makeResponse(songs: [
            makeSongDTO(id: "s1", appleMusicId: nil),
            makeSongDTO(id: "s2", appleMusicId: nil)
        ])
        await sut.exportPlaylist()
        #expect(export.executeLastAppleMusicIds == [])
    }

    @Test("Clears errorMessage at the start of a new export")
    func clearsErrorMessageAtStart() async {
        let (sut, _, _) = makeSUT()
        sut.errorMessage = "stale error"
        sut.result = makeResponse()
        await sut.exportPlaylist()
        #expect(sut.errorMessage == nil)
    }
}
