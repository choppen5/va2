/*
 * Load Tables
*/
/*
 * Target DBMS: 'Ingres'
*/
 
 
/*
 * Load Table          : errorevent
*/
copy table errorevent (
    errorevent_id=char(0)',',
    type=char(0)',',
    event_sub_type=char(0)',',
    event_level=char(0)',',
    event_time=char(0)',',
    event_string=char(0)',',
    status=char(0)',',
    error_defs_id=char(0)',',
    cc_alias=char(0)',',
    sv_name=char(0)',',
    sft_elmnt_id=char(0)',',
    processed=char(0)',',
    reactionfired=char(0)',',
    host=char(0)nl)
from 'errorevent.txt';
 
 
/*
 * Load Table          : host
*/
copy table host (
    host_id=char(0)',',
    hostname=char(0)',',
    ipaddress=char(0)',',
    os=char(0)',',
    status=char(0)nl)
from 'host.txt';
 
 
/*
 * Load Table          : schedule
*/
copy table schedule (
    schedule_id=char(0)',',
    schedule_every=char(0)',',
    monday=char(0)',',
    tuesday=char(0)',',
    wednesday=char(0)',',
    thursday=char(0)',',
    friday=char(0)',',
    saturday=char(0)',',
    sunday=char(0)',',
    every_day=char(0)',',
    hour_start=char(0)',',
    minute_start=char(0)',',
    hour_end=char(0)',',
    minute_end=char(0)',',
    every_hour=char(0)',',
    schd_name=char(0)',',
    start_time=char(0)',',
    end_time=char(0)nl)
from 'schedule.txt';
 
 
/*
 * Load Table          : comunicationserver
*/
copy table comunicationserver (
    com_server_id=char(0)',',
    smtp_server=char(0)',',
    webserver=char(0)',',
    paging_server=char(0)',',
    modemnumber=char(0)',',
    type=char(0)',',
    active=char(0)',',
    name=char(0)nl)
from 'comunicationserver.txt';
 
 
/*
 * Load Table          : system_msg
*/
copy table system_msg (
    system_msg_id=char(0)',',
    type=char(0)',',
    message=char(0)',',
    host=char(0)',',
    app_server=char(0)',',
    processesed=char(0)nl)
from 'system_msg.txt';
 
 
/*
 * Load Table          : analysis_rule
*/
copy table analysis_rule (
    analysis_rule_id=char(0)',',
    type=char(0)',',
    rule_def=char(0)',',
    error=char(0)',',
    name=char(0)',',
    sf_error_deff_id=char(0)',',
    active=char(0)nl)
from 'analysis_rule.txt';
 
 
/*
 * Load Table          : reaction_grp
*/
copy table reaction_grp (
    reaction_grp_id=char(0)',',
    type=char(0)',',
    name=char(0)nl)
from 'reaction_grp.txt';
 
 
/*
 * Load Table          : collector
*/
copy table collector (
    collector_id=char(0)',',
    type=char(0)',',
    rule_def=char(0)',',
    error=char(0)',',
    name=char(0)',',
    odbc=char(0)',',
    active=char(0)',',
    sft_elmnt_id=char(0)',',
    host_id=char(0)',',
    description=char(0)nl)
from 'collector.txt';
 
 
/*
 * Load Table          : sft_mng_sys
*/
copy table sft_mng_sys (
    sft_mng_sys_id=char(0)',',
    name=char(0)',',
    status=char(0)',',
    state=char(0)nl)
from 'sft_mng_sys.txt';
 
 
/*
 * Load Table          : sft_error_defs
*/
copy table sft_error_defs (
    error_defs_id=char(0)',',
    type=char(0)',',
    eventtypename=char(0)',',
    errorlevel=char(0)',',
    errortime=char(0)',',
    search_string=char(0)',',
    eventsubtype=char(0)',',
    template=char(0)',',
    anded=char(0)',',
    globaldef=char(0)',',
    evt_error_level=char(0)',',
    evt_type=char(0)',',
    host=char(0)nl)
from 'sft_error_defs.txt';
 
 
/*
 * Load Table          : server_task
*/
copy table server_task (
    server_task_id=char(0)',',
    sv_name=char(0)',',
    cc_alias=char(0)',',
    tk_taskid=char(0)',',
    tk_pid=char(0)',',
    tk_disp_runstate=char(0)',',
    cc_runmode=char(0)',',
    tk_start_time=char(0)',',
    tk_end_time=char(0)',',
    tk_status=char(0)',',
    cg_alias=char(0)',',
    sft_elmnt_id=char(0)',',
    sft_elmnt_comp_id=char(0)nl)
from 'server_task.txt';
 
 
/*
 * Load Table          : monitored_comps
*/
copy table monitored_comps (
    monitored_comps_id=char(0)',',
    sv_name=char(0)',',
    cp_max_mts=char(0)',',
    cc_name=char(0)',',
    ct_alias=char(0)',',
    cg_name=char(0)',',
    cc_runmode=char(0)',',
    cp_disp_run_state=char(0)',',
    cp_num_run=char(0)',',
    cp_max_tas=char(0)',',
    cp_actv_mt=char(0)',',
    cc_alias=char(0)',',
    cp_start_time=char(0)',',
    cp_end_time=char(0)',',
    cp_status=char(0)',',
    sft_elmnt_id=char(0)',',
    sft_elmnt_comp_id=char(0)nl)
from 'monitored_comps.txt';
 
 
/*
 * Load Table          : processes
*/
copy table processes (
    process_id=char(0)',',
    sv_name=char(0)',',
    task_id=char(0)',',
    pid=char(0)',',
    cc_alias=char(0)',',
    cc_name=char(0)',',
    host=char(0)',',
    state=char(0)',',
    process=char(0)',',
    cpu=char(0)',',
    cpu_time=char(0)',',
    memory=char(0)',',
    pagefaults=char(0)',',
    virtualmem=char(0)',',
    priority=char(0)',',
    threads=char(0)',',
    sft_elmnt_id=char(0)',',
    sft_elmnt_comp_id=char(0)nl)
from 'processes.txt';
 
 
/*
 * Load Table          : components
*/
copy table components (
    components_id=char(0)',',
    description=char(0)',',
    log_analyze=char(0)',',
    log_monitor=char(0)',',
    sft_elmnt_id=char(0)',',
    cc_alias=char(0)nl)
from 'components.txt';
 
 
/*
 * Load Table          : tableids
*/
copy table tableids (
    table_name=char(0)',',
    id=char(0)nl)
from 'tableids.txt';
 
 
/*
 * Load Table          : administrators
*/
copy table administrators (
    administrators_id=char(0)',',
    first_name=char(0)',',
    last_name=char(0)',',
    password=char(0)',',
    email=char(0)',',
    phone=char(0)',',
    pager=char(0)',',
    default_admin=char(0)',',
    user_name=char(0)',',
    schedule_id=char(0)nl)
from 'administrators.txt';
 
 
/*
 * Load Table          : notification_rule
*/
copy table notification_rule (
    note_rule_id=char(0)',',
    name=char(0)',',
    message=char(0)',',
    notify_all=char(0)',',
    incl_ev_string=char(0)',',
    inc_ev_level=char(0)',',
    inc_ev_subtype=char(0)',',
    type=char(0)',',
    status=char(0)',',
    active=char(0)',',
    ev_sft_elmnt_id=char(0)',',
    ev_event_sub_type=char(0)',',
    ev_event_level=char(0)',',
    ev_event_time=char(0)',',
    ev_event_string=char(0)',',
    ev_type=char(0)',',
    reaction_grp_id=char(0)nl)
from 'notification_rule.txt';
 
 
/*
 * Load Table          : errorexceptions
*/
copy table errorexceptions (
    errorexceptions_id=char(0)',',
    errorexception=char(0)',',
    time_exemption=char(0)',',
    err_type_exept=char(0)',',
    note_rule_id=char(0)nl)
from 'errorexceptions.txt';
 
 
/*
 * Load Table          : host_os_stats
*/
copy table host_os_stats (
    db_id=char(0)',',
    running_since=char(0)',',
    status=char(0)',',
    memory_consuption=char(0)',',
    cpu_utilization=char(0)',',
    time_stamp=char(0)',',
    host_id=char(0)nl)
from 'host_os_stats.txt';
 
 
/*
 * Load Table          : com_admin
*/
copy table com_admin (
    com_server_id=char(0)',',
    administrators_id=char(0)nl)
from 'com_admin.txt';
 
 
/*
 * Load Table          : reaction
*/
copy table reaction (
    reaction_id=char(0)',',
    type=char(0)',',
    return_val_req=char(0)',',
    return_val=char(0)',',
    rule_def=char(0)',',
    error=char(0)',',
    name=char(0)',',
    host_specific=char(0)',',
    inactive=char(0)',',
    reaction_grp_id=char(0)nl)
from 'reaction.txt';
 
 
/*
 * Load Table          : stat_vals
*/
copy table stat_vals (
    stat_vals_id=char(0)',',
    val=char(0)',',
    time_stmp=char(0)',',
    collector_id=char(0)nl)
from 'stat_vals.txt';
 
 
/*
 * Load Table          : sft_product
*/
copy table sft_product (
    sft_product_id=char(0)',',
    name=char(0)',',
    vendor=char(0)',',
    version=char(0)',',
    type=char(0)',',
    sft_mng_sys_id=char(0)nl)
from 'sft_product.txt';
 
 
/*
 * Load Table          : sft_elmnt
*/
copy table sft_elmnt (
    sft_elmnt_id=char(0)',',
    type=char(0)',',
    description=char(0)',',
    name=char(0)',',
    os=char(0)',',
    host=char(0)',',
    installdir=char(0)',',
    status=char(0)',',
    exe=char(0)',',
    service_name=char(0)',',
    parent_elmnt_id=char(0)',',
    sft_product_id=char(0)nl)
from 'sft_elmnt.txt';
 
 
/*
 * Load Table          : sft_elmnt_comp
*/
copy table sft_elmnt_comp (
    sft_elmnt_comp_id=char(0)',',
    type=char(0)',',
    elmnt_key=char(0)',',
    elmnt_value=char(0)',',
    status=char(0)',',
    sft_elmnt_id=char(0)nl)
from 'sft_elmnt_comp.txt';
 
 
/*
 * Load Table          : sft_err_deff
*/
copy table sft_err_deff (
    sft_err_deff_id=char(0)',',
    type=char(0)',',
    log_path=char(0)',',
    filename=char(0)',',
    sft_elmnt_id=char(0)',',
    sft_elmnt_comp_id=char(0)',',
    error_defs_id=char(0)nl)
from 'sft_err_deff.txt';
 
 
/*
 * Load Table          : comp_errdef
*/
copy table comp_errdef (
    components_id=char(0)',',
    error_defs_id=char(0)nl)
from 'comp_errdef.txt';
 
 
/*
 * Load Table          : com_srvr_vals
*/
copy table com_srvr_vals (
    com_srvr_vals_id=char(0)',',
    type=char(0)',',
    elmnt_key=char(0)',',
    elmnt_value=char(0)',',
    status=char(0)',',
    com_server_id=char(0)nl)
from 'com_srvr_vals.txt';
 
 
/*
 * Load Table          : analysis_err
*/
copy table analysis_err (
    analysis_err_id=char(0)',',
    evt_type=char(0)',',
    evt_event_sub_type=char(0)',',
    evt_event_level=char(0)',',
    evt_event_time=char(0)',',
    evt_event_string=char(0)',',
    evt_status=char(0)',',
    evt_cc_alias=char(0)',',
    evt_sv_name=char(0)',',
    evt_sft_elmnt_id=char(0)',',
    evt_host=char(0)',',
    name=char(0)',',
    analysis_rule_id=char(0)nl)
from 'analysis_err.txt';
 
 
/*
 * Load Table          : sft_sub_elmnt
*/
copy table sft_sub_elmnt (
    sft_sub_elmnt_id=char(0)',',
    type=char(0)',',
    elmnt_key=char(0)',',
    elmnt_value=char(0)',',
    sft_elmnt_comp_id=char(0)nl)
from 'sft_sub_elmnt.txt';
 
commit \g
