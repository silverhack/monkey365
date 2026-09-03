using System;
using System.Globalization;

namespace Ocsf.Objects.Entity {
    public enum UserType : int
    { 
        Unknown = 0,
        User = 1,
        Admin = 2,
        System = 3,
        Other = 99
    };
}