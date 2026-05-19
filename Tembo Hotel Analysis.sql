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

-- Audit 1 - guest name problems 
select distinct  guest_name from bookings_staging limit 40;
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
 * 
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
update bookings_staging
set guest_phone = 0|| regexp_replace(
						regexp_replace(
							trim(guest_phone:: text), 
							'[^0-9]', '', 'g'
							), 
							'^254', '0')
where guest_phone is not null
;

-- phone 
select booking_id, guest_phone from bookings_staging
where guest_phone like '+254%' or guest_phone like '%-%';

-- city


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


-- Audit 7 - Date Format problems
select booking_id, check_in_date, check_out_date 
from bookings_staging 
where check_in_date not similar to '[0-9]{4}-[0-9]{2}-[0-9]{2}';

-- ==================================================
-- ======= Part C - Time to clean data ==============

-- Clean 1 - fix guest name: trim + fix casing - Captalization 
-- ALICE MWANGI - should be -> Alice Mwangi
-- brian otieno  - should be -> Brian Otieno 




-- Clean 2 - guest phone: remove dashes, fix +254 
-- +254715623803 - 0715623803
-- 07-15-623-803 - 0715623803 



-- Clean 3 - guest city: typos, casing , empty (Unknown)



-- Clean 4 - Date formats 
-- 2026-04-28 



-- Clean 5 - roomtype: abbreviations and lowercase 
-- Standard, Deluxe, Suite, Penthouse



-- Clean 6 - Payment method and booking_status , casing 



-- clean 7 - total amount and staff salary (strip KES, commas, cast to number)

select *
from bookings_staging;

update bookings_staging
set staff_salary = regexp_replace(
						cast ( staff_salary as int), '^[0-9.]', '', 'g' 
);

-- clean 8 - guest rating: invalid values - null 


-- clean 9 - Remove exact duplicates 
select booking_id, count(*) from bookings_staging
group by booking_id having count(*) > 1;



-- clean 10 - figure out other fixes you need to do 


-- ========== PART D ==========================
-- Create production table and load clean data .

create table if not exists bookings(
		booking_id VARCHAR(10) primary key,
		