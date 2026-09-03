using Ocsf.Objects;

namespace Ocsf.Objects.Entity {
    public class Cloud {
        public Account Account { get; set; }
        public string Zone { get; set; }
        public Organization Organization { get; set; }
        public string ProjectId { get; set; }
        public string Provider { get; set; }
        public string Region { get; set; }
    }
}