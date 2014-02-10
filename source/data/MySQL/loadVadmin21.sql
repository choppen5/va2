#
# Load Tables
#
#
# Target DBMS: 'MySQL'
#
 
#
# select the database
#
use vadmin21;
 
 
#
# Load Table          : errorevent
#
load data
infile 'errorevent.txt' 
into table errorevent
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
 
#
# Load Table          : notification_rule
#
load data
infile 'notification_rule.txt' 
into table notification_rule
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
 
#
# Load Table          : host
#
load data
infile 'host.txt' 
into table host
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
 
#
# Load Table          : schedule
#
load data
infile 'schedule.txt' 
into table schedule
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
 
#
# Load Table          : comunicationserver
#
load data
infile 'comunicationserver.txt' 
into table comunicationserver
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
 
#
# Load Table          : system_msg
#
load data
infile 'system_msg.txt' 
into table system_msg
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
 
#
# Load Table          : analysis_rule
#
load data
infile 'analysis_rule.txt' 
into table analysis_rule
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
 
#
# Load Table          : reaction
#
load data
infile 'reaction.txt' 
into table reaction
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
 
#
# Load Table          : collector
#
load data
infile 'collector.txt' 
into table collector
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
 
#
# Load Table          : sft_mng_sys
#
load data
infile 'sft_mng_sys.txt' 
into table sft_mng_sys
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
 
#
# Load Table          : sft_error_defs
#
load data
infile 'sft_error_defs.txt' 
into table sft_error_defs
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
 
#
# Load Table          : server_task
#
load data
infile 'server_task.txt' 
into table server_task
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
 
#
# Load Table          : monitored_comps
#
load data
infile 'monitored_comps.txt' 
into table monitored_comps
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
 
#
# Load Table          : processes
#
load data
infile 'processes.txt' 
into table processes
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
 
#
# Load Table          : components
#
load data
infile 'components.txt' 
into table components
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
 
#
# Load Table          : analysis_err
#
load data
infile 'analysis_err.txt' 
into table analysis_err
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
 
#
# Load Table          : tableids
#
load data
infile 'tableids.txt' 
into table tableids
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
 
#
# Load Table          : data_source
#
load data
infile 'data_source.txt' 
into table data_source
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
 
#
# Load Table          : resonate_ar
#
load data
infile 'resonate_ar.txt' 
into table resonate_ar
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
 
#
# Load Table          : administrators
#
load data
infile 'administrators.txt' 
into table administrators
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
 
#
# Load Table          : errorexceptions
#
load data
infile 'errorexceptions.txt' 
into table errorexceptions
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
 
#
# Load Table          : host_os_stats
#
load data
infile 'host_os_stats.txt' 
into table host_os_stats
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
 
#
# Load Table          : com_admin
#
load data
infile 'com_admin.txt' 
into table com_admin
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
 
#
# Load Table          : stat_vals
#
load data
infile 'stat_vals.txt' 
into table stat_vals
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
 
#
# Load Table          : sft_elmnt
#
load data
infile 'sft_elmnt.txt' 
into table sft_elmnt
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
 
#
# Load Table          : sft_elmnt_comp
#
load data
infile 'sft_elmnt_comp.txt' 
into table sft_elmnt_comp
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
 
#
# Load Table          : comp_errdef
#
load data
infile 'comp_errdef.txt' 
into table comp_errdef
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
 
#
# Load Table          : com_srvr_vals
#
load data
infile 'com_srvr_vals.txt' 
into table com_srvr_vals
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
 
#
# Load Table          : notification_reaction
#
load data
infile 'notification_reactio.txt' 
into table notification_reaction
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
 
#
# Load Table          : analysis_errdef
#
load data
infile 'analysis_errdef.txt' 
into table analysis_errdef
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
 
#
# Load Table          : sft_err_deff
#
load data
infile 'sft_err_deff.txt' 
into table sft_err_deff
fields terminated by ',' optionally enclosed by '''
lines terminated by '\n';
 
