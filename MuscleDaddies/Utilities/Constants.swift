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
            case .sports: return 25000
            case .scifi: return 60000
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
        case runningBack
        case linebacker
        case golfTrickShot
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
            case .runningBack: return "Running Back"
            case .linebacker: return "Linebacker"
            case .golfTrickShot: return "Golf Trick Shot"
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

        var theme: ClassTheme {
            switch self {
            case .warrior, .scout, .knight, .wizard, .thief, .berserker, .swordmaster, .elf:
                return .fantasy
            case .shortstop, .quarterback, .runningBack, .linebacker, .golfTrickShot, .powerForward, .goalie, .striker:
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
            case .powerForward: return "PowerForward"
            case .goalie: return "Goalie"
            case .striker: return "Striker"
            case .golfTrickShot: return "Golfer"
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
            case .shortstop: return ClassWeights(strength: 0.15, speed: 0.35, endurance: 0.30, intelligence: 0.20)
            case .quarterback: return ClassWeights(strength: 0.30, speed: 0.20, endurance: 0.15, intelligence: 0.35)
            case .runningBack: return ClassWeights(strength: 0.30, speed: 0.35, endurance: 0.20, intelligence: 0.15)
            case .linebacker: return ClassWeights(strength: 0.35, speed: 0.15, endurance: 0.30, intelligence: 0.20)
            case .golfTrickShot: return ClassWeights(strength: 0.15, speed: 0.20, endurance: 0.30, intelligence: 0.35)
            case .powerForward: return ClassWeights(strength: 0.35, speed: 0.15, endurance: 0.30, intelligence: 0.20)
            case .goalie: return ClassWeights(strength: 0.20, speed: 0.15, endurance: 0.30, intelligence: 0.35)
            case .striker: return ClassWeights(strength: 0.20, speed: 0.35, endurance: 0.30, intelligence: 0.15)
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
        case firstBlood = "first_blood"
        case ironWill = "iron_will"
        case renaissanceMan = "renaissance_man"
        case beastMode = "beast_mode"
        case zenMaster = "zen_master"
        case accountabilityPartner = "accountability_partner"
        case daddyOfTheMonth = "daddy_of_the_month"

        var displayName: String {
            switch self {
            case .firstBlood: return "First Blood"
            case .ironWill: return "Iron Will"
            case .renaissanceMan: return "Renaissance Man"
            case .beastMode: return "Beast Mode"
            case .zenMaster: return "Zen Master"
            case .accountabilityPartner: return "Accountability Partner"
            case .daddyOfTheMonth: return "Daddy of the Month"
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
            }
        }
    }
}
