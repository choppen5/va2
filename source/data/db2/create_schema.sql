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
 primary key  (errorevent_id))
 
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
primary key  (note_rule_id))

commit;