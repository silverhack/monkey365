using System;
using System.Globalization;

namespace Ocsf.Objects.Data {
    public class Analytic {
        public string Category { get; set; }
        public string Description { get; set; }
        public string Name { get; set; }
        public Analytic[] RelatedAnalytics { get; set; }
        public string Type { get; set; }
        public TypeId TypeId { get; set; }
        public string Id { get; set; }
        public string Version { get; set; }
    }
}