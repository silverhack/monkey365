using System;
using System.Globalization;
using Ocsf.Framework;
using Ocsf.Objects.Data;

namespace Ocsf.Objects.Events {
    public class RelatedEvent {
        public KillChain[] KillChain { get; set; }
        public MitreAttack[] Attacks { get; set; }
        public Observable[] Observable { get; set; }
        public string ProductId { get; set; }
        public string Type { get; set; }
        public long TypeId { get; set; }
        public string Id { get; set; }
    }
}