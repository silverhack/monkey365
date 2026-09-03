using System;
using System.Globalization;

namespace Ocsf.Objects {
        public class Session {
            public string UidAlt { get; set; }
            public int Count { get; set; }
            public DateTime CreatedTime { get; set; }
            public string ExpirationReason { get; set; }
            public DateTime ExpirationTime { get; set; }
            public string Issuer { get; set; }
            public bool IsMfa { get; set; }
            public bool IsRemote { get; set; }
            public string Terminal { get; set; }
            public Guid GUID { get; set; }
            public string Id { get; set; }
            public string CredentialId { get; set; }
            public bool IsVpn { get; set; }
        }
    }