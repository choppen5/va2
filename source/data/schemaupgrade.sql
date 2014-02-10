alter table errorevent add analysis_rule_id INT NULL

alter table errorevent add note_rule_id  INT NULL

alter table host add check_interval  int null

alter table server_task add  cc_incarn_no char(50) null

alter table server_task add  tk_label char(50) null

alter table server_task add  tk_tasktype char(50) null

alter table server_task add tk_parent_t char (50) null

alter table sft_elmnt add     mon_interval    int null

