//
//  BangErrors.swift
//  Banger!
//
//  Created by Hannes Nagel on 6/23/25.
//

import Foundation

// MARK: - Game Errors
enum BangGameError: LocalizedError {
    case invalidPlayerCount(Int)
    case playerNotFound(String)
    case cardNotFound(String)
    case invalidCardPlay(String)
    case invalidTarget(String)
    case gameNotStarted
    case gameAlreadyStarted
    case notPlayerTurn(String)
    case insufficientCards
    case invalidGameState(String)
    case characterAbilityFailed(String)
    case deckEmpty
    case invalidDistance(Int, Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidPlayerCount(let count):
            return "Invalid player count: \(count). Bang! requires 4-7 players."
        case .playerNotFound(let playerName):
            return "Player not found: \(playerName)"
        case .cardNotFound(let cardName):
            return "Card not found: \(cardName)"
        case .invalidCardPlay(let reason):
            return "Cannot play card: \(reason)"
        case .invalidTarget(let reason):
            return "Invalid target: \(reason)"
        case .gameNotStarted:
            return "Game has not started yet"
        case .gameAlreadyStarted:
            return "Game has already started"
        case .notPlayerTurn(let playerName):
            return "It's not \(playerName)'s turn"
        case .insufficientCards:
            return "Not enough cards to perform this action"
        case .invalidGameState(let reason):
            return "Invalid game state: \(reason)"
        case .characterAbilityFailed(let ability):
            return "Character ability failed: \(ability)"
        case .deckEmpty:
            return "Deck is empty and cannot be shuffled"
        case .invalidDistance(let actual, let required):
            return "Target at distance \(actual), but requires distance \(required) or less"
        }
    }
}

// MARK: - Network Errors
enum BangNetworkError: LocalizedError {
    case connectionFailed(String)
    case messageEncodingFailed(String)
    case messageDecodingFailed(String)
    case playerDisconnected(String)
    case gameStateSyncFailed(String)
    case invalidMessage(String)
    case timeoutError
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        case .messageEncodingFailed(let message):
            return "Failed to encode message: \(message)"
        case .messageDecodingFailed(let message):
            return "Failed to decode message: \(message)"
        case .playerDisconnected(let playerName):
            return "Player disconnected: \(playerName)"
        case .gameStateSyncFailed(let reason):
            return "Game state synchronization failed: \(reason)"
        case .invalidMessage(let message):
            return "Invalid message received: \(message)"
        case .timeoutError:
            return "Network operation timed out"
        case .unauthorized:
            return "Unauthorized network operation"
        }
    }
}

// MARK: - GameKit Errors
enum BangGameKitError: LocalizedError {
    case authenticationFailed(String)
    case matchmakingFailed(String)
    case invitationFailed(String)
    case achievementError(String)
    case leaderboardError(String)
    case playerNotAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed(let reason):
            return "GameKit authentication failed: \(reason)"
        case .matchmakingFailed(let reason):
            return "Matchmaking failed: \(reason)"
        case .invitationFailed(let reason):
            return "Game invitation failed: \(reason)"
        case .achievementError(let reason):
            return "Achievement error: \(reason)"
        case .leaderboardError(let reason):
            return "Leaderboard error: \(reason)"
        case .playerNotAuthenticated:
            return "Player must be authenticated with GameKit"
        }
    }
}

// MARK: - Result Types
typealias BangGameResult<T> = Result<T, BangGameError>
typealias BangNetworkResult<T> = Result<T, BangNetworkError>
typealias BangGameKitResult<T> = Result<T, BangGameKitError>