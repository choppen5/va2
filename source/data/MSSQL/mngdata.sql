insert system_msg (system_msg_id,type,message) values (1,1,60)
go
update system_msg set message = 30

insert sft_error_defs (error_defs_id,search_string) values (1,'Iteration:')

insert sft_error_defs (error_defs_id,search_string) values (2,'Sleeping')
update sft_error_defs set template = 'N' where error_defs_id = 2;
update sft_error_defs set anded = 'N' where error_defs_id = 2;
update sft_error_defs set errorlevel = '3' where error_defs_id = 2;
update sft_error_defs set search_string = 'Sleeping' where error_defs_id = 2;
update sft_error_defs set evt_type = 'trivial',evt_error_level = 3 

insert comp_errdef (components_id,error_defs_id) values (1,1)


insert comp_errdef values (4,1)
insert comp_errdef values (4,2)


insert schedule (schedule_id,schedule_every) values (1,'Y')

insert administrators (administrators_id,first_name,last_name,email,phone,default_admin,schedule_id) values (1,'Charles','Oppenheimer','choppen5@yahoo.com','415-577-3411','Y',1)

insert comunicationserver (com_server_id,smtp_server) values (1,'localhost')
update comunicationserver set name = 'recursive_tech',type ='smtp'

insert com_srvr_vals (com_srvr_vals_id,type,elmnt_key,elmnt_value) values (1,'smtp','smtp_server','localhost')
/*insert com_srvr_vals (com_srvr_vals_id,type,elmnt_key,elmnt_value) values (1,'smtp','user_name','choppen5')*/
 

insert com_admin (administrators_id,com_server_id) values (1,1)
insert notification_rule (note_rule_id, message,notify_all,active) values (1,"Generic Message - sent with all events",'Y','Y')
update schedule set hour_start = '8', minute_start = '00',hour_end = '17', minute_end = '00'


insert into reaction_grp (reaction_grp_id,name) values (1,"generic reactions")
update notification_rule set reaction_grp_id = 1

insert into reaction (reaction_id,type,name,rule_def,reaction_grp_id) values (1,2,"run notepad","exec 'notepad';",1)
go
insert into analysis_rule (analysis_rule_id,type,rule_def,name,active) values (34,2,"if ($entobj->isenttaskrunning('TxnRoute')) {$retval = 1}",'IsTxnrouterRunning?','Y')
go
insert into analysis_err (analysis_err_id,evt_event_string,evt_sft_elmnt_id,analysis_rule_id) values (1,"Transaciton Router Not Running in the Enterprise",3,34)
GO
insert collector(collector_id,type,rule_def,name,active) values (1,1,"$retval = vadmin::sqlanalyze->sqlcount($sqlstatement,$datasession);",'ERROR COUNT','Y')
GO
 