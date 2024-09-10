namespace Ocsf.Objects {
        public class DeviceHardwareInfo {
            public string BiosDate { get; set; }
            public string BiosManufacturer { get; set; }
            public string BiosVer { get; set; }
            public int CpuBits { get; set; }
            public int CpuCores { get; set; }
            public int CpuCount { get; set; }
            public string Chassis { get; set; }
            public Display DesktopDisplay { get; set; }
            public KeyboardInfo Keyboard { get; set; }
            public int CpuSpeed { get; set; }
            public string CpuType { get; set; }
            public int RamSize { get; set; }
            public string SerialNumber { get; set; }
        }
    }