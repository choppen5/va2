If you want to send an event to VA2 from a custom application, it is a relatively simple procedure.  

1. Find the address of your central server.  This was decided on install.  Use a host name or IP address.
2. Find the port of your CCPORT

3.  write an application that can send message to the following URL

http://yourserver:yourport/RPC2


4. The following XML is an example of the required XML fields.  The method name is errorinsert.


5. The following pramaters are availible....almost all are optional.  Create a date string for your events with the  mm/dd/yyy hh24:MM:SS format.

 Paramaters:  $sft_elmnt_id,$server,$event_string,$usr_event_level,$usr_event_type,$usr_event_sub_type,$event_time,$error_defs_id,$cc_alias,$host,$analysis_rule_id


7. Example:



<?xml version="1.0"?>
<methodCall>
<methodName>errorinsert</methodName>
<params>
<param><value><string></string></value></param>
<param><value><string></string></value></param>
<param><value><string>LOW DISK SPACE ON C: -  Percentage free = 0.068728086902913
</string></value></param>
<param><value><i4>0</i4></value></param>
<param><value><string>DiskSpaceLow</string></value></param>
<param><value><string>K6Z7E4</string></value></param>
<param><value><string>7/18/2003 18:56:6</string></value></param>
<param><value><i4>4</i4></value></param>
<param><value><string></string></value></param>
<param><value><string></string></value></param>
<param><value><i4>1</i4></value></param>
</params>
</methodCall>

