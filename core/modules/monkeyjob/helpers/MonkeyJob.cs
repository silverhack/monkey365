using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Text;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Threading;
using System.Threading.Tasks;

public class MonkeyJob: System.Management.Automation.Job {
    public System.Management.Automation.PowerShell InnerJob;

    public MonkeyJob(PowerShell PowerShell ,string name){
        InnerJob = PowerShell;
        this.PSJobTypeName = "MonkeyJob";
        this.Name = name;
        SetUpStreams(name);
    }

    public override string Location{
        get { return "localhost"; }
    }
    public override string StatusMessage{
        get { return _status; }
    }
    public override bool HasMoreData{
        get {
            return Output.Any() || Progress.Any() || Error.Any()
                || Warning.Any() || Verbose.Any() || Debug.Any();

        }
    }
    private void SetUpStreams(string name){
        InnerJob.Streams.Verbose = this.Verbose;
        InnerJob.Streams.Error = this.Error;
        InnerJob.Streams.Debug = this.Debug;
        InnerJob.Streams.Warning = this.Warning;
        InnerJob.InvocationStateChanged  += new EventHandler<PSInvocationStateChangedEventArgs>(Powershell_InvocationStateChanged);
        int id = System.Threading.Interlocked.Add(ref JobNumber, 1);
        if (!string.IsNullOrEmpty(name)){
            this.Name = name;
        }
        else{
            this.Name = "MonkeyJob";
        }
    }
    void Powershell_InvocationStateChanged(object sender, PSInvocationStateChangedEventArgs e){
        if (e.InvocationStateInfo.State == PSInvocationState.Completed){
            _status = "Completed";
            SetJobState(JobState.Completed);
            Complete();
        }
    }
    protected override void Dispose(bool disposing){
        if (disposing){
            if (!isDisposed){
                isDisposed = true;
                try{
                    if (!IsFailedOrCancelled(JobStateInfo.State)){
                        StopJob();
                    }
                    foreach (Job job in ChildJobs){
                        job.Dispose();
                    }
                }
                finally{
                    base.Dispose(disposing);
                }
            }
        }
    }
    CancellationTokenSource cancellationTokenSource = new CancellationTokenSource();
    bool _failedOnUnblock = false;
    string _status = "NotStarted";
    object _lockObject = new object();
    System.IAsyncResult Handle;
    static int JobNumber = 0;
    private bool isDisposed = false;
    internal bool IsFailedOrCancelled(JobState state){
        return (state == JobState.Completed || state == JobState.Failed || state == JobState.Stopped);
    }
    protected void ThrowIfJobFailedOrCancelled(){
        lock (_lockObject){
            if (IsFailedOrCancelled(JobStateInfo.State)){
                throw new Exception("Monkey365 job is stopped or cancelled");
            }
        }
    }
    public override void StopJob(){
        InnerJob.Stop();
        if (Handle != null){
            InnerJob.EndInvoke(Handle);
        }
        _status = "Stopped";
        SetJobState(JobState.Stopped);
    }
    public void Start(){
        Handle = InnerJob.BeginInvoke<PSObject, PSObject>(null, Output);
        SetJobState(JobState.Running);
        _status = "Running";
    }
    public void WaitJob(){
        Handle.AsyncWaitHandle.WaitOne();
    }
    public void WaitJob(TimeSpan timeout){
        Handle.AsyncWaitHandle.WaitOne(timeout);
    }
    public bool IsFinished(){
        return Handle.IsCompleted;
    }
    public PSObject JobStatus(){
        PSObject responseObject = new PSObject();
        responseObject.Members.Add(new PSNoteProperty("InstanceId", InnerJob.InstanceId));
        responseObject.Members.Add(new PSNoteProperty("State", InnerJob.InvocationStateInfo.State));
        if (Handle != null){
            responseObject.Members.Add(new PSNoteProperty("Reason", Handle.IsCompleted));
            responseObject.Members.Add(new PSNoteProperty("AsyncState", Handle.AsyncState));
        }
        responseObject.Members.Add(new PSNoteProperty("Error", InnerJob.Streams.Error));
        responseObject.Members.Add(new PSNoteProperty("Warning", InnerJob.Streams.Warning));
        responseObject.Members.Add(new PSNoteProperty("Info", InnerJob.Streams.Information));
        responseObject.Members.Add(new PSNoteProperty("Verbose", InnerJob.Streams.Verbose));
        responseObject.Members.Add(new PSNoteProperty("Debug", InnerJob.Streams.Debug));
        return responseObject;
    }
    private bool TryStart(){
        bool result = false;
        lock (_lockObject){
            if (!IsFailedOrCancelled(JobStateInfo.State)){
                _status = "Running";
                SetJobState(JobState.Running);
                result = true;
            }
        }
        return result;
    }
    private void Fail(){
        lock (_lockObject){
            _status = "Failed";
            SetJobState(JobState.Failed);
        }
    }
    private void Complete(){
        lock (_lockObject){
            if (_failedOnUnblock){
                _status = "Failed";
                SetJobState(JobState.Failed);
            }

            if (JobStateInfo != null && !IsFailedOrCancelled(JobStateInfo.State)){
                _status = "Completed";
                SetJobState(JobState.Completed);
            }
        }
    }
    private void Cancel(){
        lock (_lockObject){
            _status = "Stopped";
            SetJobState(JobState.Stopped);
        }
    }
    public async Task<PSDataCollection<PSObject>> StartTask(){
        PSDataCollection<PSObject> results = new PSDataCollection<PSObject>();
        if (TryStart()){
            try{
                results = await Task<PSDataCollection<PSObject>>.Factory.FromAsync(InnerJob.BeginInvoke(), pResult => InnerJob.EndInvoke(pResult));
                return results;
            }
            catch (PSInvalidOperationException ex){
                string message = string.Format(ex.Message);
                WriteError(new ErrorRecord(ex, message, ErrorCategory.InvalidOperation, this));
            }
            catch (TaskCanceledException ex){
                string message = string.Format(ex.Message);
                WriteError(new ErrorRecord(ex, message, ErrorCategory.OperationStopped, this));
            }
            catch (Exception ex){
                string message = string.Format(ex.Message);
                WriteError(new ErrorRecord(ex, message, ErrorCategory.InvalidOperation, this));
                _failedOnUnblock = true;
            }
            finally{
                Complete();
            }
            return new PSDataCollection<PSObject>();
        }
        else{
            return new PSDataCollection<PSObject>();
        }
    }
    public void WriteError(ErrorRecord errorRecord){
        ThrowIfJobFailedOrCancelled();
        if (Error.IsOpen){
            Error.Add(errorRecord);
        }
    }
}