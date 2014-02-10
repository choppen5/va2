

create table errorevent (
    errorevent_id   int not null,
    type            char(50),
    event_sub_type  char(50),
    event_level     char(20),
    event_time      char(50),
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
 primary key  (errorevent_id));
 
 commit;
 
 
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
primary key  (note_rule_id));

commit;
 

create table host (
    host_id         int not null,
    hostname        char(50),
    ipaddress       char(50),
    os              char(50),
    status          char(20),
    username        char(100),
    password        char(100),
    check_interval  int,
  primary key (host_id));
 
commit;
 
 

create table schedule (
    schedule_id     int not null,
    schedule_every  char(1),
    monday          char(1),
    tuesday         char(1),
    wednesday       char(1),
    thursday        char(1),
    friday          char(1),
    saturday        char(1),
    sunday          char(1),
    every_day       char(1),
    hour_start      char(2),
    minute_start    char(2),
    hour_end        char(2),
    minute_end      char(2),
    every_hour      char(1),
    schd_name       char(50),
primary key (schedule_id));
 
commit;
 
 
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

commit;
 

create table system_msg (
    system_msg_id   int not null,
    type            char(10),
    message         char(50),
    host            char(50),
    app_server      char(50),
    processesed     char(1),
primary key (system_msg_id));
 
commit;
 
 
create table analysis_rule (
    analysis_rule_id int not null,
    type            char(10),
    rule_def        long varchar,
    error           char(254),
    name            char(100),
    sf_error_deff_id int,
    active          char(1),
    execution_interval int,
    description     char(100),
 primary key  (analysis_rule_id));
 
commit;
 
 
create table reaction (
    reaction_id     int not null,
    type            char(10),
    rule_def        long varchar,
    error           char(100),
    name            char(20),
    host_specific   char(50),
    active          char(1),
    sv_name         char(50),
 primary key  (reaction_id));
 
commit;
 
 
create table collector (
    collector_id    int not null,
    type            char(10),
    rule_def        long varchar,
    error           char(254),
    name            char(100),
    odbc            char(50),
    active          char(1),
    sft_elmnt_id    int,
    host_id         int,
    description     char(100),
    execution_interval int,
    max_records     int,
    primary key  (collector_id));
 
commit;
 
 
create table sft_mng_sys (
    sft_mng_sys_id  int not null,
    name            char(50),
    status          char(20),
    state           char(20),
    type            char(50),
    primary key  (sft_mng_sys_id));
 
commit;
 
 

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
 primary key  (error_defs_id));
 
commit;
 
 
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
 
commit;
 
 
create table monitored_comps (
    monitored_comps_id int not null,
    sv_name         char(50),
    cp_max_mts      int,
    cc_name         char(50),
    ct_alias        char(50),
    cg_name         char(50),
    cc_runmode      char(50),
    cp_disp_run_state char(50),
    cp_num_run      int,
    cp_max_tas      int,
    cp_actv_mt      int,
    cc_alias        char(50),
    cp_start_time   char(50),
    cp_end_time     char(50),
    cp_status       char(50),
    sft_elmnt_id    int,
    sft_elmnt_comp_id char(50),
 primary key  (monitored_comps_id));
 
 commit;
 
 
create table processes (
    process_id      int not null,
    sv_name         char(50),
    task_id         char(10),
    pid             int,
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
    threads         int,
    sft_elmnt_id    int,
    sft_elmnt_comp_id int,
    kernel_time     varchar(10),
    user_time       varchar(10),
  primary key (process_id));

  commit;
 
 
create table components (
    components_id   int not null,
    description     char(100),
    log_analyze     char(1),
    log_monitor     char(1),
    sft_elmnt_id    int,
    cc_alias        char(80) not null,
 primary key  (components_id));
 
commit;
 

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
 primary key  (analysis_err_id));
 
commit;
 
 
create table data_source (
    data_source_id  int not null,
    name            char(50),
    username        char(50),
    password        char(50),
    host            char(50),
    alias           char(50) not null,
primary key (data_source_id, alias));
 
commit;
 

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
primary key  (administrators_id),
 foreign key (schedule_id) references schedule (schedule_id));
 
commit;



create table host_os_stats (
    db_id           char(10) not null,
    running_since   TIMESTAMP,
    status          char(10),
    memory_consuption char(50),
    cpu_utilization char(50),
    time_stamp      TIMESTAMP,
    host_id         int,
 primary key  (db_id),
 foreign key (host_id) references host (host_id));
 
commit;
 
 

create table com_admin (
    com_server_id   int not null,
    administrators_id int not null,
 primary key  (com_server_id, administrators_id),
foreign key (com_server_id) references comunicationserver (com_server_id),
foreign key (administrators_id) references administrators (administrators_id));
 
commit;
 

create table stat_vals (
    stat_vals_id    int not null,
    val             float(20) not null,
    time_stmp       TIMESTAMP not null,
    collector_id    int,
primary key  (stat_vals_id),
foreign key (collector_id) references collector (collector_id));
 
commit;
 
 
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
    port            real,
    mon_interval    int,
    sft_mng_sys_id  int,
 primary key  (sft_elmnt_id),
 foreign key (sft_mng_sys_id)  references sft_mng_sys (sft_mng_sys_id));
 
commit;

create table sft_elmnt_comp (
    sft_elmnt_comp_id int not null,
    type            char(20),
    elmnt_key       char(50) not null,
    elmnt_value     char(254) not null,
    status          char(20),
    sft_elmnt_id    int,
 primary key  (sft_elmnt_comp_id),
 foreign key (sft_elmnt_id) references sft_elmnt (sft_elmnt_id));
 
commit;
 

create table comp_errdef (
    components_id   int not null,
    error_defs_id   int not null,
 primary key (components_id, error_defs_id),
 foreign key (components_id)  references components (components_id),
 foreign key (error_defs_id)  references sft_error_defs (error_defs_id));
 
commit;
 

create table com_srvr_vals (
    com_srvr_vals_id int not null,
    type            char(20),
    elmnt_key       char(50) not null,
    elmnt_value     char(254) not null,
    status          char(20),
    com_server_id   int,
 primary key (com_srvr_vals_id),
 foreign key (com_server_id)  references comunicationserver (com_server_id));
 
commit;
 
 
create table notification_reaction (
    note_rule_id    int not null,
    reaction_id     int not null,
 primary key  (note_rule_id, reaction_id),
 foreign key (note_rule_id)   references notification_rule (note_rule_id),
 foreign key (reaction_id)    references reaction (reaction_id));
 
commit;
 

create table analysis_errdef (
    analysis_rule_id int not null,
    error_defs_id   int not null,
 primary key  (analysis_rule_id, error_defs_id),
 foreign key (analysis_rule_id)    references analysis_rule (analysis_rule_id),
 foreign key (error_defs_id)    references sft_error_defs (error_defs_id));
 
commit;
 
 
create table sft_err_deff (
    sft_elmnt_id    int not null,
    error_defs_id   int not null,
    primary key (sft_elmnt_id, error_defs_id),
   foreign key (sft_elmnt_id) references sft_elmnt (sft_elmnt_id),
   foreign key (error_defs_id)references sft_error_defs (error_defs_id));
 
commit;
 
