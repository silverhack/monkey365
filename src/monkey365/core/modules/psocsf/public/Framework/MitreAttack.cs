namespace Ocsf.Framework {
    public class MitreAttack {
        public SubTechnique SubTechnique { get; set; }
        public Tactic Tactic { get; set; }
        public Tactic[] Tactics { get; set; }
        public Technique Technique { get; set; }
        public string Version { get; set; }
    }
}