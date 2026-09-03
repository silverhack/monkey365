using System;
using System.Globalization;
using Ocsf.Framework;
using Ocsf.Objects.Data;
using Ocsf.Objects.Events;

namespace Ocsf.Objects.Finding {
    public class FindingInfo {
        public Analytic Analytic { get; set; }
        public DateTime CreatedTime { get; set; }
        public string[] DataSources { get; set; }
        public string Description { get; set; }
        public ActivityId ActivityId { get; set; }
        public DateTime FirstSeenTime { get; set; }
        public KillChain KillChain { get; set; }
        public DateTime LastSeenTime { get; set; }
        public MitreAttack[] Attacks { get; set; }
        public DateTime ModifiedTime { get; set; }
        public string ProductId { get; set; }
        public Analytic[] RelatedAnalytics { get; set; }
        public RelatedEvent[] RelatedEvents { get; set; }
        public string SrcUrl { get; set; }
        public string Title { get; set; }
        public string[] Types { get; set; }
        public string Id { get; set; }
    }
}