namespace Ocsf.Framework {
    public class ComplianceObject {
        public string[] Requirements { get; set; }
        public string Control { get; set; }
        public string[] Standards { get; set; }
        public string Status { get; set; }
        public string StatusCode { get; set; }
        public string StatusDetail { get; set; }
        public ComplianceId StatusId { get; set; }
    }
}