namespace Ocsf.Objects {
    public enum ConfidentialityId : int
    { 
        Unknown = 0,
        NotConfidential = 1,
        Confidential = 2,
        Secret = 3,
        TopSecret = 4,
        Other = 9
    };
}