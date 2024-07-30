mod DiscoveryEnums {
    #[derive(Copy, Drop, Serde, PartialEq)]
    enum ExploreResult {
        Beast,
        Obstacle,
        Discovery,
    }

    #[derive(Copy, Drop, PartialEq)]
    enum DiscoveryType {
        Gold: u16,
        Health: u16,
        Loot: u8,
    }
}
