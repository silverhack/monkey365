using System.Collections.Generic;
using Ocsf.Objects.Entity;

namespace Ocsf.Objects {
    public class ResourceDetails {
        public string CloudPartition { get; set; }
        public string Criticality { get; set; }
        public Dictionary<string,string> Data { get; set; }
        public Group Group { get; set; }
        public string[] Labels { get; set; }
        public string Name { get; set; }
        public string Namespace  { get; set; }
        public User Owner { get; set; }
        public string Region { get; set; }
        public string Type { get; set; }
        public string Id { get; set; }
        public string Version { get; set; }
    }
}