using System;
using System.Globalization;

namespace Ocsf.Objects {
        public class DigitalSignature {
            public string Algorithm { get; set; }
            public AlgorithmId AlgorithmId { get; set; }
            public DigitalCertificate Certificate { get; set; }
            public DateTime CreatedTime { get; set; }
            public string DeveloperId { get; set; }
            public Fingerprint Digest { get; set; }
        }
    }