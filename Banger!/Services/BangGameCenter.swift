//
//  BangGameCenter.swift
//  Banger!
//
//  Created by Hannes Nagel on 6/23/25.
//

import Foundation
import GameKit

extension BangGameManager {
    
    // MARK: - Achievements
    enum BangAchievement: String, CaseIterable {
        case firstWin = "com.banger.first_win"
        case playTenGames = "com.banger.play_ten_games"
        case winAsSheriff = "com.banger.win_as_sheriff"
        case winAsOutlaw = "com.banger.win_as_outlaw"
        case winAsDeputy = "com.banger.win_as_deputy"
        case winAsRenegade = "com.banger.win_as_renegade"
        case surviveFiveRounds = "com.banger.survive_five_rounds"
        case playAllCharacters = "com.banger.play_all_characters"
        case eliminateThreePlayers = "com.banger.eliminate_three_players"
        case winWithoutTakingDamage = "com.banger.win_without_damage"
        
        var title: String {
            switch self {
            case .firstWin: return "First Victory"
            case .playTenGames: return "Regular Player"
            case .winAsSheriff: return "Law and Order"
            case .winAsOutlaw: return "Outlaw Victory"
            case .winAsDeputy: return "Loyal Deputy"
            case .winAsRenegade: return "Lone Wolf"
            case .surviveFiveRounds: return "Survivor"
            case .playAllCharacters: return "Master of Disguise"
            case .eliminateThreePlayers: return "Gunslinger"
            case .winWithoutTakingDamage: return "Untouchable"
            }
        }
        
        var description: String {
            switch self {
            case .firstWin: return "Win your first game of Bang!"
            case .playTenGames: return "Play 10 games of Bang!"
            case .winAsSheriff: return "Win a game as the Sheriff"
            case .winAsOutlaw: return "Win a game as an Outlaw"
            case .winAsDeputy: return "Win a game as a Deputy"
            case .winAsRenegade: return "Win a game as the Renegade"
            case .surviveFiveRounds: return "Survive 5 rounds in a single game"
            case .playAllCharacters: return "Play as all 16 different characters"
            case .eliminateThreePlayers: return "Eliminate 3 players in a single game"
            case .winWithoutTakingDamage: return "Win a game without taking any damage"
            }
        }
    }
    
    // MARK: - Leaderboards
    enum BangLeaderboard: String, CaseIterable {
        case gamesWon = "com.banger.games_won"
        case gamesPlayed = "com.banger.games_played"
        case playersEliminated = "com.banger.players_eliminated"
        case sheriffWins = "com.banger.sheriff_wins"
        case outlawWins = "com.banger.outlaw_wins"
        case deputyWins = "com.banger.deputy_wins"
        case renegadeWins = "com.banger.renegade_wins"
        
        var title: String {
            switch self {
            case .gamesWon: return "Games Won"
            case .gamesPlayed: return "Games Played"
            case .playersEliminated: return "Players Eliminated"
            case .sheriffWins: return "Sheriff Victories"
            case .outlawWins: return "Outlaw Victories"
            case .deputyWins: return "Deputy Victories"
            case .renegadeWins: return "Renegade Victories"
            }
        }
    }
    
    // MARK: - Achievement Tracking
    func reportGameWin(role: Role, character: Character, roundsSurvived: Int, playersEliminated: Int, damageTaken: Int) {
        // First win achievement
        reportAchievementProgress(.firstWin, percentComplete: 100.0)
        
        // Role-specific wins
        switch role {
        case .sheriff:
            reportAchievementProgress(.winAsSheriff, percentComplete: 100.0)
            reportLeaderboardScore(.sheriffWins, score: 1)
        case .outlaw:
            reportAchievementProgress(.winAsOutlaw, percentComplete: 100.0)
            reportLeaderboardScore(.outlawWins, score: 1)
        case .deputy:
            reportAchievementProgress(.winAsDeputy, percentComplete: 100.0)
            reportLeaderboardScore(.deputyWins, score: 1)
        case .renegade:
            reportAchievementProgress(.winAsRenegade, percentComplete: 100.0)
            reportLeaderboardScore(.renegadeWins, score: 1)
        }
        
        // Survival achievement
        if roundsSurvived >= 5 {
            reportAchievementProgress(.surviveFiveRounds, percentComplete: 100.0)
        }
        
        // Elimination achievement
        if playersEliminated >= 3 {
            reportAchievementProgress(.eliminateThreePlayers, percentComplete: 100.0)
        }
        
        // No damage achievement
        if damageTaken == 0 {
            reportAchievementProgress(.winWithoutTakingDamage, percentComplete: 100.0)
        }
        
        // Leaderboard scores
        reportLeaderboardScore(.gamesWon, score: 1)
        reportLeaderboardScore(.playersEliminated, score: playersEliminated)
        
        // Track character usage
        trackCharacterUsed(character)
    }
    
    func reportGamePlayed() {
        // Increment games played
        reportAchievementProgress(.playTenGames, percentComplete: 10.0) // 10% per game
        reportLeaderboardScore(.gamesPlayed, score: 1)
    }
    
    private func reportAchievementProgress(_ achievement: BangAchievement, percentComplete: Double) {
        GKAchievement.loadAchievements { existingAchievements, error in
            if let error = error {
                print("Error loading achievements: \(error.localizedDescription)")
                return
            }
            
            var achievementObject = existingAchievements?.first { $0.identifier == achievement.rawValue }
            
            if achievementObject == nil {
                achievementObject = GKAchievement(identifier: achievement.rawValue)
            }
            
            let newProgress = min(100.0, (achievementObject?.percentComplete ?? 0.0) + percentComplete)
            achievementObject?.percentComplete = newProgress
            
            if let achievementToReport = achievementObject {
                GKAchievement.report([achievementToReport]) { error in
                    if let error = error {
                        print("Error reporting achievement: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func reportLeaderboardScore(_ leaderboard: BangLeaderboard, score: Int) {
        GKLeaderboard.submitScore(
            score,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [leaderboard.rawValue]
        ) { error in
            if let error = error {
                print("Error submitting score: \(error.localizedDescription)")
            }
        }
    }
    
    private func trackCharacterUsed(_ character: Character) {
        // Store character usage in UserDefaults
        let key = "character_used_\(character.name.replacingOccurrences(of: " ", with: "_"))"
        UserDefaults.standard.set(true, forKey: key)
        
        // Check if all characters have been used
        let allCharactersUsed = BangDeck.characters.allSatisfy { character in
            let characterKey = "character_used_\(character.name.replacingOccurrences(of: " ", with: "_"))"
            return UserDefaults.standard.bool(forKey: characterKey)
        }
        
        if allCharactersUsed {
            reportAchievementProgress(.playAllCharacters, percentComplete: 100.0)
        }
    }
    
    // MARK: - Game Center UI
    func showAchievements() {
        // Use GKAccessPoint for modern iOS versions
        GKAccessPoint.shared.trigger(state: .achievements) { }
    }
    
    func showLeaderboards() {
        // Use GKAccessPoint for modern iOS versions
        GKAccessPoint.shared.trigger(state: .leaderboards) { }
    }
    
    func showGameCenter() {
        // Use GKAccessPoint for modern iOS versions
        GKAccessPoint.shared.trigger(state: .default) { }
    }
    
    // MARK: - Friend Invitations
    func createInviteRequest() -> GKMatchRequest {
        let request = GKMatchRequest()
        request.minPlayers = 4
        request.maxPlayers = 7
        return request
    }
    
    // Voice chat functionality has been removed as it's deprecated in iOS 18
}

// MARK: - Game Stats Tracking
class BangGameStats {
    static let shared = BangGameStats()
    
    private init() {}
    
    var gamesPlayed: Int {
        get { UserDefaults.standard.integer(forKey: "bang_games_played") }
        set { UserDefaults.standard.set(newValue, forKey: "bang_games_played") }
    }
    
    var gamesWon: Int {
        get { UserDefaults.standard.integer(forKey: "bang_games_won") }
        set { UserDefaults.standard.set(newValue, forKey: "bang_games_won") }
    }
    
    var playersEliminated: Int {
        get { UserDefaults.standard.integer(forKey: "bang_players_eliminated") }
        set { UserDefaults.standard.set(newValue, forKey: "bang_players_eliminated") }
    }
    
    var favoriteCharacter: String? {
        get { UserDefaults.standard.string(forKey: "bang_favorite_character") }
        set { UserDefaults.standard.set(newValue, forKey: "bang_favorite_character") }
    }
    
    func incrementGamesPlayed() {
        gamesPlayed += 1
    }
    
    func incrementGamesWon() {
        gamesWon += 1
    }
    
    func incrementPlayersEliminated(by count: Int) {
        playersEliminated += count
    }
    
    func updateFavoriteCharacter(_ character: String) {
        let key = "character_play_count_\(character)"
        let currentCount = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(currentCount + 1, forKey: key)
        
        // Find most played character
        var maxCount = 0
        var mostPlayedCharacter = ""
        
        for character in BangDeck.characters {
            let characterKey = "character_play_count_\(character.name)"
            let count = UserDefaults.standard.integer(forKey: characterKey)
            if count > maxCount {
                maxCount = count
                mostPlayedCharacter = character.name
            }
        }
        
        favoriteCharacter = mostPlayedCharacter
    }
    
    var winRate: Double {
        guard gamesPlayed > 0 else { return 0.0 }
        return Double(gamesWon) / Double(gamesPlayed)
    }
}