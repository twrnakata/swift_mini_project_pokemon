enum BattleError: Error{
    case noOwner
    case pokemonFainted
}


struct Skill{
    private var name: [String] = []
    static let maxSkill = 4

    var totalSkill: Int{
        get{
            return self.name.count
        }
    }

    enum StarterSkill{
        case fire, water, grass
        
        func getSkill() -> [String]{
            switch self{
                case .fire:
                    return ["Bite", "Ember"]
                case .water:
                    return ["Tail Whip", "Water Gun"]
                case .grass:
                    return ["Tackle", "Vine Whip"]
            }
        }
    }

    init(name: String){
        self.name.append(name)
    }

    init(_ setSkill: StarterSkill){
        self.name = setSkill.getSkill()
    }

    func allSkills() -> [String]{
        return self.name
    }

    mutating func newSkill(_ name: String){
        if (self.name.count == Skill.maxSkill){
            self.name[0] = name
        }else{
            self.name.append(name)
        }
    }

    subscript(index: Int) -> String{
        get{
            guard !(name.isEmpty) else{ return "[no skill]" }
            return name[index]
        }
    }
}

// ทำเป็น Property Wrappers เพื่อเช็คเงื่อนไขอยู่เสมอว่า ค่าที่รับเข้ามาจะไม่เกินเงื่อนไขที่กำหนด
@propertyWrapper
struct Level{
    private var level: Int = 1
    var wrappedValue: Int{
        get{ return self.level }
        set{
            if (newValue > 99){
                self.level = 99
            }else if(newValue < 1){
                self.level = 1
            }else{
                self.level = newValue
            }
        }
    }
}


@propertyWrapper
struct Health{
    static let maxHP = 10
    private var hp: Int = maxHP
    var wrappedValue: Int{
        get{ return self.hp }
        set{
            if (newValue > Health.maxHP){
                self.hp = 10
            }else if(newValue < 0){
                self.hp = 0
            }else{
                self.hp = newValue
            }
        }
    }

}

struct Trainer{
    var name: String
    var pokemon: Pokemon

    init(name: String, pokemon: Pokemon){
        self.name = name
        self.pokemon = pokemon
    }

    init(trainer: Trainer){
        self.name = trainer.name
        self.pokemon = trainer.pokemon
    }
    
}

class Monster{
    var name: String

    init(){
        self.name = "[Unset]"
    }

    init(name: String){
        self.name = name
    }

    deinit{
        print("Monster Name \(self.name) has gone")
    }
}

class Pokemon: Monster{
    var owner: Trainer?
    private(set) var skill: Skill
    private(set) var element: Element
    @Level var level: Int {
        // อัพเวลเพิ่มสกิล
        didSet{
            print("\(self.name) level up from \(oldValue) to \(self.level)")
        }
    }
    @Health var hp{
        willSet(newHP){
            if (newHP < self.hp){
                print("\(self.name) has take \(self.hp - newHP) damage")
            }
                // restore hp
        }
        didSet{
            // ถ้าเลือดปัจจุบันน้อยกว่า เลือดเดิม  ===> เลือดลด
            if(self.hp < oldValue){
                if (self.hp) == 0 {
                    print("\(self.name) HP remain: \(self.hp)")
                    print("\(self.name) fainted")
                }else{
                    print("\(self.name) HP remain: \(self.hp)")
                }
            }else{
            // ถ้าเลือดปัจจุบันมากกว่าเลือดเดิม ===> เลือดเพิ่ม
                // restore hp
            }
        }
    }


    private override init(){
        // phase 1
        // กำหนดค่าให้ตัวเองให้ครบก่อน
        element = Element.fire
        skill = Skill(.fire)

        // phase 2
        super.init()
        
    }

    override convenience init(name: String){
        // phase 1
        self.init()

        
        // phase 2
        let name = name.lowercased()
        switch name{
            case "zenigame":
                self.name = name
                self.element.setElement(to: name)
                self.skill = Skill(.water)
            case "fushigidane":
                self.name = name
                self.element.setElement(to: name)
                self.skill = Skill(.grass)
            default:
                self.name = "hitokage"
                self.element.setElement(to: name)
        }
    }
    convenience init(name: String, owner: Trainer){
        self.init(name: name)
        self.owner = owner
    }

    enum Element: String{
        case fire, water, grass
        mutating func setElement(to value: String){
            switch value.lowercased(){
                case "hitokage":
                    self = .fire
                case "zenigame":
                    self = .water
                case "fushigidane":
                    self = .grass
                default:
                    break
            }
        }

        func isElementWin(against: Element) -> Bool{
            switch self{
                case .fire where against == .grass:
                    return true
                case .grass where against == .water:
                    return true
                case .water where against == .fire:
                    return true
                default:
                    return false
            }
        }
    }

    func lvlUp(){
        self.level += 1
    }

    func restoreHealth(){
        self.hp = Health.maxHP
    }

    deinit{
        StarterPack.pokedex.append(Pokemon(name: self.name))
    }

}

class StarterPack {
    static var pokedex: [Pokemon] = [
        Pokemon(name: "Hitokage"), Pokemon(name: "Zenigame"), Pokemon(name: "Fushigidane")
        ]

    static func takePokemon(name target: String) -> Pokemon?{
        for (number, pokemon) in StarterPack.pokedex.enumerated() {
            if (pokemon.name) == target.lowercased() {
                print(pokemon.name, "has pick from pokedex")
                pokedex.remove(at: number)
                return pokemon
            }
        }

        return nil
    }
    
}


func battle(player1:  Trainer, player2:  Trainer) throws { 


    guard player1.pokemon.owner != nil, player2.pokemon.owner != nil else { throw BattleError.noOwner }
    guard player1.pokemon.hp > 0, player2.pokemon.hp > 0 else { throw BattleError.pokemonFainted  }

    var flag = true
    var randomSkill = 0
    var round = 1

    // เริ่มเกมโดย สุ่มค่าเพื่อเลือกผู้เล่นที่จะได้โจมตี
    // จากนั้นทำการสุ่มเลขสกิลเพื่อใช้โจมตี
    // ความเสียหายที่อีกฝ่ายจะได้รับจะถูกนำไปคิดรวมกับธาตุของโปเกม่อน
    // ถ้าฝ่ายโจมตีเป็นธาตุที่ชนะทางก็จะสร้างความเสียหายเพิ่มขึ้น 1 หน่วย

    // ทำการสุ่มโจมตีไปจนกว่าเลือดของโปเกม่อนอีกฝ่ายจะเป็น 0 ถึงจะจบการต่อสู้

    print("\n START BATTLE !\n")
    repeat {
        print("===============")
        print("round \(round)!")
        var randomNumber = Int.random(in: 1...2)
        var damage = 0
        if(randomNumber == 1){
            randomSkill = Int.random(in: 0..<(player1.pokemon.skill.totalSkill))

            print("Player 1: use \(player1.pokemon.skill[randomSkill])")
            damage = (player1.pokemon.element.isElementWin(against: player2.pokemon.element) ? 2 : 1)
            player2.pokemon.hp -= damage
        }else{
            randomSkill = Int.random(in: 0..<(player2.pokemon.skill.totalSkill))

            print("Player 2: use \(player2.pokemon.skill[randomSkill])")

            damage = (player2.pokemon.element.isElementWin(against: player1.pokemon.element) ? 2 : 1)
            player1.pokemon.hp -= damage
        }

        round += 1
        

        // ถ้ามีโปเกม่อนเลือดเหลือ 0 จะจบการทำงานของโปรแกรม และฟื้นเลือดโปเกมอนให้กลับไปเท่า maxHP
        if(player1.pokemon.hp <= 0){
            print("\nPlayer 2 Win!\n")
            player2.pokemon.lvlUp()
            flag = false
        }else if(player2.pokemon.hp <= 0){
            print("\nPlayer 1 Win!\n")
            player1.pokemon.lvlUp()
            flag = false
        }
        
    } while (flag)

    defer{
        player1.pokemon.restoreHealth()
        player2.pokemon.restoreHealth()
        print("Battle End")
    } 

}


var player1: Trainer?
var player2: Trainer?

var pokemon1: Pokemon?
var pokemon2: Pokemon?


for pokemon in StarterPack.pokedex{
    print(pokemon.name)
}

pokemon1 = StarterPack.takePokemon(name: "hitokage")
pokemon2 = StarterPack.takePokemon(name: "zenigame")

for pokemon in StarterPack.pokedex{
    print(pokemon.name)
}

player1 = Trainer(name: "Red", pokemon: pokemon1!)
player2 = Trainer(trainer: 
        Trainer(name: "Blue", pokemon: pokemon2!)
        )
pokemon2?.owner = player2

do{
    try battle(player1: player1! , player2: player2!)
}catch BattleError.noOwner{
    print("found pokemon have not owner")
}catch BattleError.pokemonFainted{
    print("found pokemon was fainted. can join battle now")
}


pokemon1?.owner = player1

do{
    try battle(player1: player1! , player2: player2!)
}catch BattleError.noOwner{
    print("found pokemon have not owner")
}catch BattleError.pokemonFainted{
    print("found pokemon was fainted. can join battle now")
}



player1 = nil
pokemon1?.owner = nil
pokemon1 = nil

player2 = nil
pokemon2?.owner = nil
pokemon2 = nil



for pokemon in StarterPack.pokedex{
    print(pokemon.name)
}