namespace Ocsf.Objects.Network {
        public class NetworkConnectionInfo {
            public string Boundary { get; set; }
            public BoundaryId BoundaryId { get; set; }
            public string Id { get; set; }
            public string Direction { get; set; }
            public DirectionId DirectionId { get; set; }
            public string ProtocolVer { get; set; }
            public ProtocolVerId ProtocolVerId { get; set; }
            public string ProtocolName { get; set; }
            public string ProtocolNum { get; set; }
            public Session Session { get; set; }
            public int TcpFlags { get; set; }
        }
    }