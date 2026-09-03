using System;
using System.Globalization;
using Ocsf.Objects.Network;
using Ocsf.Objects.Entity;

namespace Ocsf.Objects {
        public class Device {
            public string UidAlt { get; set; }
            public string AutoscaleId { get; set; }
            public string IsCompliant { get; set; }
            public DateTime CreatedTime { get; set; }
            public string Description { get; set; }
            public string Domain { get; set; }
            public DateTime FirstSeenTime { get; set; }
            public Location Location { get; set; }
            public Group[] Groups { get; set; }
            public DeviceHardwareInfo HwInfo { get; set; }
            public string Hostname { get; set; }
            public string Hypervisor { get; set; }
            public string IMEI { get; set; }
            public string IP { get; set; }
            public Image Image { get; set; }
            public string InstanceId { get; set; }
            public DateTime LastSeenTime { get; set; }
            public string Name { get; set; }
            public OperatingSystem OS { get; set; }
            public Organization Organization { get; set; }
            public bool IsPersonal { get; set; }
            public string Region { get; set; }
            public string RiskLevel { get; set; }
            public RiskLevelId RiskLevelId { get; set; }
            public string Subnet { get; set; }
            public string SubnetId { get; set; }
            public bool IsTrusted { get; set; }
            public string Type { get; set; }
            public NetworkTypeId TypeId { get; set; }
            public string Id { get; set; }
            public string VlanId { get; set; }
            public string VpcId { get; set; }
        }
    }