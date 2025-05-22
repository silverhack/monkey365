ConvertFrom-StringData @'
    RunspaceCreationError          = Unable to create RunspacePool
    ISSCreationError               = Unable to create Initial Session State
    OpenRunspaceMessage            = Opening runspacePool
    CloseRunspaceMessage           = Closing runspacePool
    MonkeyJobObjectError           = Unable to create MonkeyJob object
    CompletedJobs                  = All Jobs are completed
    WaitJobCompletion              = Waiting for job completion
    RunspaceError                  = Runspace state was not opened
    UnknownError                   = Unknown error. Probably runspace state was either broken, or closed
    TimeSpentInvokeBatchMessage    = Time spent on Invoking Batch number {0}: {1}
    TimeSpentCollectBatchMessage   = Time spent on Collecting Batch number {0}: {1}
    SleepMessage                   = Sleeping for {0} Milliseconds
    TerminateJobMessage            = Finishing the {0} job(s) that are still running
    UnableToExecuteCommand         = Unable to process command: {0}
    UnknownObject                  = Status-Code: {0}
    ErrorOnThreadEndInvoke         = Error on Thread EndInvoke : {0}
    DetailedEndInvokeErrorMessage  = It was received while processing Object {0}. Job ID: {1}
    DummyFunctionMessage           = Setting dummy function {0}
    UnableToCreateProxyCommand     = Unable to create the Proxy command, Error : {0}
    StoppingTimerMessage           = Stopping timer
    RemoveDummyFunctionMessage     = Removing dummy function {0}
    ScriptBlockError               = Unable to create ScriptBlock object
    CommandNotRecognized           = Command {0} cannot be imported
    UnableToRemoveJob              = "Unable to remove job {0}"
'@
