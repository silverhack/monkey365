using Ocsf.Objects.Network;
using Ocsf.Objects.Entity;

namespace Ocsf.Objects.Interface {
    public class API {
        public Request Request { get; set; }
        public Response Response { get; set; }
        public Group Group { get; set; }
        public string Operation { get; set; }
        public Service Service { get; set; }
        public string Version { get; set; }
    }
}