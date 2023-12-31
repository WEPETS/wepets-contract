module wepets::we_pet_game {
    use sui::event;
    use std::string::{Self, String};
    use sui::object::{Self, UID, ID};
    use sui::url::{Self, Url};
    use sui::transfer;
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext};
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use std::option::{Self, Option};

    // TODO: EVENT
    struct Hero has key, store {
        id: UID,
        level: u8,
        game_id: ID,
    }

    struct Pet has key, store {
        id: UID,
        hp: u8,
        exp: u8,
        strength: u8,
        game_id: ID,
        owner: ID // pet of owner
    }

    struct Bot has key, store {
        id: UID,
        hp: u8,
        strength: u8,
        game_id: ID,
    }

    struct GameInfo has key {
        id: UID,
        admin: address
    }

    // TODO: refactor
    struct GameAdmin has key {
        id: UID,
        bot_animal_created: u8,
        game_id: ID,
    }

    struct Bot_animalEvent has copy, drop {
        slayer_address: address,
        hero: ID,
        pet: ID,
        game_id: ID,
    }


    // TODO: ERROR
    const NOT_PET: u64 = 0;
    const PET_WIN:u64 = 0;
    const PET_lose:u64 = 2;

    #[allow(unused_function)]
    fun init(ctx: &mut TxContext) {
        create_game(ctx);
    }

    fun create_game(ctx: &mut TxContext){
        let sender = tx_context::sender(ctx);
        let id = object::new(ctx);
        let game_id = object::uid_to_inner(&id);

        transfer::freeze_object(GameInfo {
            id,
            admin: sender
        });

        transfer::transfer(
            GameAdmin {
                id: object::new(ctx),
                game_id,
                bot_animal_created: 0,
            }, 
            sender
        )
    }

    // TODO: Token

    // ENTRY FUNCTION 
    // ADMIN
    // create profile
    // TODO
    public entry fun create_profile(
        game: &GameInfo, admin: &GameAdmin, player: address, ctx: &mut TxContext
    ) {

        // create a hero
        let new_hero = create_hero(game, ctx);
        let hero_ref = &new_hero;
        // create a pet
        let new_pet = create_pet(game, hero_ref, 100, 30, ctx);
        transfer::public_transfer(new_hero, player);
        transfer::public_transfer(new_pet, player);
    }

    // create bot (send bot to player)
    // TODO;  
    public entry fun send_bot(
        game: &GameInfo, admin: &mut GameAdmin, player: address, hp: u8,strength: u8 , ctx: &mut TxContext
    ) {
        // create a pet
        let new_bot = create_bot(game, hp, strength, ctx);

        admin.bot_animal_created = admin.bot_animal_created + 1;
        transfer::public_transfer(new_bot, player);
    }

    // USER
    // attrack
    // TODO
    public entry fun huntbot(game: &GameInfo, hero: &mut Hero, pet: &mut Pet, bot: Bot, ctx: &TxContext) {
        let Bot {id: b_id, hp, strength: bot_strength, game_id: _} = bot;

        // check pet la cua hero 
        assert!(id(hero) ==  pet.owner, NOT_PET);

    
        // pet vs bot   
        let bot_hp = hp;   
        let pet_hp = pet.hp;
        let pet_strength = pet.strength * 2;

        while (bot_hp > pet.strength) {
            // hero attack boar
            bot_hp = bot_hp - pet.strength;
            assert!(bot_hp >= bot_strength , 1);
            bot_hp = bot_hp - bot_strength;

        };



     
        hero.level = hero.level + pet_hp;
        pet.exp = pet.exp + pet.strength * 10/100;
        
        pet.hp = pet_hp;

        event::emit(Bot_animalEvent {
            slayer_address: tx_context::sender(ctx),
            hero: object::uid_to_inner(&hero.id),
            pet: object::uid_to_inner(&pet.id),
            game_id: object::id(game)
        });

    
        // level up pet & hero
        

        // delete bot
        object::delete(b_id);

    }

    public fun create_hero(game: &GameInfo, ctx: &mut TxContext): Hero {
        Hero {
            id: object::new(ctx),
            level: 0,
            game_id: game_id(game)
        }
    }

    public fun create_pet(game: &GameInfo,hero: &Hero, hp: u8, strength: u8, ctx: &mut TxContext): Pet {
        Pet {
            id: object::new(ctx),
            hp, 
            exp: 1,
            strength,
            game_id: game_id(game),
            owner: id(hero)
        }
    }

    public fun create_bot(game: &GameInfo, hp: u8, strength: u8, ctx: &mut TxContext): Bot {
        Bot {
            id: object::new(ctx),
            hp, 
            strength,
            game_id: game_id(game)
        }

    }

 

    public fun game_id(game: &GameInfo): ID {
        object::id(game)
    }

    // check pet of hero 
    public fun checkpet(hero: &Hero, id: ID) {
        assert!(id(hero) == id, 403);
    }

    public fun id(hero: &Hero): ID {
        object::id(hero)
    }


    #[test] 
    fun test_game(){
        use sui::test_scenario;

        let admin = @0xAD; 
        let player = @0x1AD; 

        //create game 
        let sceneraio_val = test_scenario::begin(admin);
        let scenario = &mut sceneraio_val;
        {
            init(test_scenario::ctx(scenario));
        };

        //Create profile
        test_scenario::next_tx(scenario, admin);
        {
            // freeze object -> take immutable 
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref: &GameInfo = &game;

            // check sender have to admin object 
            let admin = test_scenario::take_from_sender<GameAdmin>(scenario);
            create_profile(game_ref, &admin, player ,test_scenario::ctx(scenario));
            test_scenario::return_immutable(game);
            test_scenario::return_to_sender(scenario, admin)
            
        };


        // -> Create bot ->  Admin send bot to player 
        test_scenario::next_tx(scenario, admin);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref: &GameInfo = &game;

            let admin = test_scenario::take_from_sender<GameAdmin>(scenario);
            send_bot(game_ref, &mut admin, player,50, 10,test_scenario::ctx(scenario));

            test_scenario::return_immutable(game);
            test_scenario::return_to_sender(scenario, admin);
        };

        // attack 
        test_scenario::next_tx(scenario, player);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let hero: Hero = test_scenario::take_from_sender<Hero>(scenario);
            let pet: Pet = test_scenario::take_from_sender<Pet>(scenario);
            // drop bot
            let bot: Bot = test_scenario::take_from_sender<Bot>(scenario);

            huntbot(&game, &mut hero, &mut pet, bot, test_scenario::ctx(scenario));

            test_scenario::return_immutable(game);
            test_scenario::return_to_sender(scenario, hero);
            test_scenario::return_to_sender(scenario, pet)
        };
            
        test_scenario::end(sceneraio_val);

    }

    

    #[test_only]
    fun test_attack(){

    }


}
