using System.Collections.Generic;

namespace Ocsf.Objects.Data {
        public class Enrichment {
            public Dictionary<string,string> Data { get; set; }
            public string Name { get; set; }
            public string Provider { get; set; }
            public string Type { get; set; }
            public string Value { get; set; }
        }
    }