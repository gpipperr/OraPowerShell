--
-- see http://docs.oracle.com/cd/E11882_01/appdev.112/e40758/d_monitor.htm#ARPLS67176
--
-- session_id 	Database Session Identifier for which SQL trace is disabled
-- serial_num 	Serial number for this session
--



begin
dbms_monitor.session_trace_disable(
   session_id      => null,
   serial_num      => null);
end;
/