
/*


•AT&T: number@txt.att.net[1] for a normal text message (SMS), or number@mms.att.net[2] for a multimedia message (MMS)
•Verizon: number@vtext.com[3] for both SMS and MMS messages
•Sprint PCS: number@messaging.sprintpcs.com for both SMS and MMS messages
•T-Mobile: number@tmomail.net for both SMS and MMS messages
•Virgin Mobile: number@vmobl.com[4] for both SMS and MMS messages
•These gateways do change periodically, and are not always published for non-subscribers. For a comprehensive and up-to-date list of current gateway addresses and the format to use for various phone companies around the world, visit http://martinfitzpatrick.name/list-of-email-to-sms-gateways 
*/



/*
EXEC msdb.dbo.sp_send_dbmail   
  @recipients= '5555555555@txt.att.net'
  ,@subject = 'Test'  
  ,@body = 'Test'
  ,@body_format = 'TEXT';  
*/  
  