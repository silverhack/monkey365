using System.Collections.Generic;
using Ocsf.Objects.Interface;
using Ocsf.Objects.Entity;
using Ocsf.Objects.Network;

namespace Ocsf.Objects {
        public class Evidence {
            public API Api { get; set; }
            public Actor Actor { get; set; }
            public NetworkConnectionInfo ConnectionInfo { get; set; }
            public DnsQuery Query { get; set; }
            public Dictionary<string,string> Data { get; set; }
            public NetworkEndpoint DstEndpoint { get; set; }
            public File File { get; set; }
            public Process Process { get; set; }
            public NetworkEndpoint SrcEndpoint { get; set; }
        }
    }