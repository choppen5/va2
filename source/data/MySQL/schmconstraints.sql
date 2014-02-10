#
# Project: DDS Project
# Author : Charles Oppenheimer
# Date   : Apr 16 2006 21:20
# File auto-generated by Database Design Studio V1.09.2
#
#
# Target DBMS: 'MySQL'
#
 
 
create database constraints;
 
#
# select the database
#
use constraints;
 
 
#
# Table               : errorevent
# Description         : popultated as result of error deff conditions or  - via XML interface or ODBC
# errorevent_id       : 
# type                : 
# event_sub_type      : 
# event_level         : 
# event_time          : 
# event_string        : 
# status              : 
# error_defs_id       : 
# cc_alias            : 
# sv_name             : 
# sft_elmnt_id        : 
# processed           : 
# reactionfired       : 
# host                : host where error occured 
# analysis_rule_id    : 
# note_rule_id        : 
# error_def_id        : 
# notimeout           : 
#
create table errorevent (
    errorevent_id   int not null,
    type            char(50),
    event_sub_type  char(50),
    event_level     char(20),
    event_time      datetime,
    event_string    char(254),
    status          char(10),
    error_defs_id   int,
    cc_alias        char(50),
    sv_name         char(50),
    sft_elmnt_id    int,
    processed       char(1),
    reactionfired   char(1),
    host            char(50),
    analysis_rule_id int,
    note_rule_id    int,
    error_def_id    int,
    notimeout       char(1),
primary key (errorevent_id));
 
 
 
#
# Table               : notification_rule
# Description         : rules for monitoring error event table - conditions will be "anded" - will send messages to communication server
# note_rule_id        : shorted to avaoid trucation 
# name                : user name for notification rule 
# message             : not a condition 
# notify_all          : 
# incl_ev_string      : 
# inc_ev_level        : 
# inc_ev_subtype      : 
# type                : 
# status              : 
# active              : 
# ev_sft_elmnt_id     : anded foriegn key to application table 
# ev_event_sub_type   : anded 
# ev_event_level      : anded 
# ev_event_time       : anded 
# ev_event_string     : anded - regexp 
# ev_type             : 
#
create table notification_rule (
    note_rule_id    int not null,
    name            char(30),
    message         char(245) not null,
    notify_all      char(1),
    incl_ev_string  char(1),
    inc_ev_level    char(50),
    inc_ev_subtype  char(1),
    type            char(50),
    status          char(10),
    active          char(1),
    ev_sft_elmnt_id int,
    ev_event_sub_type char(50),
    ev_event_level  int,
    ev_event_time   char(50),
    ev_event_string char(254),
    ev_type         char(20),
primary key (note_rule_id));
 
 
 
#
# Table               : host
# Description         : machine specific info
# host_id             : 
# hostname            : 
# ipaddress           : 
# os                  : 
# status              : 
# username            : 
# password            : 
# check_interval      : 
# no_ping             : 
#
create table host (
    host_id         int not null,
    hostname        char(50),
    ipaddress       char(50),
    os              char(50),
    status          char(20),
    username        char(100),
    password        char(100),
    check_interval  int,
    no_ping         char(1),
primary key (host_id));
 
 
 
#
# Table               : schedule
# Description         : first draft
# schedule_id         : 
# schedule_every      : overides all hour minutes specs 
# monday              : 
# tuesday             : 
# wednesday           : 
# thursday            : 
# friday              : 
# saturday            : 
# sunday              : 
# every_day           : overides daily columns 
# hour_start          : 24 
# minute_start        : 60 
# hour_end            : 60 
# minute_end          : 
# every_hour          : overides hour/minutes 
# schd_name           : 
# start_time          : 
# end_time            : 
#
create table schedule (
    schedule_id     int not null,
    schedule_every  varchar(1),
    monday          varchar(1),
    tuesday         varchar(1),
    wednesday       varchar(1),
    thursday        varchar(1),
    friday          varchar(1),
    saturday        varchar(1),
    sunday          varchar(1),
    every_day       varchar(1),
    hour_start      varchar(2),
    minute_start    varchar(2),
    hour_end        varchar(2),
    minute_end      varchar(2),
    every_hour      varchar(1),
    schd_name       varchar(50),
    start_time      time,
    end_time        time,
primary key (schedule_id));
 
 
 
#
# Table               : comunicationserver
# Description         : 
# com_server_id       : truncated from comunicationserver_id 
# smtp_server         : 
# webserver           : for future use 
# paging_server       : futureuse 
# modemnumber         : future use 
# type                : 
# active              : 
# name                : 
#
create table comunicationserver (
    com_server_id   int not null,
    smtp_server     char(50),
    webserver       char(50),
    paging_server   char(50),
    modemnumber     char(50),
    type            char(20),
    active          char(1),
    name            char(50),
primary key (com_server_id));
 
 
 
#
# Table               : system_msg
# Description         : 
# system_msg_id       : 
# type                : 
# message             : 
# host                : 
# app_server          : 
# processesed         : 
#
create table system_msg (
    system_msg_id   int not null,
    type            varchar(50),
    message         varchar(50),
    host            char(50),
    app_server      char(50),
    processesed     char(1),
primary key (system_msg_id));
 
 
 
#
# Table               : analysis_rule
# Description         : deffinition for a executible system check
# analysis_rule_id    : 
# type                : 
# rule_def            : definition -sql, wmi, perl, etc 
# error               : error message displayed if rule unexecutible 
# name                : 
# sf_error_deff_id    : 
# active              : 
# execution_interval  : 
# description         : 
# notimeout           : 
#
create table analysis_rule (
    analysis_rule_id int not null,
    type            char(10),
    rule_def        varchar(4000),
    error           char(254),
    name            char(100),
    sf_error_deff_id int,
    active          char(1),
    execution_interval varchar(10),
    description     char(100),
    notimeout       char(1),
primary key (analysis_rule_id));
 
 
 
#
# Table               : reaction
# Description         : deffinition for a executible system check
# reaction_id         : 
# type                : 
# rule_def            : definition -sql, wmi, perl, etc 
# error               : error message displayed if rule unexecutible 
# name                : 
# host_specific       : if true, execute reaction on host of error,otherwise central 
# active              : 
# sv_name             : 
#
create table reaction (
    reaction_id     int not null,
    type            char(10),
    rule_def        varchar(2000),
    error           char(100),
    name            char(20),
    host_specific   char(50),
    active          char(1),
    sv_name         char(50),
primary key (reaction_id));
 
 
 
#
# Table               : collector
# Description         : script/sql to collect non internal statistics
# collector_id        : 
# type                : 
# rule_def            : definition -sql, wmi, perl, etc 
# error               : error message displayed if rule unexecutible 
# name                : 
# odbc                : 
# active              : 
# sft_elmnt_id        : 
# host_id             : host a collector is associated with 
# description         : description of the statistic 
# execution_interval  : 
# max_records         : 
# notimeout           : 
# parent_sft_elmnt_id : 
# parent_collector_id : 
# archive_field       : 
# archive_interval    : 
# archive_description : reserved for future use 
#
create table collector (
    collector_id    int not null,
    type            char(10),
    rule_def        varchar(4000),
    error           varchar(254),
    name            char(100),
    odbc            char(50),
    active          char(1),
    sft_elmnt_id    varchar(10),
    host_id         varchar(10),
    description     char(100),
    execution_interval int,
    max_records     int,
    notimeout       char(1),
    parent_sft_elmnt_id int,
    parent_collector_id int,
    archive_field   char(1),
    archive_interval char(1),
    archive_description char(50),
primary key (collector_id));
 
 
 
#
# Table               : sft_mng_sys
# Description         : 
# sft_mng_sys_id      : 
# name                : 
# status              : 
# state               : 
# type                : 
#
create table sft_mng_sys (
    sft_mng_sys_id  int not null,
    name            char(50),
    status          char(20),
    state           char(20),
    type            varchar(50),
primary key (sft_mng_sys_id));
 
 
 
#
# Table               : sft_error_defs
# Description         : string errors and messages will be configured per component/appserver
# error_defs_id       : 
# ev_type             : 
# ev_level            : 
# ev_time             : 
# search_string       : 
# ev_sub_type         : 
# host                : 
# name                : Name of Error Deffinition 
# sv_name             : 
# cc_alias            : 
# sf_elmnt_id         : 
# active              : 
# type                : type of error definition 
#
create table sft_error_defs (
    error_defs_id   int not null,
    ev_type         char(50),
    ev_level        char(50),
    ev_time         char(50),
    search_string   char(254),
    ev_sub_type     char(50),
    host            char(254),
    name            char(50),
    sv_name         char(50),
    cc_alias        char(50),
    sf_elmnt_id     char(50),
    active          char(1),
    type            char(10),
primary key (error_defs_id));
 
 
 
#
# Table               : server_task
# Description         : related to sft_elment (for all tasks per app server) or components and monitored_comps , (all task per component)
# server_task_id      : 
# sv_name             : 
# cc_alias            : 
# tk_taskid           : 
# tk_pid              : 
# tk_disp_runstate    : 
# cc_runmode          : 
# tk_start_time       : 
# tk_end_time         : 
# tk_status           : 
# cg_alias            : 
# sft_elmnt_id        : 
# sft_elmnt_comp_id   : 
# tk_parent_t         : 
# cc_incarn_no        : 
# tk_label            : 
# tk_tasktype         : 
#
create table server_task (
    server_task_id  int not null,
    sv_name         char(100),
    cc_alias        char(100),
    tk_taskid       int,
    tk_pid          int,
    tk_disp_runstate char(100),
    cc_runmode      char(100),
    tk_start_time   char(50),
    tk_end_time     char(50),
    tk_status       char(254),
    cg_alias        char(100),
    sft_elmnt_id    int,
    sft_elmnt_comp_id int,
    tk_parent_t     char(50),
    cc_incarn_no    char(50),
    tk_label        char(50),
    tk_tasktype     char(50),
primary key (server_task_id));
 
 
 
#
# Table               : monitored_comps
# Description         : represents all components per app server being monitored
# monitored_comps_id  : 
# sv_name             : 
# cp_max_mts          : 
# cc_name             : use this key to show running components per component deff 
# ct_alias            : 
# cg_name             : 
# cc_runmode          : 
# cp_disp_run_state   : 
# cp_num_run          : 
# cp_max_tas          : 
# cp_actv_mt          : 
# cc_alias            : 
# cp_start_time       : 
# cp_end_time         : 
# cp_status           : 
# sft_elmnt_id        : 
# sft_elmnt_comp_id   : 
#
create table monitored_comps (
    monitored_comps_id int not null,
    sv_name         char(50),
    cp_max_mts      varchar(10),
    cc_name         char(100),
    ct_alias        char(100),
    cg_name         char(50),
    cc_runmode      char(50),
    cp_disp_run_state char(50),
    cp_num_run      varchar(10),
    cp_max_tas      varchar(10),
    cp_actv_mt      varchar(10),
    cc_alias        char(50),
    cp_start_time   char(50),
    cp_end_time     char(50),
    cp_status       char(50),
    sft_elmnt_id    int,
    sft_elmnt_comp_id char(50),
primary key (monitored_comps_id));
 
 
 
#
# Table               : processes
# Description         : related to the app server via sft_enlmnt_id, aslo to component or task via cc_name or ct_name,respectively
# process_id          : 
# sv_name             : 
# task_id             : 
# pid                 : 
# cc_alias            : 
# cc_name             : 
# host                : 
# state               : 
# process             : 
# cpu                 : 
# cpu_time            : 
# memory              : 
# pagefaults          : 
# virtualmem          : 
# priority            : 
# threads             : 
# sft_elmnt_id        : 
# sft_elmnt_comp_id   : 
# kernel_time         : 
# user_time           : 
#
create table processes (
    process_id      int not null,
    sv_name         char(50),
    task_id         char(10),
    pid             varchar(10),
    cc_alias        char(50),
    cc_name         char(100),
    host            char(50),
    state           char(50),
    process         char(50),
    cpu             float(10),
    cpu_time        varchar(10),
    memory          int,
    pagefaults      int,
    virtualmem      int,
    priority        char(50),
    threads         varchar(10),
    sft_elmnt_id    varchar(10),
    sft_elmnt_comp_id varchar(10),
    kernel_time     varchar(10),
    user_time       varchar(10),
primary key (process_id));
 
 
 
#
# Table               : components
# Description         : will contain all Siebel default components, plus user definable components
# components_id       : 
# description         : 
# log_analyze         : 
# log_monitor         : 
# sft_elmnt_id        : 
# cc_alias            : 
#
create table components (
    components_id   int not null,
    description     char(100),
    log_analyze     char(1),
    log_monitor     char(1),
    sft_elmnt_id    int,
    cc_alias        char(80) not null,
primary key (components_id));
 
 
 
#
# Table               : analysis_err
# Description         : (reserved for future use) If the anlaysis object returns false, the error defined here will be inserted into error event table
# analysis_err_id     : 
# evt_type            : 
# evt_event_sub_type  : 
# evt_event_level     : 
# evt_event_time      : 
# evt_event_string    : 
# evt_status          : 
# evt_cc_alias        : 
# evt_sv_name         : 
# evt_sft_elmnt_id    : 
# evt_host            : 
# name                : 
#
create table analysis_err (
    analysis_err_id int not null,
    evt_type        char(10),
    evt_event_sub_type char(50),
    evt_event_level int,
    evt_event_time  char(50),
    evt_event_string char(254),
    evt_status      char(50),
    evt_cc_alias    char(50),
    evt_sv_name     char(50),
    evt_sft_elmnt_id int,
    evt_host        char(254),
    name            char(50),
primary key (analysis_err_id));
 
 
 
#
# Table               : tableids
# Description         : 
# table_name          : 
# id                  : 
#
create table tableids (
    table_name      char(50) not null,
    id              int not null,
primary key (table_name));
 
 
 
#
# Table               : data_source
# Description         : 
# data_source_id      : 
# name                : 
# username            : 
# password            : 
# host                : 
# alias               : alias name for ODBC 
#
create table data_source (
    data_source_id  int not null,
    name            char(50),
    username        char(50),
    password        char(50),
    host            char(50),
    alias           char(50) not null,
primary key (data_source_id, alias));
 
 
 
#
# Table               : resonate_ar
# Description         : Resonate table for Agent Rules
# resonate_id         : 
# sft_elmnt_id        : join to parent sft_elment 
# service             : object manager - such as eaiobjmgr 
# service_host        : usually an IP address 
# type                : 
# rule_number         : list the number of rules for service host combo 
#
create table resonate_ar (
    resonate_id     int not null,
    sft_elmnt_id    int,
    service         char(50),
    service_host    char(50),
    type            char(50),
    rule_number     int,
primary key (resonate_id));
 
 
 
#
# Table               : sessions
# Description         : related to sft_elment (for all tasks per app server) or components and monitored_comps , (all task per component)
# sessions_id         : 
# sv_name             : 
# cc_alias            : 
# cg_alias            : 
# tk_taskid           : 
# tk_pid              : 
# tk_disp_runstate    : 
# tk_idle_state       : 
# tk_ping_tim         : 
# tk_hung_state       : 
# om_login            : 
# om_bussvc           : 
# om_view             : 
# om_applet           : 
# om_buscomp          : 
# sft_elmnt_id        : 
#
create table sessions (
    sessions_id     int not null,
    sv_name         char(50),
    cc_alias        char(100),
    cg_alias        char(100),
    tk_taskid       int,
    tk_pid          int,
    tk_disp_runstate char(20),
    tk_idle_state   char(20),
    tk_ping_tim     char(20),
    tk_hung_state   char(20) not null,
    om_login        char(30),
    om_bussvc       char(100),
    om_view         char(100),
    om_applet       char(100),
    om_buscomp      char(100),
    sft_elmnt_id    int,
primary key (sessions_id));
 
 
 
#
# Table               : administrators
# Description         : persons with email address 
# administrators_id   : 
# first_name          : 
# last_name           : 
# password            : 
# email               : 
# phone               : 
# pager               : 
# default_admin       : 
# user_name           : 
# schedule_id         : (Foreign Key
#                        references SCHEDULE.schedule_id)
#
create table administrators (
    administrators_id int not null,
    first_name      char(50),
    last_name       char(50),
    password        char(50),
    email           char(70),
    phone           char(50),
    pager           char(50),
    default_admin   char(1),
    user_name       char(50),
    schedule_id     int,
primary key (administrators_id),
foreign key (schedule_id) references schedule (schedule_id)
        on delete set null
        on update cascade);
 
 
 
#
# Table               : errorexceptions
# Description         : ignore errors based on time/date or string
# errorexceptions_id  : 
# errorexception      : 
# time_exemption      : ignore errors before this date 
# err_type_exept      : 
# note_rule_id        : shorted to avaoid trucation (Foreign Key
#                        references NOTIFICATION_RULE.note_rule_id)
#
create table errorexceptions (
    errorexceptions_id char(10) not null,
    errorexception  char(254),
    time_exemption  datetime,
    err_type_exept  char(10),
    note_rule_id    int,
primary key (errorexceptions_id),
foreign key (note_rule_id) references notification_rule (note_rule_id)
        on delete set null
        on update cascade);
 
 
 
#
# Table               : host_os_stats
# Description         : machine specific info
# db_id               : 
# running_since       : 
# status              : 
# memory_consuption   : 
# cpu_utilization     : 
# time_stamp          : 
# host_id             : (Foreign Key
#                        references HOST.host_id)
#
create table host_os_stats (
    db_id           char(10) not null,
    running_since   datetime,
    status          char(10),
    memory_consuption char(50),
    cpu_utilization char(50),
    time_stamp      datetime,
    host_id         int,
primary key (db_id),
foreign key (host_id) references host (host_id)
        on delete set null
        on update cascade);
 
 
 
#
# Table               : com_admin
# Description         : 
# com_server_id       : truncated from comunicationserver_id (Foreign Key
#                        references COMUNICATIONSERVER.com_server_id)
# administrators_id   : (Foreign Key
#                        references ADMINISTRATORS.administrators_id)
#
create table com_admin (
    com_server_id   int not null,
    administrators_id int not null,
primary key (com_server_id, administrators_id),
foreign key (com_server_id) references comunicationserver (com_server_id)
        on delete cascade
        on update cascade,
foreign key (administrators_id) references administrators (administrators_id)
        on delete restrict
        on update cascade);
 
 
 
#
# Table               : stat_vals
# Description         : values populated as result of stat_defs
# stat_vals_id        : 
# val                 : 
# time_stmp           : 
# collector_id        : (Foreign Key
#                        references COLLECTOR.collector_id)
#
create table stat_vals (
    stat_vals_id    int not null,
    val             float(20) not null,
    time_stmp       datetime not null,
    collector_id    int,
primary key (stat_vals_id),
foreign key (collector_id) references collector (collector_id)
        on delete set null
        on update cascade);
 
 
 
#
# Table               : sft_elmnt
# Description         : 
# sft_elmnt_id        : 
# type                : 
# description         : 
# name                : 
# os                  : 
# host                : 
# installdir          : 
# status              : 
# exe                 : 
# service_name        : 
# parent_elmnt_id     : 
# logdir              : 
# monitor_service     : 
# restart_service     : 
# send_event          : send event on service failure 
# port                : 
# mon_interval        : 
# sft_mng_sys_id      : (Foreign Key
#                        references SFT_MNG_SYS.sft_mng_sys_id)
#
create table sft_elmnt (
    sft_elmnt_id    int not null,
    type            char(20),
    description     char(50),
    name            char(50),
    os              char(20),
    host            char(50),
    installdir      char(254),
    status          char(20),
    exe             char(50),
    service_name    char(50),
    parent_elmnt_id int,
    logdir          char(254),
    monitor_service char(1),
    restart_service char(1),
    send_event      char(1),
    port            double precision(5),
    mon_interval    int,
    sft_mng_sys_id  int,
primary key (sft_elmnt_id),
foreign key (sft_mng_sys_id) references sft_mng_sys (sft_mng_sys_id)
        on delete set null
        on update cascade);
 
 
 
#
# Table               : sft_elmnt_comp
# Description         : key value description of component
# sft_elmnt_comp_id   : 
# type                : 
# elmnt_key           : 
# elmnt_value         : 
# status              : 
# sft_elmnt_id        : (Foreign Key
#                        references SFT_ELMNT.sft_elmnt_id)
#
create table sft_elmnt_comp (
    sft_elmnt_comp_id int not null,
    type            char(20),
    elmnt_key       char(50) not null,
    elmnt_value     char(254) not null,
    status          char(20),
    sft_elmnt_id    int,
primary key (sft_elmnt_comp_id),
foreign key (sft_elmnt_id) references sft_elmnt (sft_elmnt_id)
        on delete set null
        on update cascade);
 
 
 
#
# Table               : comp_errdef
# Description         : 
# components_id       : (Foreign Key
#                        references COMPONENTS.components_id)
# error_defs_id       : (Foreign Key
#                        references SFT_ERROR_DEFS.error_defs_id)
#
create table comp_errdef (
    components_id   int not null,
    error_defs_id   int not null,
primary key (components_id, error_defs_id),
foreign key (components_id) references components (components_id)
        on delete cascade
        on update cascade,
foreign key (error_defs_id) references sft_error_defs (error_defs_id)
        on delete cascade
        on update cascade);
 
 
 
#
# Table               : com_srvr_vals
# Description         : key value description of component
# com_srvr_vals_id    : 
# type                : 
# elmnt_key           : 
# elmnt_value         : 
# status              : 
# com_server_id       : truncated from comunicationserver_id (Foreign Key
#                        references COMUNICATIONSERVER.com_server_id)
#
create table com_srvr_vals (
    com_srvr_vals_id int not null,
    type            char(20),
    elmnt_key       char(50) not null,
    elmnt_value     char(254) not null,
    status          char(20),
    com_server_id   int,
primary key (com_srvr_vals_id),
foreign key (com_server_id) references comunicationserver (com_server_id)
        on delete set null
        on update cascade);
 
 
 
#
# Table               : notification_reaction
# Description         : 
# note_rule_id        : shorted to avaoid trucation (Foreign Key
#                        references NOTIFICATION_RULE.note_rule_id)
# reaction_id         : (Foreign Key
#                        references REACTION.reaction_id)
#
create table notification_reaction (
    note_rule_id    int not null,
    reaction_id     int not null,
primary key (note_rule_id, reaction_id),
foreign key (note_rule_id) references notification_rule (note_rule_id)
        on delete cascade
        on update cascade,
foreign key (reaction_id) references reaction (reaction_id)
        on delete restrict
        on update cascade);
 
 
 
#
# Table               : analysis_errdef
# Description         : 
# analysis_rule_id    : (Foreign Key
#                        references ANALYSIS_RULE.analysis_rule_id)
# error_defs_id       : (Foreign Key
#                        references SFT_ERROR_DEFS.error_defs_id)
#
create table analysis_errdef (
    analysis_rule_id int not null,
    error_defs_id   int not null,
primary key (analysis_rule_id, error_defs_id),
foreign key (analysis_rule_id) references analysis_rule (analysis_rule_id)
        on delete cascade
        on update cascade,
foreign key (error_defs_id) references sft_error_defs (error_defs_id)
        on delete cascade
        on update cascade);
 
 
 
#
# Table               : sft_err_deff
# Description         : 
# sft_elmnt_id        : (Foreign Key
#                        references SFT_ELMNT.sft_elmnt_id)
# error_defs_id       : (Foreign Key
#                        references SFT_ERROR_DEFS.error_defs_id)
#
create table sft_err_deff (
    sft_elmnt_id    int not null,
    error_defs_id   int not null,
primary key (sft_elmnt_id, error_defs_id),
foreign key (sft_elmnt_id) references sft_elmnt (sft_elmnt_id)
        on delete cascade
        on update cascade,
foreign key (error_defs_id) references sft_error_defs (error_defs_id)
        on delete cascade
        on update cascade);
 
 
 
 
 
