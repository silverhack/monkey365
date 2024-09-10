using System;
using System.Globalization;
using Ocsf.Objects.Entity;
using Ocsf.Objects;

namespace Ocsf.Objects {
        public class File {
            public DateTime AccessedTime { get; set; }
            public User Accessor { get; set; }
            public int Attributes { get; set; }
            public string CompanyName { get; set; }
            public string Confidentiality { get; set; }
            public ConfidentialityId ConfidentialityId { get; set; }
            public DateTime CreatedTime { get; set; }
            public User Creator { get; set; }
            public string Description { get; set; }
            public DigitalSignature Signature { get; set; }
            public Fingerprint Hashes { get; set; }
            public string MimeType { get; set; }
            public DateTime ModifiedTime { get; set; }
            public User Modifier { get; set; }
            public string Name { get; set; }
            public User Owner { get; set; }
            public string ParentFolder { get; set; }
            public string Path { get; set; }
            public Product Product { get; set; }
            public string SecurityDescriptor { get; set; }
            public long Size { get; set; }
            public bool IsSystem { get; set; }
            public string Type { get; set; }
            public FileTypeId TypeId { get; set; }
            public string Id { get; set; }
            public string Version { get; set; }
        }
    }