create table kinds (
   id integer primary key,
   description string
);

create table params (
   id integer primary key,
   kind integer not null,
   name string,
   description string,
   not_null boolean,
   expert boolean,
   needs_restart boolean,

   constraint kind_fk foreign key(kind)
      references kinds(id)
      on delete cascade
      on update cascade
);

create table arc_labels (
   id integer primary key,
   label string
);

create table param_arcs (
   id integer primary key,
   source integer not null,
   dest integer not null,
   label integer not null,

   constraint source_fk foreign key(source)
      references params(id)
      on delete cascade
      on update cascade,
   constraint dest_fk foreign key(dest)
      references params(id)
      on delete cascade
      on update cascade,
   constraint label_fk foreign key(label)
      references arc_labels(id)
      on delete cascade
      on update cascade
);

create table nodes (
   id integer primary key,
   name string,
   pool string
);

create table node_groups (
   id integer primary key,
   name string
);

create table group_memberships (
   id integer primary key,
   node integer not null,
   node_group integer not null,

   constraint node_fk foreign key(node)
      references nodes(id)
      on delete cascade
      on update cascade,
   constraint node_group_fk foreign key(node_group)
      references node_groups(id)
      on delete cascade
      on update cascade,
);

create table features (
   id integer primary key,
   name string not null,
);

create table feature_arcs (
   id integer primary key,
   source integer not null,
   dest integer not null,
   label integer not null,

   constraint source_fk foreign key(source)
      references features(id)
      on delete cascade
      on update cascade,
   constraint dest_fk foreign key(dest)
      references features(id)
      on delete cascade
      on update cascade,
   constraint label_fk foreign key(label)
      references arc_labels(id)
      on delete cascade
      on update cascade
);

create table feature_params (
   id integer primary key,
   feature integer not null,
   param integer not null,
   value string not null,

   constraint feature_fk foreign key(feature)
      references features(id)
      on delete cascade
      on update cascade,
   constraint param_fk foreign key(param)
      references params(id)
      on delete cascade
      on update cascade

);

create table configurations (
	id integer primary key,
	string name not null,
);

create table configuration_group_features (
	id integer primary key,
	configuration integer not null,
	version integer not null,
	group integer not null,
	feature integer not null,
	enable boolean default true,

    constraint configuration_fk foreign key(configuration)
       references configurations(id)
       on delete cascade
       on update cascade,
    	
	constraint feature_fk foreign key(feature)
   	   references features(id)
   	   on delete cascade
       on update cascade,

    constraint group_fk foreign key(group)
       references groups(id)
       on delete cascade
       on update cascade,

	constraint version_pos check (version >= 0)
);

create table configuration_group_mappings (
	id integer primary key,
	configuration integer not null,
	version integer not null,
	group integer not null,
	param integer not null,
	value string,
	enable boolean default true,

    constraint configuration_fk foreign key(configuration)
       references configurations(id)
       on delete cascade
       on update cascade,
    	
	constraint param_fk foreign key(param)
   	   references params(id)
   	   on delete cascade
       on update cascade,

    constraint group_fk foreign key(group)
       references groups(id)
       on delete cascade
       on update cascade,

	constraint version_pos check (version >= 0)	
);

create table configuration_default_features (
	id integer primary key,
	configuration integer not null,
	version integer not null,
	feature integer not null,
	enable boolean default true,

    constraint configuration_fk foreign key(configuration)
       references configurations(id)
       on delete cascade
       on update cascade,
    	
	constraint feature_fk foreign key(feature)
   	   references features(id)
   	   on delete cascade
       on update cascade,

	constraint version_pos check (version >= 0)
);
