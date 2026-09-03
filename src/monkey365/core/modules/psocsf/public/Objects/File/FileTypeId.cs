namespace Ocsf.Objects {
    public enum FileTypeId : int
    { 
        Unknown = 0,
        RegularFile = 1,
        Folder = 2,
        CharacterDevice = 3,
        BlockDevice = 4,
        LocalSocket = 5,
        NamedPipe = 6,
        SymbolicLink = 7,
        Other = 9
    };
}