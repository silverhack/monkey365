namespace Ocsf.Objects {
    public enum HashId : int
    { 
        Unknown = 0,
        MD5 = 1,
        SHA1 = 2,
        SHA256 = 3,
        SHA512 = 4,
        CTPH = 5,
        TLSH = 6,
        QuickXorHash = 7,
        Other = 99
    };
}