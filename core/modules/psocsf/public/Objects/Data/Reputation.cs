namespace Ocsf.Objects.Data {
    public class Reputation {
        public string Provider { get; set; }
        public float BaseScore { get; set; }
        public string Score { get; set; }
        public ScoreId ScoreId { get; set; }
    }
}