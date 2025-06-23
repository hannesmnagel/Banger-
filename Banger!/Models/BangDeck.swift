//
//  BangDeck.swift
//  Banger!
//
//  Created by Hannes Nagel on 6/23/25.
//

import Foundation

struct BangDeck {
    
    // MARK: - Characters
    static let characters: [Character] = [
        Character(
            name: "Bart Cassidy",
            lifePoints: 4,
            ability: "Each time he loses a life point, he immediately draws a card from the deck.",
            description: "4 life points"
        ),
        Character(
            name: "Black Jack",
            lifePoints: 4,
            ability: "During phase 1 of his turn, he must show the second card he draws: if it's Heart or Diamonds, he draws one additional card.",
            description: "4 life points"
        ),
        Character(
            name: "Calamity Janet",
            lifePoints: 4,
            ability: "She can use BANG! cards as Missed! cards and vice versa.",
            description: "4 life points"
        ),
        Character(
            name: "El Gringo",
            lifePoints: 3,
            ability: "Each time he loses a life point due to a card played by another player, he draws a random card from that player's hand.",
            description: "3 life points"
        ),
        Character(
            name: "Jesse Jones",
            lifePoints: 4,
            ability: "During phase 1 of his turn, he may choose to draw the first card from the deck or randomly from any other player's hand.",
            description: "4 life points"
        ),
        Character(
            name: "Jourdonnais",
            lifePoints: 4,
            ability: "He is considered to have a Barrel card in play at all times.",
            description: "4 life points"
        ),
        Character(
            name: "Kit Carlson",
            lifePoints: 4,
            ability: "During phase 1 of his turn, he looks at the top three cards of the deck and chooses 2 to draw.",
            description: "4 life points"
        ),
        Character(
            name: "Lucky Duke",
            lifePoints: 4,
            ability: "Each time he is required to 'draw!', he flips the top two cards and chooses the result he prefers.",
            description: "4 life points"
        ),
        Character(
            name: "Paul Regret",
            lifePoints: 3,
            ability: "He is considered to have a Mustang card in play at all times.",
            description: "3 life points"
        ),
        Character(
            name: "Pedro Ramirez",
            lifePoints: 4,
            ability: "During phase 1 of his turn, he may choose to draw the first card from the discard pile or from the deck.",
            description: "4 life points"
        ),
        Character(
            name: "Rose Doolan",
            lifePoints: 4,
            ability: "She is considered to have an Appaloosa card in play at all times; she sees other players at distance decreased by 1.",
            description: "4 life points"
        ),
        Character(
            name: "Sid Ketchum",
            lifePoints: 4,
            ability: "At any time, he may discard 2 cards from his hand to regain one life point.",
            description: "4 life points"
        ),
        Character(
            name: "Slab the Killer",
            lifePoints: 4,
            ability: "Players trying to cancel his BANG! cards need to play 2 Missed! cards.",
            description: "4 life points"
        ),
        Character(
            name: "Suzy Lafayette",
            lifePoints: 4,
            ability: "As soon as she has no cards in her hand, she draws a card from the draw pile.",
            description: "4 life points"
        ),
        Character(
            name: "Vulture Sam",
            lifePoints: 4,
            ability: "Whenever a character is eliminated, Sam takes all the cards that player had in hand and in play.",
            description: "4 life points"
        ),
        Character(
            name: "Willy the Kid",
            lifePoints: 4,
            ability: "He can play any number of BANG! cards during his turn.",
            description: "4 life points"
        )
    ]
    
    // MARK: - Playing Cards Deck
    static func createDeck() -> [Card] {
        var deck: [Card] = []
        
        // BANG! cards (25 total)
        let bangCards = [
            ("A", "♠"), ("2", "♦"), ("3", "♦"), ("4", "♦"), ("5", "♦"), ("6", "♦"), ("7", "♦"), ("8", "♦"), ("9", "♦"), ("10", "♦"), ("J", "♦"), ("Q", "♦"), ("K", "♦"),
            ("2", "♣"), ("3", "♣"), ("4", "♣"), ("5", "♣"), ("6", "♣"), ("7", "♣"), ("8", "♣"), ("9", "♣"),
            ("A", "♥"), ("K", "♥"), ("Q", "♥"), ("J", "♥")
        ]
        
        for (value, suit) in bangCards {
            deck.append(Card(
                type: .bang,
                suit: suit,
                value: value,
                color: .brown,
                description: "Hit another player with 1 damage",
                range: nil
            ))
        }
        
        // MISSED! cards (12 total)
        let missedCards = [
            ("10", "♣"), ("J", "♣"), ("Q", "♣"), ("K", "♣"), ("A", "♣"),
            ("2", "♠"), ("3", "♠"), ("4", "♠"), ("5", "♠"), ("6", "♠"), ("7", "♠"), ("8", "♠")
        ]
        
        for (value, suit) in missedCards {
            deck.append(Card(
                type: .missed,
                suit: suit,
                value: value,
                color: .brown,
                description: "Cancel a BANG! aimed at you",
                range: nil
            ))
        }
        
        // BEER cards (6 total)
        let beerCards = [
            ("6", "♥"), ("7", "♥"), ("8", "♥"), ("9", "♥"), ("10", "♥"), ("J", "♠")
        ]
        
        for (value, suit) in beerCards {
            deck.append(Card(
                type: .beer,
                suit: suit,
                value: value,
                color: .brown,
                description: "Regain 1 life point",
                range: nil
            ))
        }
        
        // WEAPONS
        
        // Schofield (2 range)
        deck.append(Card(type: .schofield, suit: "♣", value: "J", color: .green, description: "Range 2 weapon", range: 2))
        deck.append(Card(type: .schofield, suit: "♣", value: "Q", color: .green, description: "Range 2 weapon", range: 2))
        deck.append(Card(type: .schofield, suit: "♠", value: "K", color: .green, description: "Range 2 weapon", range: 2))
        
        // Remington (3 range)
        deck.append(Card(type: .remington, suit: "♣", value: "K", color: .green, description: "Range 3 weapon", range: 3))
        
        // Rev. Carabine (4 range)
        deck.append(Card(type: .revCarabine, suit: "♣", value: "A", color: .green, description: "Range 4 weapon", range: 4))
        
        // Winchester (5 range)
        deck.append(Card(type: .winchester, suit: "♠", value: "8", color: .green, description: "Range 5 weapon", range: 5))
        
        // Volcanic (1 range, unlimited BANG!)
        deck.append(Card(type: .volcanic, suit: "♠", value: "10", color: .green, description: "Range 1, unlimited BANG! cards", range: 1))
        deck.append(Card(type: .volcanic, suit: "♣", value: "10", color: .green, description: "Range 1, unlimited BANG! cards", range: 1))
        
        // EQUIPMENT
        
        // Barrel
        deck.append(Card(type: .barrel, suit: "♠", value: "Q", color: .blue, description: "Draw! when hit by BANG! - if Heart, counts as Missed!", range: nil))
        deck.append(Card(type: .barrel, suit: "♠", value: "K", color: .blue, description: "Draw! when hit by BANG! - if Heart, counts as Missed!", range: nil))
        
        // Scope
        deck.append(Card(type: .scope, suit: "♠", value: "A", color: .blue, description: "You see all players at distance -1", range: nil))
        
        // Mustang
        deck.append(Card(type: .mustang, suit: "♥", value: "8", color: .blue, description: "Other players see you at distance +1", range: nil))
        deck.append(Card(type: .mustang, suit: "♥", value: "9", color: .blue, description: "Other players see you at distance +1", range: nil))
        
        // SPECIAL CARDS
        
        // Cat Balou
        deck.append(Card(type: .catBalou, suit: "♥", value: "K", color: .brown, description: "Force any player to discard a card", range: nil))
        deck.append(Card(type: .catBalou, suit: "♦", value: "9", color: .brown, description: "Force any player to discard a card", range: nil))
        deck.append(Card(type: .catBalou, suit: "♦", value: "10", color: .brown, description: "Force any player to discard a card", range: nil))
        deck.append(Card(type: .catBalou, suit: "♦", value: "J", color: .brown, description: "Force any player to discard a card", range: nil))
        
        // Panic!
        deck.append(Card(type: .panic, suit: "♥", value: "A", color: .brown, description: "Draw a card from a player at distance 1", range: nil))
        deck.append(Card(type: .panic, suit: "♥", value: "3", color: .brown, description: "Draw a card from a player at distance 1", range: nil))
        deck.append(Card(type: .panic, suit: "♥", value: "4", color: .brown, description: "Draw a card from a player at distance 1", range: nil))
        deck.append(Card(type: .panic, suit: "♦", value: "8", color: .brown, description: "Draw a card from a player at distance 1", range: nil))
        
        // Stagecoach
        deck.append(Card(type: .stagecoach, suit: "♠", value: "9", color: .brown, description: "Draw 2 cards", range: nil))
        deck.append(Card(type: .stagecoach, suit: "♠", value: "9", color: .brown, description: "Draw 2 cards", range: nil))
        
        // Wells Fargo
        deck.append(Card(type: .wellsFargo, suit: "♥", value: "3", color: .brown, description: "Draw 3 cards", range: nil))
        
        // General Store
        deck.append(Card(type: .generalStore, suit: "♣", value: "9", color: .brown, description: "All players draw 1 card from face-up selection", range: nil))
        deck.append(Card(type: .generalStore, suit: "♠", value: "Q", color: .brown, description: "All players draw 1 card from face-up selection", range: nil))
        
        // Saloon
        deck.append(Card(type: .saloon, suit: "♥", value: "5", color: .brown, description: "All players regain 1 life point", range: nil))
        
        // Indians!
        deck.append(Card(type: .indians, suit: "♦", value: "K", color: .brown, description: "All other players discard BANG! or lose 1 life", range: nil))
        deck.append(Card(type: .indians, suit: "♦", value: "A", color: .brown, description: "All other players discard BANG! or lose 1 life", range: nil))
        
        // Duel
        deck.append(Card(type: .duel, suit: "♦", value: "Q", color: .brown, description: "Challenge another player to discard BANG! cards", range: nil))
        deck.append(Card(type: .duel, suit: "♠", value: "J", color: .brown, description: "Challenge another player to discard BANG! cards", range: nil))
        deck.append(Card(type: .duel, suit: "♣", value: "8", color: .brown, description: "Challenge another player to discard BANG! cards", range: nil))
        
        // Gatling
        deck.append(Card(type: .gatling, suit: "♥", value: "10", color: .brown, description: "BANG! all other players", range: nil))
        
        // Dynamite
        deck.append(Card(type: .dynamite, suit: "♥", value: "2", color: .blue, description: "Draw! at turn start - if Spades 2-9, lose 3 life points", range: nil))
        
        // Jail
        deck.append(Card(type: .jail, suit: "♠", value: "4", color: .blue, description: "Draw! at turn start - if not Heart, skip turn", range: nil))
        deck.append(Card(type: .jail, suit: "♠", value: "5", color: .blue, description: "Draw! at turn start - if not Heart, skip turn", range: nil))
        deck.append(Card(type: .jail, suit: "♥", value: "J", color: .blue, description: "Draw! at turn start - if not Heart, skip turn", range: nil))
        
        return deck.shuffled()
    }
    
    // MARK: - Role Distribution
    static func getRoles(for playerCount: Int) -> [Role] {
        switch playerCount {
        case 2:
            return [.sheriff, .outlaw] // Testing mode: Sheriff vs Outlaw
        case 3:
            return [.sheriff, .renegade, .outlaw] // Compact game: Sheriff, Renegade, Outlaw
        case 4:
            return [.sheriff, .renegade, .outlaw, .outlaw]
        case 5:
            return [.sheriff, .renegade, .outlaw, .outlaw, .deputy]
        case 6:
            return [.sheriff, .renegade, .outlaw, .outlaw, .outlaw, .deputy]
        case 7:
            return [.sheriff, .renegade, .outlaw, .outlaw, .outlaw, .deputy, .deputy]
        default:
            return [.sheriff, .renegade, .outlaw, .outlaw] // Default to 4 players
        }
    }
}