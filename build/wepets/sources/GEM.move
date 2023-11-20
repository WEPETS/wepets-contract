module wepets::GEM {

    use std::option::{Self, Option};
    use std::string::{Self, String};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::object::{Self, UID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{sender, TxContext};
    use sui::coin::{Self, Coin, TreasuryCap};


    struct GEM has drop {}

    #[lint_allow(coin_field)]
    /// Gems can be purchased through the `Store`.
    struct GemStore has key {
        id: UID,
        /// Profits from selling Gems.
        profits: Balance<SUI>,
        /// The Treasury Cap for the in-game currency.
        gem_treasury: TreasuryCap<GEM>,
    }


    fun init(otw: GEM, ctx: &mut TxContext) {
        
         let (treasury_cap, metadata) = coin::create_currency(
            otw, 0,
            b"WEW",
            b"wepet Gems",
            b"In-game currency",
            option::none(),
            ctx
        );        

        

        // transfer::share_object(GemStore {
        //     id: object::new(ctx),
        //     gem_treasury: treasury_cap,
        //     profits: balance::zero()
        // });

        // deal with `TokenPolicy`, `CoinMetadata` and `TokenPolicyCap`
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury_cap, sender(ctx));
    }


    public entry fun mint(
        treasury_cap: &mut TreasuryCap<GEM>, amount: u64, recipient: address, ctx: &mut TxContext
    ) {
        coin::mint_and_transfer(treasury_cap, amount, recipient, ctx)
    }

    /// Manager can burn coins
    public entry fun burn(treasury_cap: &mut TreasuryCap<GEM>, coin: Coin<GEM>) {
        coin::burn(treasury_cap, coin);
    }


    #[test_only]
    public fun test_init(ctx: &mut TxContext) {
        init(GEM {}, ctx)
    }
}



module wepets::Trade {
    use sui::tx_context::TxContext;
    use sui::object::{Self, UID};


    /// A game item that can be purchased with Gems.
    struct Pet has key, store { id: UID }  


    // Purchase Gems from the GemStore
    public fun buy_pet(){

    }



}