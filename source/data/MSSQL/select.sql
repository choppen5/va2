select * from sft_mng_sys

select * from sft_product where sft_mng_sys_id = 1

select * from sft_elmnt where sft_product_id = 1 and parent_elmnt_id is null
select * from sft_elmnt where sft_product_id = 1 and parent_elmnt_id = 1
select * from sft_elmnt where sft_product_id = 1 and parent_elmnt_id = 2
select t1.sft_elmnt_comp_id,t1.type,t1.elmnt_key,t1.elmnt_value from sft_elmnt_comp t1,sft_elmnt t2 where t2.sft_elmnt_id = t1.sft_elmnt_id and t1.sft_elmnt_id = 3 and t2.sft_product_id = 1
select t1.sft_sub_elmnt_id,t1.elmnt_key,t1.elmnt_value from sft_sub_elmnt t1, sft_elmnt_comp t2,sft_elmnt t3 where t3.sft_elmnt_id = t2.sft_elmnt_id and t1.sft_elmnt_comp_id = t2.sft_elmnt_comp_id and  t1.sft_elmnt_comp_id = 4  and t3.sft_product_id = 1
select t1.sft_sub_elmnt_id,t1.elmnt_key,t1.elmnt_value from sft_sub_elmnt t1, sft_elmnt_comp t2,sft_elmnt t3 where t3.sft_elmnt_id = t2.sft_elmnt_id and t1.sft_elmnt_comp_id = t2.sft_elmnt_comp_id and  t1.sft_elmnt_comp_id = 5  and t3.sft_product_id = 1

select * from monitored_comps

select * from server_task

select * from processes

select name from sft_elmnt where type = 'appserver' and host = 'NOTEBOOK'

select * from errorevent where processed is NULL or processed != 'Y'

select * from notification_rule where active = 'Y'

update notification_rule set ev_event_sub_type  = 'test'
update errorevent set event_sub_type = 'test'

	
