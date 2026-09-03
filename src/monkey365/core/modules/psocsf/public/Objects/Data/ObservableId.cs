namespace Ocsf.Objects.Data {
    public enum ObservableId : int
    { 
        Unknown = 0,
        Hostname = 1,
        IPAddress = 2,
        MACAddress = 3,
        UserName = 4,
        EmailAddress = 5,
        URLString = 6,
        FileName = 7,
        Hash = 8,
        ProcessName = 9,
        ResourceId = 10,
        Endpoint = 20,
        User = 21,
        Email  = 22,
        URL = 23,
        File = 24,
        Process = 25,
        GeoLocation = 26,
        Container = 27,
        RegistryKey = 28,
        RegistryValue = 29,
        FingerPrint = 30,
        Other = 99
    };
}