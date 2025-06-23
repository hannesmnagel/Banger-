//
//  BangGameEngine.swift
//  Banger!
//
//  Created by Hannes Nagel on 6/23/25.
//

import Foundation

class BangGameEngine {
    
    // MARK: - Game Action Results
    struct GameActionResult {
        let success: Bool
        let message: String
        let requiresResponse: Bool
        let targetPlayer: BangPlayer?
        let cardToPlay: CardType?
        let error: BangGameError?
        
        init(success: Bool, message: String, requiresResponse: Bool = false, targetPlayer: BangPlayer? = nil, cardToPlay: CardType? = nil, error: BangGameError? = nil) {
            self.success = success
            self.message = message
            self.requiresResponse = requiresResponse
            self.targetPlayer = targetPlayer
            self.cardToPlay = cardToPlay
            self.error = error
        }
        
        static func failure(_ error: BangGameError) -> GameActionResult {
            return GameActionResult(success: false, message: error.localizedDescription, error: error)
        }
        
        static func success(_ message: String, requiresResponse: Bool = false, targetPlayer: BangPlayer? = nil, cardToPlay: CardType? = nil) -> GameActionResult {
            return GameActionResult(success: true, message: message, requiresResponse: requiresResponse, targetPlayer: targetPlayer, cardToPlay: cardToPlay)
        }
    }
    
    // MARK: - Card Validation
    static func canPlayCard(_ card: Card, by player: BangPlayer, in gameState: GameState) -> Bool {
        // Check if it's player's turn (except for Missed! and Beer)
        guard gameState.currentPlayer?.id == player.id || 
              card.type == .missed || 
              (card.type == .beer && player.currentLife == 0) else {
            return false
        }
        
        // Check BANG! limit per turn
        if card.type == .bang && gameState.bangPlayedThisTurn {
            // Exception: Willy the Kid or Volcanic weapon
            if player.character?.name != "Willy the Kid" && 
               player.weapon?.type != .volcanic {
                return false
            }
        }
        
        // Check equipment duplicates
        if card.isEquipment || card.isWeapon {
            let existingEquipment = player.equipment + [player.weapon].compactMap { $0 }
            if existingEquipment.contains(where: { $0.type == card.type }) {
                return false
            }
        }
        
        return true
    }
    
    static func getValidTargets(for card: Card, by player: BangPlayer, in gameState: GameState) -> [BangPlayer] {
        let alivePlayers = gameState.players.filter { $0.isAlive }
        
        switch card.type {
        case .bang:
            return alivePlayers.filter { target in
                target.id != player.id && player.canTarget(target, in: alivePlayers)
            }
            
        case .catBalou:
            return alivePlayers.filter { $0.id != player.id }
            
        case .panic:
            return alivePlayers.filter { target in
                target.id != player.id && 
                player.distanceTo(target, in: alivePlayers) == 1 &&
                (!target.hand.isEmpty || !target.equipment.isEmpty || target.weapon != nil)
            }
            
        case .duel:
            return alivePlayers.filter { $0.id != player.id }
            
        case .jail:
            return alivePlayers.filter { target in
                target.id != player.id && 
                target.role != .sheriff && 
                !target.equipment.contains(where: { $0.type == .jail })
            }
            
        default:
            return []
        }
    }
    
    // MARK: - Card Effects
    static func executeCard(_ card: Card, by player: BangPlayer, target: BangPlayer? = nil, in gameState: inout GameState) -> GameActionResult {
        
        switch card.type {
        case .bang:
            return executeBang(by: player, target: target, in: &gameState)
            
        case .missed:
            return .failure(.invalidCardPlay("Missed! can only be played in response to BANG!"))
            
        case .beer:
            return executeBeer(by: player, in: &gameState)
            
        case .catBalou:
            return executeCatBalou(by: player, target: target, in: &gameState)
            
        case .panic:
            return executePanic(by: player, target: target, in: &gameState)
            
        case .stagecoach:
            return executeStagecoach(by: player, in: &gameState)
            
        case .wellsFargo:
            return executeWellsFargo(by: player, in: &gameState)
            
        case .generalStore:
            return executeGeneralStore(by: player, in: &gameState)
            
        case .saloon:
            return executeSaloon(by: player, in: &gameState)
            
        case .indians:
            return executeIndians(by: player, in: &gameState)
            
        case .duel:
            return executeDuel(by: player, target: target, in: &gameState)
            
        case .gatling:
            return executeGatling(by: player, in: &gameState)
            
        case .dynamite, .jail:
            return executeEquipment(card, by: player, target: target, in: &gameState)
            
        case .barrel, .scope, .mustang:
            return executeEquipment(card, by: player, in: &gameState)
            
        default:
            if card.isWeapon {
                return executeWeapon(card, by: player, in: &gameState)
            }
            return .failure(.invalidCardPlay("Unknown card type"))
        }
    }
    
    // MARK: - Specific Card Implementations
    
    private static func executeBang(by player: BangPlayer, target: BangPlayer?, in gameState: inout GameState) -> GameActionResult {
        guard let target = target else {
            return .failure(.invalidTarget("BANG! requires a target"))
        }
        
        guard target.isAlive else {
            return .failure(.invalidTarget("Cannot target eliminated player"))
        }
        
        guard target.id != player.id else {
            return .failure(.invalidTarget("Cannot target yourself"))
        }
        
        let distance = player.distanceTo(target, in: gameState.players)
        guard distance <= player.weaponRange else {
            return .failure(.invalidDistance(distance, player.weaponRange))
        }
        
        gameState.bangPlayedThisTurn = true
        
        // Check for Slab the Killer - requires 2 Missed!
        let missedRequired = (player.character?.name == "Slab the Killer") ? 2 : 1
        
        // Target can respond with Missed! or Barrel
        return .success(
            "\(player.displayName) shoots at \(target.displayName)!",
            requiresResponse: true,
            targetPlayer: target,
            cardToPlay: .missed
        )
    }
    
    private static func executeBeer(by player: BangPlayer, in gameState: inout GameState) -> GameActionResult {
        // Beer has no effect with only 2 players
        let alivePlayers = gameState.players.filter { $0.isAlive }
        guard alivePlayers.count > 2 else {
            return .failure(.invalidCardPlay("Beer has no effect with 2 or fewer players"))
        }
        
        guard player.currentLife < player.maxLife else {
            return .failure(.invalidCardPlay("Already at maximum life"))
        }
        
        player.heal()
        return .success("\(player.displayName) drinks a beer and regains 1 life point")
    }
    
    private static func executeCatBalou(by player: BangPlayer, target: BangPlayer?, in gameState: inout GameState) -> GameActionResult {
        guard let target = target else {
            return .failure(.invalidTarget("Cat Balou requires a target"))
        }
        
        guard target.isAlive else {
            return .failure(.invalidTarget("Cannot target eliminated player"))
        }
        
        // Choose random card to discard
        var availableCards: [Card] = target.hand + target.equipment
        if let weapon = target.weapon {
            availableCards.append(weapon)
        }
        
        guard !availableCards.isEmpty else {
            return .failure(.invalidTarget("Target has no cards to discard"))
        }
        
        let cardToDiscard = availableCards.randomElement()!
        
        // Remove the card
        if target.hand.contains(where: { $0.id == cardToDiscard.id }) {
            target.removeCard(cardToDiscard)
        } else if target.equipment.contains(where: { $0.id == cardToDiscard.id }) {
            target.equipment.removeAll { $0.id == cardToDiscard.id }
        } else if target.weapon?.id == cardToDiscard.id {
            target.weapon = nil
        }
        
        gameState.discardPile.append(cardToDiscard)
        
        return .success("\(player.displayName) forces \(target.displayName) to discard a card")
    }
    
    private static func executePanic(by player: BangPlayer, target: BangPlayer?, in gameState: inout GameState) -> GameActionResult {
        guard let target = target else {
            return .failure(.invalidTarget("Panic! requires a target"))
        }
        
        guard target.isAlive else {
            return .failure(.invalidTarget("Cannot target eliminated player"))
        }
        
        guard player.distanceTo(target, in: gameState.players) == 1 else {
            return .failure(.invalidDistance(player.distanceTo(target, in: gameState.players), 1))
        }
        
        // Choose random card to steal
        var availableCards: [Card] = target.hand + target.equipment
        if let weapon = target.weapon {
            availableCards.append(weapon)
        }
        
        guard !availableCards.isEmpty else {
            return .failure(.invalidTarget("Target has no cards to steal"))
        }
        
        let cardToSteal = availableCards.randomElement()!
        
        // Remove card from target and add to player
        if target.hand.contains(where: { $0.id == cardToSteal.id }) {
            target.removeCard(cardToSteal)
            player.addCard(cardToSteal)
        } else if target.equipment.contains(where: { $0.id == cardToSteal.id }) {
            target.equipment.removeAll { $0.id == cardToSteal.id }
            player.addCard(cardToSteal)
        } else if target.weapon?.id == cardToSteal.id {
            target.weapon = nil
            player.addCard(cardToSteal)
        }
        
        return .success("\(player.displayName) steals a card from \(target.displayName)")
    }
    
    private static func executeStagecoach(by player: BangPlayer, in gameState: inout GameState) -> GameActionResult {
        for _ in 0..<2 {
            if let card = gameState.deck.popLast() {
                player.addCard(card)
            }
        }
        return .success("\(player.displayName) draws 2 cards")
    }
    
    private static func executeWellsFargo(by player: BangPlayer, in gameState: inout GameState) -> GameActionResult {
        for _ in 0..<3 {
            if let card = gameState.deck.popLast() {
                player.addCard(card)
            }
        }
        return .success("\(player.displayName) draws 3 cards")
    }
    
    private static func executeGeneralStore(by player: BangPlayer, in gameState: inout GameState) -> GameActionResult {
        let alivePlayers = gameState.players.filter { $0.isAlive }
        let cardsToReveal = min(alivePlayers.count, gameState.deck.count)
        
        guard cardsToReveal > 0 else {
            return .failure(.deckEmpty)
        }
        
        var revealedCards: [Card] = []
        for _ in 0..<cardsToReveal {
            if let card = gameState.deck.popLast() {
                revealedCards.append(card)
            }
        }
        
        // Implement proper turn-order selection starting with the player who played General Store
        let startingPlayerIndex = gameState.players.firstIndex(where: { $0.id == player.id }) ?? 0
        var currentPlayerIndex = startingPlayerIndex
        var availableCards = revealedCards
        
        // Each player selects a card in turn order
        for _ in 0..<alivePlayers.count {
            // Find next alive player
            var attempts = 0
            while !gameState.players[currentPlayerIndex].isAlive && attempts < gameState.players.count {
                currentPlayerIndex = (currentPlayerIndex + 1) % gameState.players.count
                attempts += 1
            }
            
            if gameState.players[currentPlayerIndex].isAlive && !availableCards.isEmpty {
                // For AI/automatic play, prioritize based on card value
                let selectedCard = selectBestCardForPlayer(from: availableCards, for: gameState.players[currentPlayerIndex])
                gameState.players[currentPlayerIndex].addCard(selectedCard)
                availableCards.removeAll { $0.id == selectedCard.id }
                
                currentPlayerIndex = (currentPlayerIndex + 1) % gameState.players.count
            }
        }
        
        // Discard any remaining cards
        gameState.discardPile.append(contentsOf: availableCards)
        
        return .success("General Store: each player selects a card in turn order")
    }
    
    // Helper function to select best card for a player
    private static func selectBestCardForPlayer(from cards: [Card], for player: BangPlayer) -> Card {
        // Priority order: BANG!, Missed!, Beer, Equipment, Others
        if let bangCard = cards.first(where: { $0.type == .bang }) {
            return bangCard
        }
        if let missedCard = cards.first(where: { $0.type == .missed }) {
            return missedCard
        }
        if let beerCard = cards.first(where: { $0.type == .beer && player.currentLife < player.maxLife }) {
            return beerCard
        }
        if let weaponCard = cards.first(where: { $0.isWeapon && player.weapon == nil }) {
            return weaponCard
        }
        if let equipmentCard = cards.first(where: { $0.isEquipment }) {
            return equipmentCard
        }
        
        // Return any remaining card
        return cards.first!
    }
    
    private static func executeSaloon(by player: BangPlayer, in gameState: inout GameState) -> GameActionResult {
        let alivePlayers = gameState.players.filter { $0.isAlive }
        for p in alivePlayers {
            p.heal()
        }
        return .success("All players regain 1 life point")
    }
    
    private static func executeIndians(by player: BangPlayer, in gameState: inout GameState) -> GameActionResult {
        let otherPlayers = gameState.players.filter { $0.isAlive && $0.id != player.id }
        
        for target in otherPlayers {
            // Check if player has BANG! to discard
            if target.hand.contains(where: { $0.type == .bang }) {
                // Remove BANG! card
                if let bangIndex = target.hand.firstIndex(where: { $0.type == .bang }) {
                    let discardedCard = target.hand.remove(at: bangIndex)
                    gameState.discardPile.append(discardedCard)
                }
            } else {
                // Take damage
                target.takeDamage()
                if !target.isAlive {
                    gameState.playerKilled(target, by: player)
                }
            }
        }
        
        return .success("Indians attack! Players discard BANG! or lose 1 life")
    }
    
    private static func executeDuel(by player: BangPlayer, target: BangPlayer?, in gameState: inout GameState) -> GameActionResult {
        guard let target = target else {
            return .failure(.invalidTarget("Duel requires a target"))
        }
        
        guard target.isAlive else {
            return .failure(.invalidTarget("Cannot target eliminated player"))
        }
        
        // Complete duel resolution with proper mechanics
        var currentResponder = target  // Target responds first
        var challenger = player
        var duelWinner: BangPlayer? = nil
        var duelLoser: BangPlayer? = nil
        
        // Duel continues until one player cannot or will not play BANG!
        while duelWinner == nil {
            // Check if current responder has BANG! cards available
            let availableBangCards = currentResponder.hand.filter { card in
                card.type == .bang || (currentResponder.character?.name == "Calamity Janet" && card.type == .missed)
            }
            
            if !availableBangCards.isEmpty {
                // Player has BANG! cards - automatically play one (simplified for AI)
                let cardToPlay = availableBangCards.first!
                currentResponder.removeCard(cardToPlay)
                gameState.discardPile.append(cardToPlay)
                
                // Switch roles: responder becomes challenger
                swap(&currentResponder, &challenger)
            } else {
                // Current responder has no BANG! cards - loses the duel
                duelLoser = currentResponder
                duelWinner = challenger
                break
            }
        }
        
        // Apply duel result
        if let loser = duelLoser, let winner = duelWinner {
            loser.takeDamage()
            
            if !loser.isAlive {
                gameState.playerKilled(loser, by: winner)
            }
            
            // Apply character abilities for damage taken
            if loser.character?.name == "Bart Cassidy" {
                applyCharacterAbility(loser.character!, player: loser, in: &gameState, trigger: "takeDamage")
            }
            
            if loser.character?.name == "El Gringo" {
                applyCharacterAbility(loser.character!, player: loser, in: &gameState, trigger: "takeDamage")
            }
        }
        
        return .success("\(player.displayName) challenges \(target.displayName) to a duel!")
    }
    
    private static func executeGatling(by player: BangPlayer, in gameState: inout GameState) -> GameActionResult {
        let otherPlayers = gameState.players.filter { $0.isAlive && $0.id != player.id }
        
        for target in otherPlayers {
            // Each player can be hit by Gatling (counts as BANG!)
            target.takeDamage()
            if !target.isAlive {
                gameState.playerKilled(target, by: player)
            }
        }
        
        return .success("\(player.displayName) shoots everyone with a Gatling gun!")
    }
    
    private static func executeEquipment(_ card: Card, by player: BangPlayer, target: BangPlayer? = nil, in gameState: inout GameState) -> GameActionResult {
        if card.type == .jail {
            guard let target = target else {
                return .failure(.invalidTarget("Jail requires a target"))
            }
            
            guard target.role != .sheriff else {
                return .failure(.invalidTarget("Cannot jail the Sheriff"))
            }
            
            target.equipment.append(card)
            return .success("\(target.displayName) is put in jail")
        } else {
            player.equipment.append(card)
            return .success("\(player.displayName) plays \(card.type.rawValue)")
        }
    }
    
    private static func executeWeapon(_ card: Card, by player: BangPlayer, in gameState: inout GameState) -> GameActionResult {
        // Discard current weapon if any
        if let currentWeapon = player.weapon {
            gameState.discardPile.append(currentWeapon)
        }
        
        player.weapon = card
        return .success("\(player.displayName) equips \(card.type.rawValue)")
    }
    
    // MARK: - Character Abilities
    static func applyCharacterAbility(_ character: Character, player: BangPlayer, in gameState: inout GameState, trigger: String) {
        switch character.name {
        case "Bart Cassidy":
            if trigger == "takeDamage" {
                if let card = gameState.deck.popLast() {
                    player.addCard(card)
                }
            }
            
        case "El Gringo":
            if trigger == "takeDamage", let attacker = gameState.players.first(where: { $0.id != player.id }) {
                if !attacker.hand.isEmpty {
                    let randomIndex = Int.random(in: 0..<attacker.hand.count)
                    let stolenCard = attacker.hand.remove(at: randomIndex)
                    player.addCard(stolenCard)
                }
            }
            
        case "Suzy Lafayette":
            if trigger == "handEmpty" && player.hand.isEmpty {
                if let card = gameState.deck.popLast() {
                    player.addCard(card)
                }
            }
            
        case "Vulture Sam":
            if trigger == "playerKilled", let killedPlayer = gameState.players.first(where: { !$0.isAlive }) {
                // Transfer all cards from killed player
                player.hand.append(contentsOf: killedPlayer.hand)
                player.hand.append(contentsOf: killedPlayer.equipment)
                if let weapon = killedPlayer.weapon {
                    player.hand.append(weapon)
                }
            }
            
        case "Sid Ketchum":
            if trigger == "canDiscardForLife" && player.hand.count >= 2 {
                // Can discard 2 cards to regain 1 life (handled in UI)
                break
            }
            
        case "Lucky Duke":
            if trigger == "draw" {
                // Draws 2 cards for any "draw!" effect and chooses the better one
                // This would be handled in the specific draw! implementations
                break
            }
            
        case "Calamity Janet":
            if trigger == "playCard" {
                // Can use BANG! as Missed! and vice versa
                // This is handled in card validation logic
                break
            }
            
        case "Willy the Kid":
            if trigger == "playBang" {
                // Can play unlimited BANG! cards (handled in validation)
                break
            }
            
        case "Slab the Killer":
            if trigger == "bangTarget" {
                // Players need 2 Missed! to cancel his BANG! (handled in BANG! resolution)
                break
            }
            
        case "Jourdonnais":
            if trigger == "bangReceived" {
                // Has permanent Barrel ability (handled in defense)
                break
            }
            
        case "Paul Regret":
            if trigger == "distance" {
                // Others see him at +1 distance (handled in distance calculation)
                break
            }
            
        case "Rose Doolan":
            if trigger == "distance" {
                // Sees others at -1 distance (handled in distance calculation)
                break
            }
            
        default:
            break
        }
    }
    
    // MARK: - Turn Phases
    static func executeDrawPhase(for player: BangPlayer, in gameState: inout GameState) {
        // First, handle special cards that trigger at turn start
        processTurnStartEffects(for: player, in: &gameState)
        
        var cardsToDraw = 2
        
        // Character abilities
        switch player.character?.name {
        case "Black Jack":
            // Draw first card and check if Heart or Diamond for bonus
            if let firstCard = gameState.deck.popLast() {
                player.addCard(firstCard)
                if firstCard.suit == "♥" || firstCard.suit == "♦" {
                    cardsToDraw += 1 // Bonus card
                }
                cardsToDraw -= 1 // Already drew one
            }
            
        case "Jesse Jones":
            // Can choose to draw from another player's hand or deck
            let otherPlayers = gameState.players.filter { $0.isAlive && $0.id != player.id && !$0.hand.isEmpty }
            if !otherPlayers.isEmpty && Bool.random() {
                // 50% chance to steal from another player
                let targetPlayer = otherPlayers.randomElement()!
                let randomIndex = Int.random(in: 0..<targetPlayer.hand.count)
                let stolenCard = targetPlayer.hand.remove(at: randomIndex)
                player.addCard(stolenCard)
                cardsToDraw -= 1
            }
            
        case "Kit Carlson":
            // Look at top 3 cards, choose 2
            var topCards: [Card] = []
            for _ in 0..<min(3, gameState.deck.count) {
                if let card = gameState.deck.popLast() {
                    topCards.append(card)
                }
            }
            
            if topCards.count >= 2 {
                // Kit Carlson chooses the 2 best cards (prioritize BANG!, Missed!, equipment)
                let sortedCards = topCards.sorted { card1, card2 in
                    let priority1 = getCardPriority(card1)
                    let priority2 = getCardPriority(card2)
                    return priority1 > priority2
                }
                
                player.addCard(sortedCards[0])
                player.addCard(sortedCards[1])
                
                // Put remaining cards back on deck
                for i in 2..<sortedCards.count {
                    gameState.deck.append(sortedCards[i])
                }
            }
            cardsToDraw = 0 // Already handled
            
        case "Pedro Ramirez":
            // Can choose to draw from discard pile
            if !gameState.discardPile.isEmpty && Bool.random() {
                let card = gameState.discardPile.removeLast()
                player.addCard(card)
                cardsToDraw -= 1
            }
            
        default:
            break
        }
        
        // Draw remaining cards
        for _ in 0..<cardsToDraw {
            if let card = gameState.deck.popLast() {
                player.addCard(card)
            }
        }
        
        gameState.turnPhase = .play
    }
    
    // MARK: - Helper Functions
    private static func getCardPriority(_ card: Card) -> Int {
        switch card.type {
        case .bang: return 10
        case .missed: return 9
        case .beer: return 8
        case .gatling: return 7
        case .duel: return 6
        case .indians: return 5
        case .catBalou, .panic: return 4
        case .stagecoach, .wellsFargo: return 3
        case .barrel, .scope, .mustang: return 2
        default: return 1
        }
    }
    
    // MARK: - Turn Start Effects
    static func processTurnStartEffects(for player: BangPlayer, in gameState: inout GameState) {
        // Process Dynamite
        if let dynamiteIndex = player.equipment.firstIndex(where: { $0.type == .dynamite }) {
            let dynamiteCard = player.equipment[dynamiteIndex]
            
            // Draw for Dynamite (Spades 2-9 explodes)
            if let drawnCard = gameState.deck.popLast() {
                gameState.discardPile.append(drawnCard)
                
                if drawnCard.suit == "♠" && ["2", "3", "4", "5", "6", "7", "8", "9"].contains(drawnCard.value) {
                    // Dynamite explodes!
                    player.equipment.remove(at: dynamiteIndex)
                    gameState.discardPile.append(dynamiteCard)
                    player.currentLife = max(0, player.currentLife - 3)
                    if player.currentLife == 0 {
                        player.isAlive = false
                    }
                } else {
                    // Pass Dynamite to next player
                    player.equipment.remove(at: dynamiteIndex)
                    let nextPlayerIndex = (player.position + 1) % gameState.players.count
                    if gameState.players[nextPlayerIndex].isAlive {
                        gameState.players[nextPlayerIndex].equipment.append(dynamiteCard)
                    }
                }
            }
        }
        
        // Process Jail
        if let jailIndex = player.equipment.firstIndex(where: { $0.type == .jail }) {
            let jailCard = player.equipment[jailIndex]
            
            // Draw for Jail (Hearts escapes)
            if let drawnCard = gameState.deck.popLast() {
                gameState.discardPile.append(drawnCard)
                
                if drawnCard.suit == "♥" {
                    // Escape from jail
                    player.equipment.remove(at: jailIndex)
                    gameState.discardPile.append(jailCard)
                } else {
                    // Stay in jail - skip turn
                    player.equipment.remove(at: jailIndex)
                    gameState.discardPile.append(jailCard)
                    gameState.turnPhase = .discard // Skip to discard phase
                    return
                }
            }
        }
    }
}