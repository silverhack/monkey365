namespace Ocsf.Objects.Data {
    public enum ScoreId : int
    { 
        Unknown = 0,
        VerySafe = 1,
        Safe = 2,
        ProbablySafe = 3,
        LeansSafe = 4,
        MayNotBeSafe = 5,
        ExerciseCaution = 6,
        SuspiciousRisky = 7,
        PossiblyMalicious = 8,
        ProbablyMalicious = 9,
        Malicious = 10,
        Other = 99
    };
}