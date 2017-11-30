# wcms-colo-synch
Code for synchronizing the colo site from production.

There are three tasks invoked in this order by this control script: aws_refresh.ps1

* File-copy batch script, exit code of 0 means success
* DB stored procedure, return code of 0 means success
* centOS Elasticsearch index restore, output message of "success" means success

If any of the tasks is none-success, the control script will send email and halt.

The settings.xml needs to configured to allow the script to run:

```xml
<settings testmode="0">   
<!--
       if 1, will output more information about script execution
    -->

<file batchcmd="File-CopyBatchCMD"/>

<DB connectionString="XXXX" storedprocedure="XXXXX"/>
    
<ES server="COLOES" userid="XXX" password="XXXX"/>

<email server="XXXX" from="XX@XX" to="XXX@XXX" subjectLine="COLO AWS refresh failed" />

</settings>
```

To execute this script:  powershell .\report-downloader.ps1
