using System;
using System.Globalization;

namespace Ocsf.Objects.Entity {
    public class LDAPPerson {
        public string CostCenter { get; set; }
        public DateTime CreatedTime { get; set; }
        public DateTime DeletedTime { get; set; }
        public string[] EmailAddrs { get; set; }
        public string EmployeeId { get; set; }
        public Location Location { get; set; }
        public string GivenName { get; set; }
        public DateTime Hiretime { get; set; }
        public string JobTitle { get; set; }
        public string LdapCn { get; set; }
        public string LdapDn { get; set; }
        public string[] Labels { get; set; }
        public DateTime LastLoginTime { get; set; }
        public DateTime LeaveTime { get; set; }
        public User Manager { get; set; }
        public DateTime ModifiedTime { get; set; }
        public string OfficeLocation { get; set; }
        public string Surname { get; set; }
    }
}