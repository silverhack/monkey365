namespace Ocsf.Objects.Network {
    public enum OpcodeId : int
    { 
        Query = 0,
        InverseQuery = 1,
        Status = 2,
        Reserved = 3,
        Notify = 4,
        Update = 5,
        DSOMessage = 6
    };
}