//
//  BangNetworking.swift
//  Banger!
//
//  Created by Hannes Nagel on 6/23/25.
//

import Foundation
import GameKit

// MARK: - Network Message Types
enum BangMessageType: String, Codable {
    case gameState = "gameState"
    case playCard = "playCard"
    case responseCard = "responseCard"
    case endTurn = "endTurn"
    case chatMessage = "chatMessage"
}

struct BangNetworkMessage: Codable {
    let type: BangMessageType
    let data: Data
    let timestamp: TimeInterval
    let playerID: String
    
    init(type: BangMessageType, data: Codable, playerID: String) throws {
        self.type = type
        self.data = try JSONEncoder().encode(data)
        self.timestamp = Date().timeIntervalSince1970
        self.playerID = playerID
    }
    
    func decode<T: Codable>(_ type: T.Type) throws -> T {
        return try JSONDecoder().decode(type, from: data)
    }
}

// MARK: - Specific Message Payloads
struct PlayCardMessage: Codable {
    let cardID: UUID
    let targetPlayerID: UUID?
    let gameStateChecksum: String
}

struct ResponseCardMessage: Codable {
    let cardID: UUID?
    let isAccepted: Bool
    let responseToPlayerID: UUID
}

struct EndTurnMessage: Codable {
    let playerID: UUID
    let discardedCards: [UUID]
}

struct ChatMessage: Codable {
    let message: String
    let senderName: String
}

// MARK: - Network Manager Extension
extension BangGameManager {
    
    // MARK: - Message Sending
    func sendPlayCard(_ card: Card, target: BangPlayer?) {
        guard let localPlayer = localPlayer else { return }
        
        let message = PlayCardMessage(
            cardID: card.id,
            targetPlayerID: target?.id,
            gameStateChecksum: gameState.checksum
        )
        
        sendMessage(type: .playCard, data: message, from: localPlayer)
    }
    
    func sendResponseCard(_ card: Card?, accepted: Bool, to player: BangPlayer) {
        guard let localPlayer = localPlayer else { return }
        
        let message = ResponseCardMessage(
            cardID: card?.id,
            isAccepted: accepted,
            responseToPlayerID: player.id
        )
        
        sendMessage(type: .responseCard, data: message, from: localPlayer)
    }
    
    func sendEndTurn(discardedCards: [Card]) {
        guard let localPlayer = localPlayer else { return }
        
        let message = EndTurnMessage(
            playerID: localPlayer.id,
            discardedCards: discardedCards.map { $0.id }
        )
        
        sendMessage(type: .endTurn, data: message, from: localPlayer)
    }
    
    func sendChatMessage(_ text: String) {
        guard let localPlayer = localPlayer else { return }
        
        let message = ChatMessage(
            message: text,
            senderName: localPlayer.displayName
        )
        
        sendMessage(type: .chatMessage, data: message, from: localPlayer)
    }
    
    private func sendMessage<T: Codable>(type: BangMessageType, data: T, from player: BangPlayer) {
        guard let match = myMatch else { return }
        
        do {
            let networkMessage = try BangNetworkMessage(
                type: type,
                data: data,
                playerID: player.id.uuidString
            )
            
            let messageData = try JSONEncoder().encode(networkMessage)
            try match.sendData(toAllPlayers: messageData, with: .reliable)
            
        } catch {
            print("Failed to send message: \(error)")
        }
    }
    
    // MARK: - Message Handling
    func handleNetworkMessage(_ data: Data, from player: GKPlayer) {
        do {
            let networkMessage = try JSONDecoder().decode(BangNetworkMessage.self, from: data)
            
            switch networkMessage.type {
            case .gameState:
                handleGameStateMessage(networkMessage)
                
            case .playCard:
                handlePlayCardMessage(networkMessage, from: player)
                
            case .responseCard:
                handleResponseCardMessage(networkMessage, from: player)
                
            case .endTurn:
                handleEndTurnMessage(networkMessage, from: player)
                
            case .chatMessage:
                handleChatMessage(networkMessage, from: player)
            }
            
        } catch {
            print("Failed to decode network message: \(error)")
        }
    }
    
    private func handleGameStateMessage(_ message: BangNetworkMessage) {
        do {
            let receivedGameState = try message.decode(GameState.self)
            
            // Validate and merge game state
            if receivedGameState.isNewerThan(gameState) {
                gameState = receivedGameState
            }
            
        } catch {
            print("Failed to handle game state message: \(error)")
        }
    }
    
    private func handlePlayCardMessage(_ message: BangNetworkMessage, from gkPlayer: GKPlayer) {
        do {
            let playCard = try message.decode(PlayCardMessage.self)
            
            // Find the player who sent the message
            guard let player = gameState.players.first(where: { $0.gkPlayer?.gamePlayerID == gkPlayer.gamePlayerID }),
                  let card = player.hand.first(where: { $0.id == playCard.cardID }) else {
                return
            }
            
            // Find target if specified
            let target = gameState.players.first(where: { $0.id == playCard.targetPlayerID })
            
            // Validate and execute the card
            if BangGameEngine.canPlayCard(card, by: player, in: gameState) {
                let result = BangGameEngine.executeCard(card, by: player, target: target, in: &gameState)
                
                if result.success {
                    // Remove card from player's hand
                    player.removeCard(card)
                    gameState.discardPile.append(card)
                    
                    // Send updated game state
                    sendGameState()
                    
                    // Add message to chat
                    messages.append(result.message)
                }
            }
            
        } catch {
            print("Failed to handle play card message: \(error)")
        }
    }
    
    private func handleResponseCardMessage(_ message: BangNetworkMessage, from gkPlayer: GKPlayer) {
        do {
            let response = try message.decode(ResponseCardMessage.self)
            
            // Handle player response (e.g., Missed! card, Beer card)
            guard let respondingPlayer = gameState.players.first(where: { $0.gkPlayer?.gamePlayerID == gkPlayer.gamePlayerID }) else {
                return
            }
            
            if response.isAccepted {
                if let cardID = response.cardID,
                   let card = respondingPlayer.hand.first(where: { $0.id == cardID }) {
                    // Player played a response card
                    respondingPlayer.removeCard(card)
                    gameState.discardPile.append(card)
                    
                    messages.append("\(respondingPlayer.displayName) plays \(card.type.rawValue)")
                }
            } else {
                // Player chose not to respond or has no valid response
                // Apply the original effect
                if let targetPlayer = gameState.players.first(where: { $0.id == response.responseToPlayerID }) {
                    targetPlayer.takeDamage()
                    messages.append("\(respondingPlayer.displayName) takes 1 damage")
                    
                    if !targetPlayer.isAlive {
                        gameState.playerKilled(targetPlayer, by: nil)
                        messages.append("\(targetPlayer.displayName) is eliminated!")
                    }
                }
            }
            
            sendGameState()
            
        } catch {
            print("Failed to handle response card message: \(error)")
        }
    }
    
    private func handleEndTurnMessage(_ message: BangNetworkMessage, from gkPlayer: GKPlayer) {
        do {
            let endTurn = try message.decode(EndTurnMessage.self)
            
            // Validate it's the current player's turn
            guard let currentPlayer = gameState.currentPlayer,
                  currentPlayer.gkPlayer?.gamePlayerID == gkPlayer.gamePlayerID else {
                return
            }
            
            // Handle discarded cards
            for cardID in endTurn.discardedCards {
                if let cardIndex = currentPlayer.hand.firstIndex(where: { $0.id == cardID }) {
                    let discardedCard = currentPlayer.hand.remove(at: cardIndex)
                    gameState.discardPile.append(discardedCard)
                }
            }
            
            // Move to next player
            gameState.nextPlayer()
            sendGameState()
            
        } catch {
            print("Failed to handle end turn message: \(error)")
        }
    }
    
    private func handleChatMessage(_ message: BangNetworkMessage, from gkPlayer: GKPlayer) {
        do {
            let chat = try message.decode(ChatMessage.self)
            messages.append("\(chat.senderName): \(chat.message)")
            
        } catch {
            print("Failed to handle chat message: \(error)")
        }
    }
}

// MARK: - GameState Extensions
extension GameState {
    var checksum: String {
        // Create a checksum based on critical game state
        let data = "\(currentPlayerIndex)-\(phase.rawValue)-\(turnPhase.rawValue)-\(players.count)-\(deck.count)-\(lastUpdateTimestamp)"
        return String(data.hashValue)
    }
    
    func isNewerThan(_ other: GameState) -> Bool {
        // Compare using timestamps for proper version control
        return self.lastUpdateTimestamp > other.lastUpdateTimestamp
    }
}

// MARK: - Conflict Resolution
extension BangGameManager {
    
    func resolveGameStateConflict(_ remoteState: GameState) {
        // In case of conflicts, use a deterministic resolution strategy
        // For simplicity, we'll trust the state from the player with the lowest player ID
        
        guard let localPlayerID = localPlayer?.gkPlayer?.gamePlayerID,
              let remotePlayerID = gameState.players.first(where: { $0.gkPlayer != nil })?.gkPlayer?.gamePlayerID else {
            return
        }
        
        if remotePlayerID < localPlayerID {
            // Remote player has priority
            gameState = remoteState
        }
        // Otherwise, keep local state
    }
    
    func validateGameState() -> Bool {
        // Basic validation checks
        
        // Check player count (4-7 for proper Bang! gameplay)
        guard gameState.players.count >= 4 && gameState.players.count <= 7 else {
            return false
        }
        
        // Check current player index is valid
        guard gameState.currentPlayerIndex < gameState.players.count else {
            return false
        }
        
        // Check all players have valid life points
        for player in gameState.players {
            if player.currentLife < 0 || player.currentLife > player.maxLife {
                return false
            }
        }
        
        // Check deck and discard pile
        let totalCards = gameState.deck.count + gameState.discardPile.count + 
                        gameState.players.flatMap { $0.hand + $0.equipment }.count +
                        gameState.players.compactMap { $0.weapon }.count
        
        guard totalCards == 80 else { // Total cards in Bang! deck
            return false
        }
        
        return true
    }
}