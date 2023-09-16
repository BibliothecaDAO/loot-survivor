mod DiscoveryEnums {
    #[derive(Copy, Drop, PartialEq)]
    enum ExploreResult {
        Beast: (),
        Obstacle: (),
        Discovery: (),
    }

    #[derive(Copy, Drop, PartialEq)]
    enum DiscoveryType {
        Gold: (),
        Health: (),
    }
}
