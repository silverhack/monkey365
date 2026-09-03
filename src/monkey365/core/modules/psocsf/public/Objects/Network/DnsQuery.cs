namespace Ocsf.Objects.Network {
        public class DnsQuery {
            public string Opcode { get; set; }
            public OpcodeId OpcodeId { get; set; }
            public int PacketId { get; set; }
            public string Class { get; set; }
            public string Type { get; set; }
        }
    }