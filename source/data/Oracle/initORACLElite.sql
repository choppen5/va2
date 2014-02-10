

insert into sft_mng_sys(sft_mng_sys_id,name,type) values (1,'Virtual Administrator 2','VA2')

/

insert into system_msg (system_msg_id,type,message) values (1,1,'60')
/

insert into sft_error_defs (error_defs_id,name,search_string,ev_level,ev_type,ev_sub_type) values (1,'Component Reached max tasks','','','Components Maxed','')
/

insert into sft_error_defs (error_defs_id,name,search_string,ev_level,ev_type,ev_sub_type) values (2,'Transaction Backlog','','','Transaction Backlog','')
/

insert into sft_error_defs (error_defs_id,name,search_string,ev_level,ev_type,ev_sub_type) values (3,'Process or Component exited with Error','Process exited with error','','Process exited with error','')
/


insert into notification_rule (note_rule_id,name, message,notify_all,active,type,ev_event_sub_type,ev_event_level,ev_event_string) values (1,'Siebel Component Maxed','1 or More Siebel Component has reached Max Tasks','N','Y','Components Maxed','','','')
/

insert into notification_rule (note_rule_id,name, message,notify_all,active,type,ev_event_sub_type,ev_event_level,ev_event_string) values (2,'Transaction Backlog','Warning!  Transaction Backlog detected','N','Y','Transacton Backlog','','','')
/

insert into notification_rule (note_rule_id,name, message,notify_all,active,type,ev_event_sub_type,ev_event_level,ev_event_string) values (3,'Siebel Proc Exited with Error!','Siebel Process exited with Error','N','Y','Process exited with error','','','')

/

commit
/