create table Vehicle(
    id serial primary key,
    reg_plate varchar(50),
    reputation int,
    curr_route_cost double precision,
    /* Pentru simulare */
    is_accurate_reporter boolean,
    is_negligent boolean
);

create table Route_portion(
    id serial primary key,
    name varchar(50),
    speed_lim int, /* expressed in km/h */
    len double precision,
    traversal_cost double precision,
    start_node int,
    end_node int /* pentru a forma un graf al drumurilor in care nodurile(capetele) reprezinta intersectii */
);

create table Intersection(
    id serial primary key,
    name varchar(50),
    reputation int
);

create table Event(
    id serial primary key,
    title varchar(50),
    max_velocity int
);

create table Report(
    id serial primary key,
    -- timestamp timestamp DEFAULT CURRENT_TIMESTAMP,
    timestamp double precision,
    vehicle_id int,
    event_id int,
    route_portion_id int,
    intersection_id int,
    reported_vehicle_id int,
    event_location double precision,
    valid_report boolean,
    constraint fk_vehicle foreign key(vehicle_id) references Vehicle(id) on update cascade,
    constraint fk_reported_vehicle foreign key(reported_vehicle_id) references Vehicle(id) on update cascade,
    constraint fk_event foreign key(event_id) references Event(id) on update cascade,
    constraint fk_portion_route foreign key(route_portion_id) references Route_portion(id) on update cascade,
    constraint fk_intersection foreign key(intersection_id) references Intersection(id) on update cascade
);

create table Route_scheduling(
    id serial primary key,
    route_portion_id int,
    vehicle_id int,
    constraint fk_vehicle foreign key(vehicle_id) references Vehicle(id) on update cascade on delete cascade,
    constraint fk_portion_route foreign key(route_portion_id) references Route_portion(id) on update cascade on delete cascade
);

insert into Event(title, max_velocity) values('Accident', 10);
insert into Event(title, max_velocity) values('Lucrari', 20);
insert into Event(title, max_velocity) values('Obstacol', 20);
insert into Event(title, max_velocity) values('Groapa', 25);
insert into Event(title, max_velocity) values('ConditiiNefavorabile', 30);
/* Evenimente specifice unei intersectii */
insert into Event(title, max_velocity) values('TrecereCuloareRosieSemafor', 0);
insert into Event(title, max_velocity) values('NeacordarePrioritate', 0);

CREATE FUNCTION update_current_cost_trigger() RETURNS trigger AS $$
    BEGIN
        IF (TG_OP = 'INSERT') THEN
            UPDATE Vehicle 
            SET curr_route_cost =
                curr_route_cost + 
                (SELECT traversal_cost FROM Route_portion WHERE id = NEW.route_portion_id)
            WHERE id = NEW.vehicle_id;
        ELSIF (TG_OP = 'UPDATE') THEN
            UPDATE Vehicle 
            SET curr_route_cost = 
                curr_route_cost + 
                (SELECT traversal_cost FROM Route_portion WHERE id = NEW.route_portion_id) -
                (SELECT traversal_cost FROM Route_portion WHERE id = OLD.route_portion_id)
            WHERE id = OLD.vehicle_id;
        ELSIF (TG_OP = 'DELETE') THEN
            UPDATE Vehicle 
            SET curr_route_cost = 
                curr_route_cost -
                (SELECT traversal_cost FROM Route_portion WHERE id = OLD.route_portion_id)
            WHERE id = OLD.vehicle_id;
        END IF;

        RETURN NULL;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER vehicle_current_route_cost_trigger
    AFTER INSERT OR UPDATE OR DELETE ON Route_scheduling
    FOR EACH ROW
    EXECUTE FUNCTION update_current_cost_trigger();
