using System;
using System.Globalization;
using Ocsf.Objects.Entity;
using Ocsf.Objects;

namespace Ocsf.Objects {
        public class DigitalCertificate {
            public string SerialNumber { get; set; }
            public DateTime CreatedTime { get; set; }
            public DateTime ExpirationTime { get; set; }
            public Fingerprint[] Fingerprints { get; set; }
            public string Issuer { get; set; }
            public string Subject { get; set; }
            public string Id { get; set; }
            public string Version { get; set; }
        }
    }