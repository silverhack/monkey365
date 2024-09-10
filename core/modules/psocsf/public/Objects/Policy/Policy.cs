using Ocsf.Objects.Entity;

namespace Ocsf.Objects {
    public class Policy {
        public string Description { get; set; }
        public Group Group { get; set; }
        public string Name { get; set; }
        public string Id { get; set; }
        public string Version { get; set; }
    }
}