//
//  BangGameManager.swift
//  Banger!
//
//  Created by Hannes Nagel on 6/23/25.
//

import Foundation
import GameKit
import SwiftUI

@MainActor
@Observable
class BangGameManager: NSObject, GKMatchDelegate, GKLocalPlayerListener {
    
    // MARK: - Properties
    var matchAvailable = false
    var playingGame = false
    var myMatch: GKMatch? = nil
    var automatch = false
    
    // Game state
    var gameState = GameState()
    var localPlayer: BangPlayer?
    var messages: [String] = []
    
    // UI state
    var myAvatar = Image(systemName: "person.crop.circle")
    var showingMatchmaker = false
    var showingGameCenter = false
    var gameOverMessage = ""
    var showingGameOver = false
    var showingAuthenticationModal = false
    var authenticationViewController: UIViewController?
    
    // Error handling
    var lastError: Error?
    var showingError = false
    var errorMessage = ""
    
    // MARK: - Game Setup
    func authenticatePlayer() {
        GKLocalPlayer.local.authenticateHandler = { viewController, error in
            if let viewController = viewController {
                // Store the view controller for SwiftUI presentation
                self.authenticationViewController = viewController
                self.showingAuthenticationModal = true
                return
            }
            
            if let error = error {
                print("Authentication error: \(error.localizedDescription)")
                return
            }
            
            // Load player avatar
            GKLocalPlayer.local.loadPhoto(for: .small) { image, error in
                if let image = image {
                    Task { @MainActor in
                        self.myAvatar = Image(uiImage: image)
                    }
                }
            }
            
            // Register for invitations
            GKLocalPlayer.local.register(self)
            
            // Setup Game Center access point
            GKAccessPoint.shared.location = .topLeading
            GKAccessPoint.shared.showHighlights = true
            GKAccessPoint.shared.isActive = true
            
            self.matchAvailable = true
        }
    }
    
    // Remove rootViewController - we'll use SwiftUI modifiers instead
    
    // MARK: - Matchmaking
    func findRandomMatch() async {
        let request = GKMatchRequest()
        request.minPlayers = 4  // Original Bang! minimum for proper gameplay
        request.maxPlayers = 7
        
        do {
            let match = try await GKMatchmaker.shared().findMatch(for: request)
            startMatch(match)
        } catch {
            print("Matchmaking error: \(error.localizedDescription)")
        }
        
        automatch = false
    }
    
    func createMatchRequest() -> GKMatchRequest {
        let request = GKMatchRequest()
        request.minPlayers = 4  // Original Bang! minimum for proper gameplay
        request.maxPlayers = 7
        return request
    }
    
    // MARK: - Game Management
    func startMatch(_ match: GKMatch) {
        GKAccessPoint.shared.isActive = false
        playingGame = true
        myMatch = match
        myMatch?.delegate = self
        
        // Initialize game state
        setupGame()
    }
    
    private func setupGame() {
        guard let match = myMatch else { return }
        
        // Create players array including local player
        var players: [BangPlayer] = []
        
        // Add local player
        let localBangPlayer = BangPlayer(gkPlayer: GKLocalPlayer.local)
        players.append(localBangPlayer)
        localPlayer = localBangPlayer
        
        // Add remote players
        for gkPlayer in match.players {
            let bangPlayer = BangPlayer(gkPlayer: gkPlayer)
            players.append(bangPlayer)
        }
        
        // Shuffle players for random seating
        players.shuffle()
        
        // Assign positions
        for (index, player) in players.enumerated() {
            player.position = index
        }
        
        gameState.players = players
        
        // Assign roles
        let roles = BangDeck.getRoles(for: players.count).shuffled()
        for (index, player) in players.enumerated() {
            player.role = roles[index]
            if player.role == .sheriff {
                gameState.sheriffIndex = index
                gameState.currentPlayerIndex = index
            }
        }
        
        // Assign characters
        let characters = BangDeck.characters.shuffled()
        for (index, player) in players.enumerated() {
            player.character = characters[index]
            player.currentLife = player.character!.lifePoints
            player.maxLife = player.character!.lifePoints
            
            // Sheriff gets +1 life point
            if player.role == .sheriff {
                player.maxLife += 1
                player.currentLife += 1
            }
        }
        
        // Deal initial cards
        gameState.deck = BangDeck.createDeck()
        dealInitialCards()
        
        gameState.phase = .playing
        
        // Send initial game state to all players
        sendGameState()
    }
    
    private func dealInitialCards() {
        for player in gameState.players {
            let cardCount = player.currentLife
            for _ in 0..<cardCount {
                if let card = gameState.deck.popLast() {
                    player.addCard(card)
                }
            }
        }
    }
    
    // MARK: - Game Actions
    func playCard(_ card: Card, target: BangPlayer? = nil) {
        guard let currentPlayer = gameState.currentPlayer,
              currentPlayer.id == localPlayer?.id else { return }
        
        // Validate card play
        if !canPlayCard(card) { return }
        
        // Execute card effect
        executeCardEffect(card, target: target, player: currentPlayer)
        
        // Remove card from hand
        currentPlayer.removeCard(card)
        
        // Add to discard pile
        gameState.discardPile.append(card)
        
        // Send updated game state
        sendGameState()
    }
    
    private func canPlayCard(_ card: Card) -> Bool {
        // Check if only one BANG! per turn
        if card.type == .bang && gameState.bangPlayedThisTurn {
            return false
        }
        
        return true
    }
    
    private func executeCardEffect(_ card: Card, target: BangPlayer?, player: BangPlayer) {
        switch card.type {
        case .bang:
            if let target = target, player.canTarget(target, in: gameState.players) {
                // Target takes damage unless they play Missed!
                target.takeDamage()
                gameState.bangPlayedThisTurn = true
            }
            
        case .beer:
            player.heal()
            
        case .catBalou:
            if let target = target, !target.hand.isEmpty {
                // Force target to discard a random card
                let randomIndex = Int.random(in: 0..<target.hand.count)
                let discardedCard = target.hand.remove(at: randomIndex)
                gameState.discardPile.append(discardedCard)
            }
            
        case .panic:
            if let target = target, 
               player.distanceTo(target, in: gameState.players) == 1,
               !target.hand.isEmpty {
                // Draw random card from target
                let randomIndex = Int.random(in: 0..<target.hand.count)
                let stolenCard = target.hand.remove(at: randomIndex)
                player.addCard(stolenCard)
            }
            
        case .stagecoach:
            // Draw 2 cards
            for _ in 0..<2 {
                if let card = gameState.deck.popLast() {
                    player.addCard(card)
                }
            }
            
        case .wellsFargo:
            // Draw 3 cards
            for _ in 0..<3 {
                if let card = gameState.deck.popLast() {
                    player.addCard(card)
                }
            }
            
        case .saloon:
            // All players regain 1 life
            for p in gameState.players where p.isAlive {
                p.heal()
            }
            
        case .indians:
            // All other players discard BANG! or lose 1 life
            for p in gameState.players where p.id != player.id && p.isAlive {
                // For now, just make them lose life (AI will handle BANG! discard)
                p.takeDamage()
            }
            
        default:
            break
        }
        
        // Check for game over
        checkGameOver()
    }
    
    func endTurn() {
        guard let currentPlayer = gameState.currentPlayer,
              currentPlayer.id == localPlayer?.id else { return }
        
        // Discard excess cards
        let handLimit = currentPlayer.currentLife
        while currentPlayer.hand.count > handLimit {
            if let card = currentPlayer.hand.popLast() {
                gameState.discardPile.append(card)
            }
        }
        
        gameState.nextPlayer()
        sendGameState()
    }
    
    private func checkGameOver() {
        if gameState.isGameOver() {
            gameState.phase = .gameOver
            
            switch gameState.winner {
            case .sheriff:
                gameOverMessage = "Sheriff and Deputies win!"
            case .outlaw:
                gameOverMessage = "Outlaws win!"
            case .renegade:
                gameOverMessage = "Renegade wins!"
            default:
                gameOverMessage = "Game Over!"
            }
            
            showingGameOver = true
        }
    }
    
    func resetGame() {
        playingGame = false
        myMatch?.disconnect()
        myMatch?.delegate = nil
        myMatch = nil
        gameState = GameState()
        localPlayer = nil
        messages.removeAll()
        showingGameOver = false
        GKAccessPoint.shared.isActive = true
    }
    
    // MARK: - Networking
    func sendGameState() {
        guard let match = myMatch else { return }
        
        do {
            let data = try JSONEncoder().encode(gameState)
            try match.sendData(toAllPlayers: data, with: .reliable)
        } catch {
            print("Failed to send game state: \(error)")
        }
    }
    
    // MARK: - GKMatchDelegate
    nonisolated func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        Task { @MainActor in
            handleNetworkMessage(data, from: player)
        }
    }
    
    nonisolated func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        switch state {
        case .connected:
            print("Player connected: \(player.displayName)")
        case .disconnected:
            print("Player disconnected: \(player.displayName)")
            // Handle player disconnection
        case .unknown:
            print("Player connection state unknown")
        @unknown default:
            break
        }
    }
    
    nonisolated func match(_ match: GKMatch, didFailWithError error: Error?) {
        print("Match failed with error: \(error?.localizedDescription ?? "Unknown error")")
        Task { @MainActor in
            resetGame()
        }
    }
    
    // MARK: - GKLocalPlayerListener
    nonisolated func player(_ player: GKPlayer, didAccept invite: GKInvite) {
        // Handle invite acceptance by creating a match from the invite
        print("Player accepted invite from: \(player.displayName)")
        
        // Create match from invite
        Task { @MainActor in
            do {
                let match = try await GKMatchmaker.shared().match(for: invite)
                self.startMatch(match)
            } catch {
                print("Failed to create match from invite: \(error.localizedDescription)")
            }
        }
    }
}