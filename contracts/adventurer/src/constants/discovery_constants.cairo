mod DiscoveryEnums {
    #[derive(Copy, Drop, PartialEq)]
    enum ExploreResult {
        Beast: (),
        Obstacle: (),
        Treasure: (),
    }

    #[derive(Copy, Drop, PartialEq)]
    enum TreasureDiscovery {
        Gold: (),
        Health: (),
    }
}
