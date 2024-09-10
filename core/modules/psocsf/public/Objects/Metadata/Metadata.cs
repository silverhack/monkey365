using System;
using System.Globalization;
using Ocsf.Objects.Entity;
using Ocsf.Objects;

namespace Ocsf.Objects {
        public class Metadata {
            public string CorrelationId { get; set; }
            public string EventCode { get; set; }
            public string Id { get; set; }
            public string[] Labels { get; set; }
            public string LogLevel { get; set; }
            public string LogName { get; set; }
            public string LogProvider { get; set; }
            public string LogVersion { get; set; }
            public string LoggedTime { get; set; }
            public Logger[] Loggers { get; set; }
            public DateTime ModifiedTime { get; set; }
            public string OriginalTime { get; set; }
            public DateTime ProcessedTime { get; set; }
            public Product Product { get; set; }
            public string[] Profiles { get; set; }
            public SchemaExtension Extension { get; set; }
            public SchemaExtension[] Extensions { get; set; }
            public int Sequence { get; set; }
            public string TenantId { get; set; }
            public string Version { get; set; }
        }
    }