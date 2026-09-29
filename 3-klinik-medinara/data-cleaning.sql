SELECT * FROM `klinik-medinara`.appointments;
create table 1app
like appointments;
insert 1app
select * from appointments;
select * from 1app;

create table 2dia
like diagnoses;
insert 2dia
select * from diagnoses;
select * from 2dia;

create table 3doc
like doctors;
insert 3doc
select * from doctors;
select * from 3doc;

create table 4pat
like patients;
insert 4pat
select * from patients;
select * from 4pat;
select * from patients;

create table 5pre
like prescriptions;
insert 5pre
select * from prescriptions;
select * from 5pre;

################# DATA CLEANING #############

#### Data dupli appointment
with app_dup as
(
select *,
row_number () over(partition by rx_id, diagnosis_id, patient_id, medicine_name, dosage, route, duration_days, prescribed_date, quantity) as row_num
from 5pre
)
select * from app_dup
where row_num > 1;



### standarisasi data
################# urus tanggal
select * from 1app;
### ubah format tanggal jadi date dulu
select appt_date, str_to_date(appt_date, '%d/%m/%Y')
from 1app;

select appt_date, str_to_date(appt_date, '%d-%m-%Y')
from 1app
where RIGHT(appt_date, 4) REGEXP '^[0-9]{4}$';

select * from appointments;
select * from 1app;

update 1app
set appt_date = str_to_date(appt_date, '%d-%m-%Y')
where RIGHT(appt_date, 4) REGEXP '^[0-9]{4}$';

alter table 1app
modify column appt_date DATE;

### ubah format waktu
alter table 1app
modify column appt_time TIME;

############# DAIGNOSIS
SELECT * from 2dia;
update 2dia
set icd_code = 'unknown'
where icd_code = '';

##################### DOKTER
select * from 3doc;

##################### pasien
select * from 4pat;
update 4pat
set phone = 'unknown'
where phone = '';

#################### prescription
select * from 5pre;
select prescribed_date, str_to_date(prescribed_date, '%d/%m/%Y')
from 5pre
where prescribed_date like '%/%';

select prescribed_date, str_to_date(prescribed_date, '%d-%m-%Y')
from 5pre
where RIGHT(prescribed_date, 4) REGEXP '^[0-9]{4}$'
and prescribed_date like '%-%';

update 1app
set appt_date = str_to_date(appt_date, '%d/%m/%Y')
where appt_date like '%/%';

select * from 1app;
select * from 2dia;
select * from 3doc;
select * from 4pat;
select * from 5pre;

