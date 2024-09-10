using System;
using System.Globalization;

namespace Ocsf.Objects {
        public class Logger {
            public Device Device { get; set; }
            public string LogLevel { get; set; }
            public string LogName { get; set; }
            public string LogProvider { get; set; }
            public string LogVersion { get; set; }
            public DateTime LoggedTime { get; set; }
            public string Name { get; set; }
            public Product Product { get; set; }
            public DateTime TransmitTime { get; set; }
            public string Id { get; set; }
            public string Version { get; set; }
        }
    }