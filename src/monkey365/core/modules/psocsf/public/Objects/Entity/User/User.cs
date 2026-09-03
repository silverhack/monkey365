using Ocsf.Objects;

namespace Ocsf.Objects.Entity {
    public class User {
        public Account Account { get; set; }
        public string AlternateId { get; set; }
        public string Domain { get; set; }
        public string EmailAddr { get; set; }
        public string FullName { get; set; }
        public Group[] Groups  { get; set; }
        public LDAPPerson LDAPPerson { get; set; }
        public string Name { get; set; }
        public Organization Organization { get; set; }
        public string Type { get; set; }
        public UserType TypeId { get; set; }
        public string Id { get; set; }
        public string CredentialId { get; set; }
    }
}