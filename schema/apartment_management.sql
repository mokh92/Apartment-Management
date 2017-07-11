--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.3
-- Dumped by pg_dump version 9.6.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: parking_system; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA parking_system;


SET search_path = parking_system, pg_catalog;

--
-- Name: bookParking(uuid, uuid); Type: FUNCTION; Schema: parking_system; Owner: -
--

CREATE FUNCTION "bookParking"(in_availabilityid uuid, in_booking_user_id uuid) RETURNS json
    LANGUAGE plpgsql
    AS $$
		 DECLARE 
		 count int;
		 out_booking_id Text;
		 out_message TEXT;
		 out_status TEXT;
		 BEGIN		
		 
		 
		 select count(*) into count from parking_system."parking_availability" where "availabilityID" =  in_availabilityId::uuid         and "availabilityStatus" = 'AVAILABLE' ;
		 
		 if(count = 1) then
		 insert into parking_system.bookings (slot_availability_id,booking_user_id,booking_status) values 
		 (in_availabilityId,in_booking_user_id,'BOOKED') RETURNING booking_id::text INTO out_booking_id;
		 
		 update parking_system.parking_availability set "availabilityStatus"='BOOKED' where "availabilityID" =  in_availabilityId;
		 out_message='Booked Successfully';
		 out_status='success';
		 else
		 out_booking_id='';
		 out_message = 'Already Booked';
		 out_status ='fail';
		 
		 
		 end if;
		 	
		return (SELECT row_to_json(r)
FROM (select  out_booking_id::text as "bookingID" , out_message as "message",out_status as status,in_availabilityId as  "availabilityID"
     ) r);
	 
		 
		 END; 
		 
		 	$$;


--
-- Name: deleteUser(uuid); Type: FUNCTION; Schema: parking_system; Owner: -
--

CREATE FUNCTION "deleteUser"(userid uuid) RETURNS TABLE(psdeletedcount integer, userdeletedcount integer)
    LANGUAGE plpgsql
    AS $$	 DECLARE 

ps int ;
userDeleted int;

BEGIN		

WITH parkingSlotsdeleted AS (delete from parking_system.parking_slot where "data"->>'ownerID' = userid::text IS TRUE RETURNING *) SELECT count(*) FROM  parkingSlotsdeleted into ps;

WITH userDeleted AS (DELETE FROM parking_system.users
WHERE id = userid IS TRUE RETURNING *) SELECT count(*) FROM userDeleted into userDeleted;

return query 
   select ps as "parkingSlotDeleted" , userDeleted as "userDeleted" ;
				
END; 	$$;


--
-- Name: getUsersAll(refcursor); Type: FUNCTION; Schema: parking_system; Owner: -
--

CREATE FUNCTION "getUsersAll"(ref1 refcursor) RETURNS refcursor
    LANGUAGE plpgsql
    AS $$	 DECLARE 
BEGIN		

OPEN ref1 FOR SELECT * from "parking_system".users;	
RETURN  ref1; 
END; 	$$;


--
-- Name: maintanence_monthly(); Type: FUNCTION; Schema: parking_system; Owner: -
--

CREATE FUNCTION maintanence_monthly() RETURNS void
    LANGUAGE plpgsql
    AS $$	DECLARE 	

rec_user   RECORD;	
 cur_users CURSOR
 FOR SELECT *
 FROM parking_system.users;
 
  BEGIN				
  
      	
      
      OPEN cur_users;
 
   LOOP
    -- fetch row into the film
      FETCH cur_users INTO rec_user;
    -- exit when no more row to fetch
      EXIT WHEN NOT FOUND;
 
    insert into parking_system.maintenance (owner_id,payment_status,maintenance_amount,amount_due) values(rec_user.id,'PENDING',12345,12345);
    
   END LOOP;
  
   -- Close the cursor
   CLOSE cur_users;
      
      
      	 	END; 		$$;


--
-- Name: userUpdate(text, jsonb, json); Type: FUNCTION; Schema: parking_system; Owner: -
--

CREATE FUNCTION "userUpdate"(user_id text, user_data jsonb, parking_slot_data json) RETURNS void
    LANGUAGE plpgsql
    AS $$	DECLARE 	 ps json; 		 BEGIN		
	    update parking_system.users set "data"=user_data where id =  user_id::uuid ;
	    
	    
	     FOR ps IN SELECT * FROM json_array_elements(parking_slot_data)         LOOP 
	               Update parking_system.parking_slot set "data" = ps where id = (ps->>'parkingSlotID')::uuid;     
	                         END LOOP;  
	    
	 	END; 		$$;


SET default_with_oids = false;

--
-- Name: amenities_bookings; Type: TABLE; Schema: parking_system; Owner: -
--

CREATE TABLE amenities_bookings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    data jsonb NOT NULL
);


--
-- Name: announcement; Type: TABLE; Schema: parking_system; Owner: -
--

CREATE TABLE announcement (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    data jsonb NOT NULL
);


--
-- Name: bookings; Type: TABLE; Schema: parking_system; Owner: -
--

CREATE TABLE bookings (
    booking_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    slot_availability_id uuid NOT NULL,
    booking_user_id uuid NOT NULL,
    booking_time timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    booking_status text NOT NULL,
    attribute1 text,
    attribute2 text,
    attribute3 text,
    attribute4 text,
    attribute5 text
);


--
-- Name: complaints; Type: TABLE; Schema: parking_system; Owner: -
--

CREATE TABLE complaints (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    data jsonb NOT NULL
);


--
-- Name: login; Type: TABLE; Schema: parking_system; Owner: -
--

CREATE TABLE login (
    user_id uuid NOT NULL,
    resident_id text NOT NULL,
    password text NOT NULL,
    last_login timestamp without time zone,
    user_status text NOT NULL,
    role_id text DEFAULT 'RESIDENT'::text
);


--
-- Name: maintenance; Type: TABLE; Schema: parking_system; Owner: -
--

CREATE TABLE maintenance (
    maintenance_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    created_date timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    owner_id uuid NOT NULL,
    payment_status text NOT NULL,
    maintenance_amount integer NOT NULL,
    amount_due integer NOT NULL,
    attribute1 text,
    attribute2 text,
    attribute3 text,
    attribute4 text,
    attribute5 text
);


--
-- Name: parking_availability; Type: TABLE; Schema: parking_system; Owner: -
--

CREATE TABLE parking_availability (
    "availabilityID" uuid NOT NULL,
    "parkingSlotID" uuid NOT NULL,
    "availabilityStartTime" time without time zone NOT NULL,
    "availabilityEndTime" time without time zone NOT NULL,
    "availabilityDate" date NOT NULL,
    "slotType" text NOT NULL,
    attribute1 text,
    attribute2 text,
    attribute3 text,
    attribute4 text,
    attribute5 text,
    "availabilityStatus" text NOT NULL
);


--
-- Name: parking_slot; Type: TABLE; Schema: parking_system; Owner: -
--

CREATE TABLE parking_slot (
    id uuid NOT NULL,
    data jsonb NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: parking_system; Owner: -
--

CREATE TABLE users (
    id uuid NOT NULL,
    data jsonb NOT NULL
);


--
-- Name: login login_pkey; Type: CONSTRAINT; Schema: parking_system; Owner: -
--

ALTER TABLE ONLY login
    ADD CONSTRAINT login_pkey PRIMARY KEY (user_id);


--
-- Name: parking_availability pa_unique_id; Type: CONSTRAINT; Schema: parking_system; Owner: -
--

ALTER TABLE ONLY parking_availability
    ADD CONSTRAINT pa_unique_id UNIQUE ("availabilityID");


--
-- Name: parking_slot ps_unique_id; Type: CONSTRAINT; Schema: parking_system; Owner: -
--

ALTER TABLE ONLY parking_slot
    ADD CONSTRAINT ps_unique_id UNIQUE (id);


--
-- Name: amenities_bookings unique_amenities_booking_id; Type: CONSTRAINT; Schema: parking_system; Owner: -
--

ALTER TABLE ONLY amenities_bookings
    ADD CONSTRAINT unique_amenities_booking_id UNIQUE (id);


--
-- Name: bookings unique_booking_id; Type: CONSTRAINT; Schema: parking_system; Owner: -
--

ALTER TABLE ONLY bookings
    ADD CONSTRAINT unique_booking_id UNIQUE (booking_id);


--
-- Name: users unique_id; Type: CONSTRAINT; Schema: parking_system; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT unique_id UNIQUE (id);


--
-- Name: announcement unique_id_announcement; Type: CONSTRAINT; Schema: parking_system; Owner: -
--

ALTER TABLE ONLY announcement
    ADD CONSTRAINT unique_id_announcement UNIQUE (id);


--
-- Name: complaints unique_id_complaints; Type: CONSTRAINT; Schema: parking_system; Owner: -
--

ALTER TABLE ONLY complaints
    ADD CONSTRAINT unique_id_complaints UNIQUE (id);


--
-- Name: maintenance unique_id_mainatanance; Type: CONSTRAINT; Schema: parking_system; Owner: -
--

ALTER TABLE ONLY maintenance
    ADD CONSTRAINT unique_id_mainatanance UNIQUE (maintenance_id);


--
-- Name: login unique_resident_id; Type: CONSTRAINT; Schema: parking_system; Owner: -
--

ALTER TABLE ONLY login
    ADD CONSTRAINT unique_resident_id UNIQUE (resident_id);


--
-- Name: login unique_userid; Type: CONSTRAINT; Schema: parking_system; Owner: -
--

ALTER TABLE ONLY login
    ADD CONSTRAINT unique_userid UNIQUE (user_id);


--
-- Name: index_data; Type: INDEX; Schema: parking_system; Owner: -
--

CREATE INDEX index_data ON users USING btree (data);


--
-- Name: index_data2; Type: INDEX; Schema: parking_system; Owner: -
--

CREATE INDEX index_data2 ON parking_slot USING btree (data);


--
-- Name: ui_reident_id; Type: INDEX; Schema: parking_system; Owner: -
--

CREATE UNIQUE INDEX ui_reident_id ON users USING btree (((data ->> 'residentID'::text)));


--
-- Name: ui_slot_no; Type: INDEX; Schema: parking_system; Owner: -
--

CREATE UNIQUE INDEX ui_slot_no ON parking_slot USING btree (((data ->> 'parkingSlotNo'::text)));


--
-- PostgreSQL database dump complete
--

