//
//  pact_iosTests.swift
//  pact-iosTests
//
//  Created by Dale Evans on 15/04/2026.
//

import XCTest
import PactSwift
import Foundation

@testable import pact_ios

class DisneyPactTest: XCTestCase  {

    static var mockService = MockService(
        consumer: "disney_ios_app",
        provider: "disney_api",
    )

    func testGetAllCharacters() async throws {
        DisneyPactTest.mockService
            .uponReceiving("a request to retrieve all characters")
            .given("a list of Disney characters exists")
            .withRequest(method: .GET, path: "/character")
            .willRespondWith(
                status: 200,
                body: [
                    "data": Matcher.EachLike([
                        "_id": Matcher.SomethingLike(112),
                        "name": Matcher.SomethingLike("Mickey Mouse"),
                        "imageUrl": Matcher.SomethingLike("https://example.com/mickey.png")
                    ])
                ]
            )
        
        try await DisneyPactTest.mockService.run { baseURL in
            let repository = DisneyRepository(baseURL: baseURL)
            
            let characters = try await repository.getCharacters()
            let character = try XCTUnwrap(characters.first, "Expected at least one character")

            XCTAssertEqual(character.id, 112)
            XCTAssertEqual(character.name, "Mickey Mouse")
            XCTAssertEqual(character.imageUrl, "https://example.com/mickey.png")
        }
    }
}

struct DisneyCharacter: Codable {
    let id: Int
    let name: String
    let imageUrl: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case imageUrl
    }
}

struct DisneyResponse: Codable {
    let data: [DisneyCharacter]
}

class DisneyRepository {
    private let baseURL: String
    private let session: URLSession

    init(baseURL: String = "https://api.disneyapi.dev", session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func getCharacters() async throws -> [DisneyCharacter] {
        guard let url = URL(string: "\(baseURL)/character") else {
            throw URLError(.badURL)
        }

        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(DisneyResponse.self, from: data)
        return response.data
    }

    func getCharacter(id: Int) async throws -> DisneyCharacter {
        guard let url = URL(string: "\(baseURL)/character/\(id)") else {
            throw URLError(.badURL)
        }

        let (data, _) = try await session.data(from: url)
        let character = try JSONDecoder().decode(DisneyCharacter.self, from: data)
        return character
    }
}
