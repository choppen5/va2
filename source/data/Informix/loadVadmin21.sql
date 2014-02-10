{
-- Load Tables
}
{
-- Target DBMS: 'Informix'
}
 
 
{
-- Load Table          : errorevent
}
file errorevent.unl delimeter "|" 14;
insert into errorevent;
 
 
{
-- Load Table          : host
}
file host.unl delimeter "|" 5;
insert into host;
 
 
{
-- Load Table          : schedule
}
file schedule.unl delimeter "|" 18;
insert into schedule;
 
 
{
-- Load Table          : comunicationserver
}
file comunicationserver.unl delimeter "|" 8;
insert into comunicationserver;
 
 
{
-- Load Table          : system_msg
}
file system_msg.unl delimeter "|" 6;
insert into system_msg;
 
 
{
-- Load Table          : analysis_rule
}
file analysis_rule.unl delimeter "|" 7;
insert into analysis_rule;
 
 
{
-- Load Table          : reaction_grp
}
file reaction_grp.unl delimeter "|" 3;
insert into reaction_grp;
 
 
{
-- Load Table          : collector
}
file collector.unl delimeter "|" 10;
insert into collector;
 
 
{
-- Load Table          : sft_mng_sys
}
file sft_mng_sys.unl delimeter "|" 4;
insert into sft_mng_sys;
 
 
{
-- Load Table          : sft_error_defs
}
file sft_error_defs.unl delimeter "|" 13;
insert into sft_error_defs;
 
 
{
-- Load Table          : server_task
}
file server_task.unl delimeter "|" 13;
insert into server_task;
 
 
{
-- Load Table          : monitored_comps
}
file monitored_comps.unl delimeter "|" 17;
insert into monitored_comps;
 
 
{
-- Load Table          : processes
}
file processes.unl delimeter "|" 18;
insert into processes;
 
 
{
-- Load Table          : components
}
file components.unl delimeter "|" 6;
insert into components;
 
 
{
-- Load Table          : tableids
}
file tableids.unl delimeter "|" 2;
insert into tableids;
 
 
{
-- Load Table          : administrators
}
file administrators.unl delimeter "|" 10;
insert into administrators;
 
 
{
-- Load Table          : notification_rule
}
file notification_rule.unl delimeter "|" 17;
insert into notification_rule;
 
 
{
-- Load Table          : errorexceptions
}
file errorexceptions.unl delimeter "|" 5;
insert into errorexceptions;
 
 
{
-- Load Table          : host_os_stats
}
file host_os_stats.unl delimeter "|" 7;
insert into host_os_stats;
 
 
{
-- Load Table          : com_admin
}
file com_admin.unl delimeter "|" 2;
insert into com_admin;
 
 
{
-- Load Table          : reaction
}
file reaction.unl delimeter "|" 10;
insert into reaction;
 
 
{
-- Load Table          : stat_vals
}
file stat_vals.unl delimeter "|" 4;
insert into stat_vals;
 
 
{
-- Load Table          : sft_product
}
file sft_product.unl delimeter "|" 6;
insert into sft_product;
 
 
{
-- Load Table          : sft_elmnt
}
file sft_elmnt.unl delimeter "|" 12;
insert into sft_elmnt;
 
 
{
-- Load Table          : sft_elmnt_comp
}
file sft_elmnt_comp.unl delimeter "|" 6;
insert into sft_elmnt_comp;
 
 
{
-- Load Table          : sft_err_deff
}
file sft_err_deff.unl delimeter "|" 7;
insert into sft_err_deff;
 
 
{
-- Load Table          : comp_errdef
}
file comp_errdef.unl delimeter "|" 2;
insert into comp_errdef;
 
 
{
-- Load Table          : com_srvr_vals
}
file com_srvr_vals.unl delimeter "|" 6;
insert into com_srvr_vals;
 
 
{
-- Load Table          : analysis_err
}
file analysis_err.unl delimeter "|" 13;
insert into analysis_err;
 
 
{
-- Load Table          : sft_sub_elmnt
}
file sft_sub_elmnt.unl delimeter "|" 5;
insert into sft_sub_elmnt;
 
