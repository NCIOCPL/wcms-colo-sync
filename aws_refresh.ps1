function DBRefresh($settings) {

  $connection = new-object system.data.SqlClient.SQLConnection($settings.settings.DB.connectionString)
  $command = new-object system.data.sqlclient.sqlcommand($settings.settings.DB.storedprocedure, $connection)
  $command.CommandType = "StoredProcedure"
  $command.CommandTimeout=65535

  $command.Parameters.Add("@ReturnValue", [System.Data.SqlDbType]"Int")  | Out-Null
  $command.Parameters["@ReturnValue"].Direction = [System.Data.ParameterDirection]"ReturnValue"
    
  try {
        $connection.Open()  | out-null
        $command.ExecuteNonQuery()  | out-null
        $returnValue = [int]$command.Parameters["@ReturnValue"].Value
      }
    finally {
        $connection.Close()
    }

return $returnValue
}   


function Main() {
    try {
            
            [xml]$settings = Get-Content "settings.xml"

            if ( $settings.settings.testmode -eq 1 ) { write-host 'start copy'}
            # Copy file goes here 
            
            cmd /c $settings.settings.file.batchcmd |Out-String  
            
            $status = $LastExitCode
            
           write-host "Copy file exit code: " $status
           
           If ( $status -ne 0 ) { 
           
           send-mailmessage `
                                -SmtpServer $settings.settings.email.server `
                                -From $settings.settings.email.from `
                                -To $settings.settings.email.to `
                                -Subject $settings.settings.email.subjectLine `
                                -BODY 'copy file failed'
           
           return 1}

            if ( $settings.settings.testmode -eq 1 ) { write-host 'start DB'} 

            $status=DBRefresh($settings)

            if ( $settings.settings.testmode -eq 1 ) { write-host 'DB restore return code: ' $status }
            
            If ( $status -ne 0 ) { 
           
           send-mailmessage `
                                -SmtpServer $settings.settings.email.server `
                                -From $settings.settings.email.from `
                                -To $settings.settings.email.to `
                                -Subject $settings.settings.email.subjectLine `
                                -BODY 'DB restore failed'
           
           return 1}
            
            
       
            if ( $settings.settings.testmode -eq 1 ) { 
            $plinkcommand = "plink.exe $($settings.settings.ES.server) -i $($settings.settings.ES.privatekey) -l $($settings.settings.ES.userid) ls "
            write-host 'Start ES. here is plink': $plinkcommand
            }  else {         
                 $plinkcommand = "plink.exe $(settings.settings.ES.server) -i $($settings.settings.ES.privatekey) -l $($settings.settings.ES.userid) /home/elasticsearch/tools/aws_restore.sh"
                 }
            
            $msg = Invoke-Expression $plinkcommand
            write-host 'ES index refresh message: ': $msg
             if ( $msg -eq 'success' ) {   
             write-host 'success'
              } else {
                        $msg = 'ES failed: ' + $msg 
                        send-mailmessage `
                                -SmtpServer $settings.settings.email.server `
                                -From $settings.settings.email.from `
                                -To $settings.settings.email.to `
                                -Subject $settings.settings.email.subjectLine `
                                -BODY $msg
                           
                        return 1
                    }

        }
    catch [System.Exception] {
    
                        $explanationMessage = "Error occured. `n$_`n`n`nError at line: " +
                        $_.InvocationInfo.ScriptLineNumber + "`n" +
                        $_.InvocationInfo.line
                        write-host $explanationMessage 
                        send-mailmessage `
                                -SmtpServer $settings.settings.email.server `
                                -From $settings.settings.email.from `
                                -To $settings.settings.email.to `
                                -Subject $settings.settings.email.subjectLine `
                                -BODY $explanationMessage
                        
    }
}


Main








 

