/*Charles Oppneheimer - changed 4/2/2005
should be run for VA2 systems that were installed before 10/26/2004
*/


/*adds support for collector archiving*/
alter table collector add parent_sft_elmnt_id integer,
    parent_collector_id integer,
    archive_field   char(1),
    archive_interval char(1),
    archive_description char(50)

/* adds support for host no_ping option */
alter table host add no_ping char(1)

create table resonate_ar (
    resonate_id     integer not null,
    sft_elmnt_id    integer,
    service         char(50),
    service_host    char(50),
    type            char(50),
    rule_number     integer,
primary key (resonate_id));