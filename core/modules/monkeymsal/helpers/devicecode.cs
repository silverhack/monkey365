using System;
using System.Threading.Tasks;
using System.Collections.Generic;
//using System.Diagnostics;
using Microsoft.Identity.Client;

public static class DeviceCodeHelper
{
    public static Func<DeviceCodeResult,Task> GetDeviceCodeResultCallback()
    {
        return deviceCodeResult =>
        {
            // This will print the message on the console which tells the user where to go sign-in using 
            // a separate browser and the code to enter once they sign in.
            // The AcquireTokenWithDeviceCode() method will poll the server after firing this
            // device code callback to look for the successful login of the user via that browser.
            // This background polling (whose interval and timeout data is also provided as fields in the 
            // deviceCodeCallback class) will occur until:
            // * The user has successfully logged in via browser and entered the proper code
            // * The timeout specified by the server for the lifetime of this code (typically ~15 minutes) has been reached
            // * The developing application calls the Cancel() method on a CancellationToken sent into the method.
            //   If this occurs, an OperationCanceledException will be thrown (see catch below for more details).
            Console.WriteLine(deviceCodeResult.Message);
            //Console.WriteLine("ExpiresOn: " + deviceCodeResult.ExpiresOn.ToLocalTime());
            // try {
            //     Process.Start(new ProcessStartInfo { UseShellExecute = true, FileName = deviceCodeResult.VerificationUrl });
            //     //Clipboard.SetData(DataFormats.Text, (Object)deviceCodeResult.UserCode);
            //     Process.Start(new ProcessStartInfo { UseShellExecute = false, FileName = "cmd", Arguments = "/c echo " + deviceCodeResult.UserCode + " | clip" });
            // }
            // catch {}
            return Task.FromResult(0);
        };
    }
}