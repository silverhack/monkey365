using System;
using System.Globalization;
using Ocsf.Objects.Entity;

namespace Ocsf.Objects {
        public class Process {
            public string CmdLine { get; set; }
            public DateTime CreatedTime { get; set; }
            public string XAttributes { get; set; }
            public File File { get; set; }
            public string Integrity { get; set; }
            public IntegrityId IntegrityId { get; set; }
            public string[] Lineage { get; set; }
            public string[] LoadedModules { get; set; }
            public string Name { get; set; }
            public Process ParentProcess { get; set; }
            public int Pid { get; set; }
            public string Sandbox { get; set; }
            public DateTime TerminatedTime { get; set; }
            public int Tid { get; set; }
            public string Id { get; set; }
            public User User { get; set; }
        }
    }