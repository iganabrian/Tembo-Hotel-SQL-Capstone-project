-- ==========================================================
-- ======= PART A - DDL ==============================

CREATE TABLE IF NOT EXISTS bookings_staging (
    booking_id          TEXT,  
    guest_name          TEXT,
    guest_phone         TEXT,  
    guest_city          TEXT,
    guest_nationality   TEXT,  
    room_no             TEXT,
    room_type           TEXT,  
    room_rate_per_night TEXT,
    check_in_date       TEXT,  
    check_out_date      TEXT,
    nights_stayed       TEXT,  
    staff_name          TEXT,
    staff_department    TEXT,  
    staff_salary        TEXT,
    payment_method      TEXT,  
    booking_status      TEXT,
    total_amount        TEXT,  
    service_used        TEXT,
    service_price       TEXT,  
    guest_rating        TEXT
);

select * from bookings_staging;

select count(*) from bookings_staging;

-- ==========================================
-- ======PART B Audit queries ======================

-- Clean 1 - fix guest name: trim + fix casing - Captalization 
-- ALICE MWANGI - should be -> Alice Mwangi
-- brian otieno  - should be -> Brian Otieno 
-- Audit 1 - guest name problems 

select distinct  guest_name 
from bookings_staging 
limit 40;


-- we have CAPS need to fix the casing - INITCAP
-- we have names in lowercase - 
update bookings_staging
set guest_name = initcap(guest_name);


-- removing extra spaces i.e Carol Wanjiku
update bookings_staging
set guest_name = trim(guest_name);


-- Audit 2 - room type distinct values
select 
	distinct  room_type, 
	count(*) as count
from bookings_staging 
group by room_type 
order by room_type;


/* Expected values: Standard, Deluxe,Suite, Penthouse)
 * dirty values - DLX, Std, standard, deluxe
 * -- Clean 5 - roomtype: abbreviations and lowercase 
-- Standard, Deluxe, Suite, Penthouse
 * */

update bookings_staging
set room_type = 
case
		when room_type = 'DLX' then  initcap('Deluxe')
		when room_type = 'Std' then  initcap('Standard')
		else initcap(room_type)
end
;


-- Audit 3 - payment method 
select distinct  payment_method 
from bookings_staging;

-- Clean 6 - Payment method and booking_status , casing 
-- expected - Mpesa , Card, Bank Transfer , Cash

update bookings_staging
set payment_method = 
case
		when payment_method = 'mpesa' then  initcap('mpesa')
		when payment_method = 'M-Pesa' then  initcap('mpesa')
		else initcap(payment_method)
end
;


-- Audit 4 - booking status
select distinct  booking_status 
from bookings_staging;

update bookings_staging
set booking_status = initcap(booking_status);


-- Audit 5 - phone, city
-- phone 
-- Null or empty string
select 
	guest_name, 
	count(*) 
from bookings_staging 
where guest_phone is null or trim(guest_phone) = ''
group by guest_name;


-- display guest
select 
	guest_name,
	guest_phone,
	count(*) 
from bookings_staging
group by 
		guest_name,
		guest_phone
;

-- add 0 to phone number, limit digits to 10, remove any other value other than 0-9
-- Clean 2 - guest phone: remove dashes, fix +254 
-- +254715623803 - 0715623803
-- 07-15-623-803 - 0715623803 


update bookings_staging
set guest_phone = 0|| regexp_replace(
						regexp_replace(
							trim(guest_phone:: text), 
							'[^0-9]', '', 'g'
							), 
							'^254', '0')
where guest_phone is not null
;

--I realizes that there are numbers with more than 10 digits after running the above code, so
--I wrote another code to repalce the two digits with one digit
select 
	guest_phone, 
	guest_name
from bookings_staging
where length(guest_phone) > 10;

update bookings_staging
set guest_phone = '0745678901'
where guest_phone = '00745678901';

select booking_id, guest_phone from bookings_staging
where guest_phone like '+254%' or guest_phone like '%-%';



-- city
-- Clean 3 - guest city: typos, casing , empty (Unknown)

select distinct 
	case
		when trim(guest_city) ='Thikax' then 'Thika'
		else initcap(trim(guest_city))
	end as guestcity_
from bookings_staging;

select distinct 
	guest_city
from bookings_staging;

update bookings_staging
set guest_city = case 
					when guest_city = 'Thikax' then trim('Thika')
					else 
						initcap(trim(guest_city))
					end
;


-- clean 8 - guest rating: invalid values - null 
-- Audit 6 - Ratings 
select 
	booking_id, 
	guest_name, 
	guest_rating 
from bookings_staging 
where 
	trim(guest_rating) not in ('1', '2', '3', '4', '5') or 
	trim(guest_rating) = ''
;

update bookings_staging 
set guest_rating = null
where 
	trim(guest_rating) not in ('1', '2', '3', '4', '5') or 
	trim(guest_rating) = ''
;

-- Audit 7 - Date Format problems
select booking_id, check_in_date, check_out_date 
from bookings_staging 
where check_in_date not similar to '[0-9]{4}-[0-9]{2}-[0-9]{2}';


-- Clean 4 - Date formats 
-- 2026-04-28 

select 
	check_in_date,
	check_out_date
from bookings_staging
;

select 
	check_in_date,
	check_out_date
from bookings_staging
where check_in_date LIKE '%-%-%'
	or check_out_date LIKE '%-%-%';


update bookings_staging 
set  check_in_date = to_char(to_date(check_in_date, 'YYYY-MM-DD'), 'DD-MM-YYYY'),
	 check_out_date = to_char(to_date(check_out_date, 'YYYY-MM-DD'), 'DD-MM-YYYY')
where check_in_date LIKE '%-%-%'
	or check_out_date LIKE '%-%-%';

--format date 
update bookings_staging 
set  check_in_date = to_char(to_date(check_in_date, 'DD-MM-YYYY'), 'YYYY-MM-DD'),
	 check_out_date = to_char(to_date(check_out_date, 'DD-MM-YYYY'), 'YYYY-MM-DD')
;




-- clean 7 - total amount and staff salary (strip KES, commas, cast to number)

select 
	staff_salary
from bookings_staging;

update bookings_staging
set staff_salary = nullif(regexp_replace( 
							trim(staff_salary::text),
								'[^0-9.]', '', 'g'),
								''
								):: decimal (12,2) 
where staff_salary is not null
		and trim(staff_salary)::text != '';


-- clean 9 - Remove exact duplicates 
select booking_id, count(*) from bookings_staging
group by booking_id having count(*) > 1;

DELETE FROM bookings_staging
WHERE ctid NOT IN (
    SELECT MIN(ctid)
    FROM bookings_staging
    GROUP BY booking_id
);




-- clean 10 - figure out other fixes you need to do 
--cleaned the total amount section 
select 
	*
from bookings_staging;


update bookings_staging
set total_amount = nullif(regexp_replace( 
							trim(total_amount::text),
								'[^0-9.]', '', 'g'),
								''
								):: decimal (12,2) 
where total_amount is not null
		and trim(total_amount)::text != ''
;

---cleaning service price just to be sure it is clean

select 
	service_price
from bookings_staging;


update bookings_staging
set service_price = nullif(regexp_replace( 
							trim(service_price::text),
								'[^0-9.]', '', 'g'),
								''
								):: decimal (12,2) 
where service_price is not null
		and trim(service_price)::text != ''
;

-- ========== PART D ==========================
-- Create production table and load clean data .

create table if not exists bookings(
	booking_id 			VARCHAR(10) primary key,
    guest_name      	VARCHAR(25),
    guest_phone        	VARCHAR(15),  
    guest_city          VARCHAR(25),
    guest_nationality   VARCHAR(25),  
    room_no             INT,
    room_type           VARCHAR(25),  
    room_rate_per_night  NUMERIC(10,2),
    check_in_date       DATE,  
    check_out_date      DATE,
    nights_stayed       INT,  
    staff_name          VARCHAR(25),
    staff_department    VARCHAR(50),  
    staff_salary        NUMERIC(10,2),
    payment_method      VARCHAR(25),  
    booking_status      VARCHAR(25),
    total_amount        NUMERIC(10,2),  
    service_used        VARCHAR(25),
    service_price       NUMERIC(10,2),  
    guest_rating        INT
);

INSERT INTO bookings (
    booking_id, guest_name, guest_phone, guest_city, guest_nationality,
    room_no, room_type, room_rate_per_night, check_in_date, check_out_date,
    nights_stayed, staff_name, staff_department, staff_salary, payment_method,
    booking_status, total_amount, service_used, service_price, guest_rating
)
SELECT 
    booking_id, guest_name, guest_phone, guest_city, guest_nationality,
    room_no::INT, room_type, room_rate_per_night::NUMERIC, 
    check_in_date::DATE, check_out_date::DATE,
    nights_stayed::INT, staff_name, staff_department, staff_salary::NUMERIC, 
    payment_method, booking_status, total_amount::NUMERIC, 
    service_used, service_price::NUMERIC, guest_rating::INT
FROM bookings_staging;




--Queries answering some business questions:
 *	-- Revenue analysis 
 *		-- total revenue by month, by room, by payment method
-- total revenue
select 
	EXTRACT(MONTH FROM "check_in_date") as booking_month,
	sum(total_amount)  as revenue
from bookings
group by 
	EXTRACT(MONTH FROM "check_in_date")
order by EXTRACT(MONTH FROM "check_in_date") ;

-- total revenue by room
select 
	room_type,
	sum(total_amount)  as revenue
from bookings
group by room_type 
order by sum(total_amount) desc;

-- total revenue by payment method
select 
	payment_method,
	sum(total_amount) as revenue
from bookings
group by payment_method 
order by sum(total_amount) desc;

---add a new column for days stayed and month checked in

alter table bookings
add column	sales_months  int,
add column days_stayed int
;


update bookings
set days_stayed = check_out_date - check_in_date,
	sales_months = extract(month from check_in_date):: int
	
;

select 
	check_in_date,
	sales_months,
	days_stayed  
from bookings;

--there is a blank or null city for Henry Korir let's fix him in Eldoret
select *
from bookings
where guest_city is null;

update  bookings
set guest_city = 'Eldoret'
where guest_name = 'Henry Korir';

 *	--Occupancy - which room types are booked most? (avg nights stayed by room type)
 *	-- Staff performance - which staff handled the most bookings?
 *	-- Cancellations - Cancellation rate per room type. Revenue lost from cancellationor no-shows
 */
