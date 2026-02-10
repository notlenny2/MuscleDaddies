import Foundation

enum Constants {
    enum Firestore {
        static let users = "users"
        static let groups = "groups"
        static let workouts = "workouts"
        static let feed = "feed"
        static let challenges = "challenges"
        static let achievements = "achievements"
        static let recovery = "recovery"
        static let beltChallenges = "beltChallenges"
        static let belts = "belts"
    }

    enum WorkoutType: String, CaseIterable, Codable {
        case strength = "strength"
        case running = "running"
        case cycling = "cycling"
        case yoga = "yoga"
        case hiit = "hiit"
        case swimming = "swimming"
        case stretching = "stretching"
        case meditation = "meditation"
        case walking = "walking"
        case other = "other"

        var displayName: String {
            switch self {
            case .strength: return "Strength Training"
            case .running: return "Running"
            case .cycling: return "Cycling"
            case .yoga: return "Yoga"
            case .hiit: return "HIIT"
            case .swimming: return "Swimming"
            case .stretching: return "Stretching"
            case .meditation: return "Meditation"
            case .walking: return "Walking"
            case .other: return "Other"
            }
        }

        var icon: String {
            switch self {
            case .strength: return "dumbbell.fill"
            case .running: return "figure.run"
            case .cycling: return "bicycle"
            case .yoga: return "figure.yoga"
            case .hiit: return "bolt.heart.fill"
            case .swimming: return "figure.pool.swim"
            case .stretching: return "figure.flexibility"
            case .meditation: return "brain.head.profile"
            case .walking: return "figure.walk"
            case .other: return "sportscourt.fill"
            }
        }

        var statCategory: StatCategory {
            switch self {
            case .strength: return .strength
            case .running, .cycling, .hiit: return .speed
            case .swimming, .walking: return .endurance
            case .yoga, .stretching, .meditation: return .intelligence
            case .other: return .endurance
            }
        }
    }

    enum StatCategory: String, CaseIterable {
        case strength, speed, endurance, intelligence

        var color: String {
            switch self {
            case .strength: return "red"
            case .speed: return "blue"
            case .endurance: return "green"
            case .intelligence: return "purple"
            }
        }
    }

    enum PriorityStat: String, CaseIterable, Codable {
        case strength = "strength"
        case speed = "speed"
        case endurance = "endurance"
        case intelligence = "intelligence"

        var displayName: String {
            switch self {
            case .strength: return "Strength"
            case .speed: return "Speed"
            case .endurance: return "Endurance"
            case .intelligence: return "Mobility"
            }
        }
    }

    enum UnitsSystem: String, CaseIterable, Codable {
        case imperial = "imperial"
        case metric = "metric"

        var displayName: String {
            switch self {
            case .imperial: return "Imperial"
            case .metric: return "Metric"
            }
        }
    }

    enum HeightCategory: String, CaseIterable, Codable {
        case medium = "medium"
        case tall = "tall"
        case veryTall = "very_tall"
        case basketball = "basketball"

        var displayName: String {
            switch self {
            case .medium: return "Medium"
            case .tall: return "Tall"
            case .veryTall: return "Very Tall"
            case .basketball: return "Basketball Player"
            }
        }
    }

    enum BodyType: String, CaseIterable, Codable {
        case slender = "slender"
        case medium = "medium"
        case stocky = "stocky"
        case yuge = "yuge"

        var displayName: String {
            switch self {
            case .slender: return "Slender"
            case .medium: return "Medium"
            case .stocky: return "Stocky"
            case .yuge: return "Yuge"
            }
        }
    }

    enum Reaction: String, CaseIterable {
        case fire = "🔥"
        case flex = "💪"
        case clap = "👏"
        case skull = "💀"
    }

    enum CardTheme: String, CaseIterable, Codable {
        case modern = "modern"
        case pixel = "pixel"
        case trading = "trading"

        var displayName: String {
            switch self {
            case .modern: return "Modern"
            case .pixel: return "Pixel Art"
            case .trading: return "Trading Card"
            }
        }
    }

    enum ClassTheme: String, CaseIterable, Codable {
        case fantasy = "fantasy"
        case sports = "sports"
        case scifi = "scifi"

        var displayName: String {
            switch self {
            case .fantasy: return "Fantasy"
            case .sports: return "Sports"
            case .scifi: return "Sci‑Fi"
            }
        }

        var cardTheme: CardTheme {
            switch self {
            case .fantasy: return .pixel
            case .sports: return .trading
            case .scifi: return .modern
            }
        }

        var unlockXP: Double {
            switch self {
            case .fantasy: return 0
            case .sports: return 0
            case .scifi: return 60000
            }
        }

        var unlockLevel: Int? {
            switch self {
            case .fantasy: return nil
            case .sports: return 5
            case .scifi: return 15
            }
        }
    }

    struct ClassWeights {
        let strength: Double
        let speed: Double
        let endurance: Double
        let intelligence: Double
    }

    enum MuscleClass: String, CaseIterable, Codable {
        // Fantasy
        case warrior
        case scout
        case knight
        case wizard
        case thief
        case berserker
        case swordmaster
        case elf
        // Sports
        case shortstop
        case quarterback
        case racecarDriver
        case enforcer
        case golfer
        case powerForward
        case goalie
        case striker
        // Sci‑Fi
        case starfighterPilot
        case starfleetCaptain
        case borgJuggernaut
        case xenomorph
        case androidMedic
        case warpEngineer
        case zeroGRanger
        case voidMonk

        var displayName: String {
            switch self {
            case .warrior: return "Warrior"
            case .scout: return "Scout"
            case .knight: return "Knight"
            case .wizard: return "Wizard"
            case .thief: return "Thief"
            case .berserker: return "Berserker"
            case .swordmaster: return "Swordmaster"
            case .elf: return "Elf"
            case .shortstop: return "Shortstop"
            case .quarterback: return "Quarterback"
            case .racecarDriver: return "Racecar Driver"
            case .enforcer: return "Enforcer"
            case .golfer: return "Golfer"
            case .powerForward: return "Power Forward"
            case .goalie: return "Goalie"
            case .striker: return "Striker"
            case .starfighterPilot: return "Starfighter Pilot"
            case .starfleetCaptain: return "Starfleet Captain"
            case .borgJuggernaut: return "Borg Juggernaut"
            case .xenomorph: return "Xenomorph"
            case .androidMedic: return "Android Medic"
            case .warpEngineer: return "Warp Engineer"
            case .zeroGRanger: return "Zero‑G Ranger"
            case .voidMonk: return "Void Monk"
            }
        }

        var flavorDescription: String {
            switch self {
            // Fantasy
            case .warrior:
                return "Frontline bruiser forged for strength and grit."
            case .scout:
                return "Fast mover who thrives on speed and steady endurance."
            case .knight:
                return "A stalwart tank with endurance to outlast any fight."
            case .wizard:
                return "Arcane tactician—mobility and endurance over raw force."
            case .thief:
                return "Quick and cunning, striking with speed and strength."
            case .berserker:
                return "Rage-fueled powerhouse built for strength and stamina."
            case .swordmaster:
                return "Precision fighter—speed and strength in perfect balance."
            case .elf:
                return "Agile and mindful, favoring mobility and endurance."
            // Sports
            case .shortstop:
                return "Lightning reflexes and sharp reads rule the field."
            case .quarterback:
                return "Commanding leader—strength and mobility set the pace."
            case .racecarDriver:
                return "Speed demon with endurance to hold the line."
            case .enforcer:
                return "Hockey bruiser—strength first, endurance to finish."
            case .golfer:
                return "Calm precision—mobility and endurance win the day."
            case .powerForward:
                return "Explosive force—strength with a quick step."
            case .goalie:
                return "Reactive wall—strength and mobility under pressure."
            case .striker:
                return "Aggressive finisher—speed and strength in attack."
            // Sci‑Fi
            case .starfighterPilot:
                return "Ace pilot—speed with endurance for long runs."
            case .starfleetCaptain:
                return "Strategic leader—mobility and endurance in command."
            case .borgJuggernaut:
                return "Relentless unit—strength and endurance above all."
            case .xenomorph:
                return "Predator class—speed and strength in lethal bursts."
            case .androidMedic:
                return "Precision support—mobility and endurance to sustain."
            case .warpEngineer:
                return "Systems specialist—mobility with solid strength."
            case .zeroGRanger:
                return "Zero‑G scout—speed and endurance in the void."
            case .voidMonk:
                return "Focused and resilient—mobility and endurance aligned."
            }
        }

        var theme: ClassTheme {
            switch self {
            case .warrior, .scout, .knight, .wizard, .thief, .berserker, .swordmaster, .elf:
                return .fantasy
            case .shortstop, .quarterback, .racecarDriver, .enforcer, .golfer, .powerForward, .goalie, .striker:
                return .sports
            case .starfighterPilot, .starfleetCaptain, .borgJuggernaut, .xenomorph, .androidMedic, .warpEngineer, .zeroGRanger, .voidMonk:
                return .scifi
            }
        }

        var fantasyArtAsset: String? {
            switch self {
            case .warrior: return "Warrior"
            case .wizard: return "Wizard"
            case .berserker: return "Berserker"
            case .knight: return "Knight"
            case .swordmaster: return "Swordmaster"
            case .elf: return "Elf"
            case .scout: return "Scout"
            case .thief: return "Thief"
            default: return nil
            }
        }

        var sportsArtAsset: String? {
            switch self {
            case .shortstop: return "Shortstop"
            case .quarterback: return "Quarterback"
            case .racecarDriver: return "Racecar Driver"
            case .enforcer: return "Enforcer"
            case .powerForward: return "PowerForward"
            case .goalie: return "Goalie"
            case .striker: return "Striker"
            case .golfer: return "Golfer"
            default: return nil
            }
        }

        var classArtAsset: String? {
            fantasyArtAsset ?? sportsArtAsset
        }

        var weights: ClassWeights {
            switch self {
            // Fantasy
            case .warrior: return ClassWeights(strength: 0.35, speed: 0.15, endurance: 0.30, intelligence: 0.20)
            case .scout: return ClassWeights(strength: 0.15, speed: 0.35, endurance: 0.30, intelligence: 0.20)
            case .knight: return ClassWeights(strength: 0.30, speed: 0.15, endurance: 0.35, intelligence: 0.20)
            case .wizard: return ClassWeights(strength: 0.20, speed: 0.15, endurance: 0.30, intelligence: 0.35)
            case .thief: return ClassWeights(strength: 0.30, speed: 0.35, endurance: 0.20, intelligence: 0.15)
            case .berserker: return ClassWeights(strength: 0.35, speed: 0.15, endurance: 0.30, intelligence: 0.20)
            case .swordmaster: return ClassWeights(strength: 0.35, speed: 0.30, endurance: 0.20, intelligence: 0.15)
            case .elf: return ClassWeights(strength: 0.15, speed: 0.20, endurance: 0.30, intelligence: 0.35)
            // Sports
            case .shortstop: return ClassWeights(strength: 0.10, speed: 0.40, endurance: 0.20, intelligence: 0.30)
            case .quarterback: return ClassWeights(strength: 0.35, speed: 0.20, endurance: 0.15, intelligence: 0.30)
            case .racecarDriver: return ClassWeights(strength: 0.15, speed: 0.40, endurance: 0.30, intelligence: 0.15)
            case .enforcer: return ClassWeights(strength: 0.40, speed: 0.15, endurance: 0.30, intelligence: 0.15)
            case .golfer: return ClassWeights(strength: 0.20, speed: 0.15, endurance: 0.30, intelligence: 0.35)
            case .powerForward: return ClassWeights(strength: 0.40, speed: 0.30, endurance: 0.20, intelligence: 0.10)
            case .goalie: return ClassWeights(strength: 0.35, speed: 0.15, endurance: 0.20, intelligence: 0.30)
            case .striker: return ClassWeights(strength: 0.30, speed: 0.40, endurance: 0.20, intelligence: 0.10)
            // Sci‑Fi
            case .starfighterPilot: return ClassWeights(strength: 0.15, speed: 0.35, endurance: 0.30, intelligence: 0.20)
            case .starfleetCaptain: return ClassWeights(strength: 0.20, speed: 0.15, endurance: 0.30, intelligence: 0.35)
            case .borgJuggernaut: return ClassWeights(strength: 0.35, speed: 0.10, endurance: 0.35, intelligence: 0.20)
            case .xenomorph: return ClassWeights(strength: 0.30, speed: 0.35, endurance: 0.20, intelligence: 0.15)
            case .androidMedic: return ClassWeights(strength: 0.15, speed: 0.20, endurance: 0.30, intelligence: 0.35)
            case .warpEngineer: return ClassWeights(strength: 0.30, speed: 0.20, endurance: 0.15, intelligence: 0.35)
            case .zeroGRanger: return ClassWeights(strength: 0.20, speed: 0.35, endurance: 0.30, intelligence: 0.15)
            case .voidMonk: return ClassWeights(strength: 0.20, speed: 0.15, endurance: 0.30, intelligence: 0.35)
            }
        }
    }

    enum AchievementType: String, CaseIterable, Codable {
        // Original achievements
        case firstBlood = "first_blood"
        case ironWill = "iron_will"
        case renaissanceMan = "renaissance_man"
        case beastMode = "beast_mode"
        case zenMaster = "zen_master"
        case accountabilityPartner = "accountability_partner"
        case daddyOfTheMonth = "daddy_of_the_month"

        // Class & Theme Exploration
        case identityCrisis = "identity_crisis"
        case tripleThreat = "triple_threat"
        case sportsLegend = "sports_legend"
        case fantasyHero = "fantasy_hero"
        case sciFiCommander = "scifi_commander"
        case loyalToTheEnd = "loyal_to_the_end"

        // Consistency & Dedication
        case gettingSerious = "getting_serious"
        case unstoppable = "unstoppable"
        case legendaryDiscipline = "legendary_discipline"

        // Workout Mastery
        case masterOfAll = "master_of_all"
        case distanceDemon = "distance_demon"
        case timeLord = "time_lord"
        case powerHouse = "power_house"
        case cardioKing = "cardio_king"

        // Social Engagement
        case socialButterfly = "social_butterfly"
        case superMotivator = "super_motivator"
        case beltMaster = "belt_master"
        case challengeChampion = "challenge_champion"
        case squadGoals = "squad_goals"

        // App Engagement
        case earlyRiser = "early_riser"
        case nightWarrior = "night_warrior"
        case consistentUser = "consistent_user"

        var displayName: String {
            switch self {
            case .firstBlood: return "First Blood"
            case .ironWill: return "Iron Will"
            case .renaissanceMan: return "Renaissance Man"
            case .beastMode: return "Beast Mode"
            case .zenMaster: return "Zen Master"
            case .accountabilityPartner: return "Accountability Partner"
            case .daddyOfTheMonth: return "Daddy of the Month"
            case .identityCrisis: return "Identity Crisis"
            case .tripleThreat: return "Triple Threat"
            case .sportsLegend: return "Sports Legend"
            case .fantasyHero: return "Fantasy Hero"
            case .sciFiCommander: return "Sci-Fi Commander"
            case .loyalToTheEnd: return "Loyal to the End"
            case .gettingSerious: return "Getting Serious"
            case .unstoppable: return "Unstoppable"
            case .legendaryDiscipline: return "Legendary Discipline"
            case .masterOfAll: return "Master of All"
            case .distanceDemon: return "Distance Demon"
            case .timeLord: return "Time Lord"
            case .powerHouse: return "Power House"
            case .cardioKing: return "Cardio King"
            case .socialButterfly: return "Social Butterfly"
            case .superMotivator: return "Super Motivator"
            case .beltMaster: return "Belt Master"
            case .challengeChampion: return "Challenge Champion"
            case .squadGoals: return "Squad Goals"
            case .earlyRiser: return "Early Riser"
            case .nightWarrior: return "Night Warrior"
            case .consistentUser: return "Consistent User"
            }
        }

        var description: String {
            switch self {
            case .firstBlood: return "Log your first workout"
            case .ironWill: return "7-day workout streak"
            case .renaissanceMan: return "5 different workout types in a week"
            case .beastMode: return "Log 20 workouts in a month"
            case .zenMaster: return "10 mindfulness sessions"
            case .accountabilityPartner: return "Poke 10 friends"
            case .daddyOfTheMonth: return "Highest overall level at month end"
            case .identityCrisis: return "Change your class 3 times"
            case .tripleThreat: return "Try all 3 class themes"
            case .sportsLegend: return "Use a Sports class for 30 days"
            case .fantasyHero: return "Use a Fantasy class for 30 days"
            case .sciFiCommander: return "Use a Sci-Fi class for 30 days"
            case .loyalToTheEnd: return "Keep same class for 60 days"
            case .gettingSerious: return "14-day workout streak"
            case .unstoppable: return "30-day workout streak"
            case .legendaryDiscipline: return "60-day workout streak"
            case .masterOfAll: return "Log all 10 workout types"
            case .distanceDemon: return "Log 100 total miles"
            case .timeLord: return "Log 100 total hours of workouts"
            case .powerHouse: return "Log 50 strength workouts"
            case .cardioKing: return "Log 50 cardio workouts"
            case .socialButterfly: return "React to 50 feed items"
            case .superMotivator: return "Poke 25 friends"
            case .beltMaster: return "Win 5 belt challenges"
            case .challengeChampion: return "Complete 10 group challenges"
            case .squadGoals: return "Be in a group with 8+ members"
            case .earlyRiser: return "Log 10 workouts before 8am"
            case .nightWarrior: return "Log 10 workouts after 9pm"
            case .consistentUser: return "Open app 30 days in a row"
            }
        }

        var icon: String {
            switch self {
            case .firstBlood: return "drop.fill"
            case .ironWill: return "flame.fill"
            case .renaissanceMan: return "paintpalette.fill"
            case .beastMode: return "bolt.fill"
            case .zenMaster: return "leaf.fill"
            case .accountabilityPartner: return "hand.point.right.fill"
            case .daddyOfTheMonth: return "crown.fill"
            case .identityCrisis: return "person.crop.circle.badge.questionmark"
            case .tripleThreat: return "star.circle.fill"
            case .sportsLegend: return "sportscourt.fill"
            case .fantasyHero: return "shield.fill"
            case .sciFiCommander: return "sparkles"
            case .loyalToTheEnd: return "heart.fill"
            case .gettingSerious: return "flame.circle.fill"
            case .unstoppable: return "bolt.shield.fill"
            case .legendaryDiscipline: return "trophy.fill"
            case .masterOfAll: return "star.fill"
            case .distanceDemon: return "figure.run.circle.fill"
            case .timeLord: return "clock.badge.checkmark.fill"
            case .powerHouse: return "dumbbell.fill"
            case .cardioKing: return "heart.circle.fill"
            case .socialButterfly: return "bubble.left.and.bubble.right.fill"
            case .superMotivator: return "hand.thumbsup.fill"
            case .beltMaster: return "medal.fill"
            case .challengeChampion: return "rosette"
            case .squadGoals: return "person.3.fill"
            case .earlyRiser: return "sunrise.fill"
            case .nightWarrior: return "moon.stars.fill"
            case .consistentUser: return "calendar.badge.clock"
            }
        }

        var xpBonus: Double {
            switch self {
            // Original - Basic (100-200 XP)
            case .firstBlood: return 100
            case .ironWill: return 250
            case .renaissanceMan: return 200
            case .beastMode: return 400
            case .zenMaster: return 200
            case .accountabilityPartner: return 150
            case .daddyOfTheMonth: return 1000

            // Class & Theme - Medium (150-400 XP)
            case .identityCrisis: return 150
            case .tripleThreat: return 250
            case .sportsLegend: return 300
            case .fantasyHero: return 300
            case .sciFiCommander: return 300
            case .loyalToTheEnd: return 400

            // Consistency - Hard to Epic (300-1500 XP)
            case .gettingSerious: return 300
            case .unstoppable: return 750
            case .legendaryDiscipline: return 1500

            // Workout Mastery - Medium to Hard (350-500 XP)
            case .masterOfAll: return 400
            case .distanceDemon: return 500
            case .timeLord: return 500
            case .powerHouse: return 350
            case .cardioKing: return 350

            // Social - Medium (200-600 XP)
            case .socialButterfly: return 200
            case .superMotivator: return 300
            case .beltMaster: return 600
            case .challengeChampion: return 500
            case .squadGoals: return 200

            // App Engagement - Medium (250-400 XP)
            case .earlyRiser: return 250
            case .nightWarrior: return 250
            case .consistentUser: return 400
            }
        }
    }
}
