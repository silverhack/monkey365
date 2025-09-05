using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Text;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Threading;
using System.Threading.Tasks;

/// <summary>
/// Represents a PowerShell job for Monkey365.
/// </summary>
public class MonkeyJob : System.Management.Automation.Job
{
    private System.Management.Automation.PowerShell _innerJob;
    private readonly object _lockObject = new object();
    private CancellationTokenSource _cancellationTokenSource = new CancellationTokenSource();
    private bool _failedOnUnblock = false;
    private string _status = "NotStarted";
    private System.IAsyncResult Handle;
    private bool _isDisposed = false;

    // PowerShell requires a public parameterless constructor for some scenarios
    public MonkeyJob() : base() { }

    /// <summary>
    /// Initializes a new instance of the <see cref="MonkeyJob"/> class.
    /// </summary>
    /// <param name="powerShell">The PowerShell instance to run.</param>
    /// <param name="name">The job name.</param>
    public MonkeyJob(PowerShell powerShell, string name) : base()
    {
        if (powerShell == null)
        {
            throw new ArgumentNullException("powerShell");
        }
        _innerJob = powerShell;
        this.PSJobTypeName = "MonkeyJob";
        this.Name = name;
        SetUpStreams(name);
    }

    /// <inheritdoc/>
    public override string Location
    {
        get { return "localhost"; }
    }
    /// <inheritdoc/>
    public override string StatusMessage
    {
        get { return _status; }
    }
    /// <inheritdoc/>
    public override bool HasMoreData
    {
        get {
            // Avoid LINQ for performance
            if (Output != null && Output.Count > 0) return true;
            if (Progress != null && Progress.Count > 0) return true;
            if (Error != null && Error.Count > 0) return true;
            if (Warning != null && Warning.Count > 0) return true;
            if (Verbose != null && Verbose.Count > 0) return true;
            if (Debug != null && Debug.Count > 0) return true;
            return false;
        }
    }

    private void SetUpStreams(string name)
    {
        _innerJob.Streams.Verbose = this.Verbose;
        _innerJob.Streams.Error = this.Error;
        _innerJob.Streams.Debug = this.Debug;
        _innerJob.Streams.Warning = this.Warning;
        _innerJob.InvocationStateChanged += new EventHandler<PSInvocationStateChangedEventArgs>(PowerShellInvocationStateChanged);
        // Name is already set in constructor
    }

    private void PowerShellInvocationStateChanged(object sender, PSInvocationStateChangedEventArgs e)
    {
        if (e.InvocationStateInfo.State == PSInvocationState.Completed)
        {
            lock (_lockObject)
            {
                _status = "Completed";
                SetJobState(JobState.Completed);
                Complete();
            }
        }
    }

    /// <inheritdoc/>
    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            if (!_isDisposed)
            {
                _isDisposed = true;
                // Use local variables for thread safety
                var innerJob = _innerJob;
                var cts = _cancellationTokenSource;
                try
                {
                    if (!IsFailedOrCancelled(JobStateInfo.State))
                    {
                        try { StopJob(); } catch { /* Ignore exceptions from StopJob in Dispose */ }
                    }
                    foreach (Job job in ChildJobs)
                    {
                        job.Dispose();
                    }
                    if (innerJob != null)
                    {
                        // Detach event handler to avoid memory leaks
                        innerJob.InvocationStateChanged -= new EventHandler<PSInvocationStateChangedEventArgs>(PowerShellInvocationStateChanged);
                        innerJob.Dispose();
                        _innerJob = null;
                    }
                    if (cts != null)
                    {
                        cts.Dispose();
                        _cancellationTokenSource = null;
                    }
                }
                finally
                {
                    base.Dispose(disposing);
                }
            }
        }
    }

    /// <summary>
    /// Checks if the job is completed, failed, or stopped.
    /// </summary>
    internal bool IsFailedOrCancelled(JobState state)
    {
        return (state == JobState.Completed || state == JobState.Failed || state == JobState.Stopped);
    }

    /// <summary>
    /// Throws if the job is failed or cancelled.
    /// </summary>
    protected void ThrowIfJobFailedOrCancelled()
    {
        lock (_lockObject)
        {
            if (IsFailedOrCancelled(JobStateInfo.State))
            {
                throw new InvalidOperationException("Monkey365 job is stopped or cancelled");
            }
        }
    }

    /// <inheritdoc/>
    public override void StopJob()
    {
        if (_innerJob != null)
        {
            _innerJob.Stop();
            if (Handle != null)
            {
                _innerJob.EndInvoke(Handle);
            }
        }
        lock (_lockObject)
        {
            _status = "Stopped";
            SetJobState(JobState.Stopped);
        }
    }

    /// <summary>
    /// Forcibly stops the job and sets its state to Failed.
    /// </summary>
    public void ForceStop()
    {
        lock (_lockObject)
        {
            if (_innerJob != null)
            {
                try { _innerJob.Stop(); } catch { /* Ignore exceptions */ }
                if (Handle != null)
                {
                    try { _innerJob.EndInvoke(Handle); } catch { /* Ignore exceptions */ }
                }
            }
            _status = "Failed";
            SetJobState(JobState.Failed);
        }
    }

    /// <summary>
    /// Starts the job.
    /// </summary>
    public void Start()
    {
        Handle = _innerJob.BeginInvoke<PSObject, PSObject>(null, Output);
        lock (_lockObject)
        {
            SetJobState(JobState.Running);
            _status = "Running";
        }
    }

    /// <summary>
    /// Waits for the job to complete.
    /// </summary>
    public void WaitJob()
    {
        if (Handle != null)
        {
            Handle.AsyncWaitHandle.WaitOne();
        }
    }

    /// <summary>
    /// Waits for the job to complete or timeout.
    /// </summary>
    public void WaitJob(TimeSpan timeout)
    {
        if (Handle != null)
        {
            Handle.AsyncWaitHandle.WaitOne(timeout);
        }
    }

    /// <summary>
    /// Returns true if the job is finished.
    /// </summary>
    public bool IsFinished()
    {
        return Handle != null && Handle.IsCompleted;
    }

    /// <summary>
    /// Gets the job status as a PSObject.
    /// </summary>
    public PSObject JobStatus()
    {
        PSObject responseObject = new PSObject();
        responseObject.Members.Add(new PSNoteProperty("InstanceId", _innerJob.InstanceId));
        responseObject.Members.Add(new PSNoteProperty("State", _innerJob.InvocationStateInfo.State));
        if (Handle != null)
        {
            responseObject.Members.Add(new PSNoteProperty("Reason", Handle.IsCompleted));
            responseObject.Members.Add(new PSNoteProperty("AsyncState", Handle.AsyncState));
        }
        responseObject.Members.Add(new PSNoteProperty("Error", _innerJob.Streams.Error));
        responseObject.Members.Add(new PSNoteProperty("Warning", _innerJob.Streams.Warning));
        responseObject.Members.Add(new PSNoteProperty("Info", _innerJob.Streams.Information));
        responseObject.Members.Add(new PSNoteProperty("Verbose", _innerJob.Streams.Verbose));
        responseObject.Members.Add(new PSNoteProperty("Debug", _innerJob.Streams.Debug));
        return responseObject;
    }

    private bool TryStart()
    {
        bool result = false;
        lock (_lockObject)
        {
            if (!IsFailedOrCancelled(JobStateInfo.State))
            {
                _status = "Running";
                SetJobState(JobState.Running);
                result = true;
            }
        }
        return result;
    }

    private void Fail()
    {
        lock (_lockObject)
        {
            _status = "Failed";
            SetJobState(JobState.Failed);
        }
    }

    private void Complete()
    {
        lock (_lockObject)
        {
            if (_failedOnUnblock)
            {
                _status = "Failed";
                SetJobState(JobState.Failed);
            }
            else if (JobStateInfo != null && !IsFailedOrCancelled(JobStateInfo.State))
            {
                _status = "Completed";
                SetJobState(JobState.Completed);
            }
        }
    }

    private void Cancel()
    {
        lock (_lockObject)
        {
            _status = "Stopped";
            SetJobState(JobState.Stopped);
        }
    }

    /// <summary>
    /// Starts the job asynchronously and returns the results.
    /// </summary>
    public async Task<PSDataCollection<PSObject>> StartTask()
    {
        PSDataCollection<PSObject> results = new PSDataCollection<PSObject>();
        if (TryStart())
        {
            try
            {
                results = await Task<PSDataCollection<PSObject>>.Factory.FromAsync(_innerJob.BeginInvoke(), pResult => _innerJob.EndInvoke(pResult)).ConfigureAwait(false);
                return results;
            }
            catch (PSInvalidOperationException ex)
            {
                string message = ex.Message;
                WriteError(new ErrorRecord(ex, message, ErrorCategory.InvalidOperation, this));
            }
            catch (TaskCanceledException ex)
            {
                string message = ex.Message;
                WriteError(new ErrorRecord(ex, message, ErrorCategory.OperationStopped, this));
            }
            catch (Exception ex)
            {
                string message = ex.Message;
                WriteError(new ErrorRecord(ex, message, ErrorCategory.InvalidOperation, this));
                _failedOnUnblock = true;
            }
            finally
            {
                Complete();
            }
            return new PSDataCollection<PSObject>();
        }
        else
        {
            return new PSDataCollection<PSObject>();
        }
    }

    /// <summary>
    /// Adds an error record to the job's error stream if possible.
    /// </summary>
    public void WriteError(ErrorRecord errorRecord)
    {
        lock (_lockObject)
        {
            if (IsFailedOrCancelled(JobStateInfo.State))
            {
                return;
            }
        }
        if (Error.IsOpen)
        {
            Error.Add(errorRecord);
        }
    }

    /// <summary>
    /// Disposes the inner PowerShell job's RunspacePool if available.
    /// </summary>
    public void DisposeInnerRunspacePool()
    {
        lock (_lockObject)
        {
            if (_innerJob != null && _innerJob.RunspacePool != null)
            {
                try
                {
                    if (_innerJob.RunspacePool.RunspacePoolStateInfo.State != RunspacePoolState.Closed &&
                        _innerJob.RunspacePool.RunspacePoolStateInfo.State != RunspacePoolState.Broken &&
                        _innerJob.RunspacePool.RunspacePoolStateInfo.State != RunspacePoolState.Closing)
                    {
                        _innerJob.RunspacePool.Dispose();
                    }
                }
                catch { /* Ignore exceptions on close */ }
                finally
                {
                    _innerJob.RunspacePool = null;
                }
            }
        }
    }
}