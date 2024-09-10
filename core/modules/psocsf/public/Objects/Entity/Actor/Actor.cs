using Ocsf.Objects.Network;
using Ocsf.Objects.Entity;

namespace Ocsf.Objects.Entity {
    public class Actor {
        public AuthorizationResult[] Authorizations { get; set; }
        public IdentityProvider Idp { get; set; }
        public string InvokedBy { get; set; }
        public Process Process { get; set; }
        public Session Session { get; set; }
        public User User { get; set; }
    }
}