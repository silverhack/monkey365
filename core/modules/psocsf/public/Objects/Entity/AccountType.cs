using System;
using System.Globalization;

namespace Ocsf.Objects.Entity {
    public enum AccountType : int
    { 
        Unknown = 0,
        LDAPAccount = 1,
        WindowsAccount = 2,
        AWSIAMUser = 3,
        AWSIAMrole = 4,
        GCPAccount = 5,
        AzureADAccount = 6,
        MacOSAccount = 7,
        AppleAccount = 8,
        LinuxAccount = 9,
        AWSAccount = 10,
        Other = 99
    };
}