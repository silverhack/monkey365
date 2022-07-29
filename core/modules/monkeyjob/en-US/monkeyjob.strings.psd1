ConvertFrom-StringData @'
    PipelineNotSupported           = Pipeline is not supported for {0}, retrying without the Pipeline Inputobject
    UnableToExecuteCommand         = Unable to process command: {0}
    UnknownObject                  = Status-Code: {0}
    CompletedJobs                  = All Jobs are Completed
    WaitJobCompletion              = Waiting for job completion
    ErrorOnThreadEndInvoke         = Error on Thread EndInvoke : {0}
    DetailedEndInvokeErrorMessage  = It was received while processing Object {0}. Job ID: {1}
    DummyFunctionMessage           = Setting dummy function {0}
    UnableToCreateProxyCommand     = Unable to create the Proxy command, Error : {0}
    SleepMessage                   = Sleeping for {0} Milliseconds
    StoppingTimerMessage           = Stopping timer
    RemoveDummyFunctionMessage     = Removing dummy function {0}
    TimeSpentInvokeBatchMessage    = Time spent on Invoking Batch number {0}: {1}
    TimeSpentCollectBatchMessage   = Time spent on Collecting Batch number {0}: {1}
    TerminateJobMessage            = Finishing the {0} job(s) that are still running
    UnknownError                   = Unknown error. Probably runspace state was either broken, or closed
    RunspaceError                  = Runspace state was not opened
    ScriptBlockError               = Unable to create ScriptBlock object
    OpenRunspaceMessage            = Opening runspacePool
    CommandNotRecognized           = Command {0} cannot be imported
'@