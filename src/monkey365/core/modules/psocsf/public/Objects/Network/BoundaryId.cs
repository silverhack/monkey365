namespace Ocsf.Objects.Network {
    public enum BoundaryId : int
    { 
        Unknown = 0,
        Localhost = 1,
        Internal = 2,
        External = 3,
        SameVPC = 4,
        InternetVPCGateway = 5,
        VirtualPrivateGateway = 6,
        IntraRegionVPC = 7,
        InterRegionVPC = 8,
        LocalGateway = 9,
        GatewayVPC = 10,
        InternetGateway = 11,
        Other = 99
    };
}