using System;
using System.Globalization;
using Ocsf.Objects.Network;
using Ocsf.Objects.Entity;

namespace Ocsf.Objects {
        public class Endpoint {
            public string Domain { get; set; }
            public Location Location { get; set; }
            public DeviceHardwareInfo HwInfo { get; set; }
            public string Hostname { get; set; }
            public string IP { get; set; }
            public string InstanceId { get; set; }
            public string MAC { get; set; }
            public string Name { get; set; }
            public string InterfaceId { get; set; }
            public string InterfaceName { get; set; }
            public string Zone { get; set; }
            public OperatingSystem OS { get; set; }
            public string SubnetId { get; set; }
            public string Type { get; set; }
            public NetworkTypeId TypeId { get; set; }
            public string Id { get; set; }
            public string VlanId { get; set; }
            public string VpcId { get; set; }
        }
    }