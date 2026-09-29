### EDA 
# 1. BEBAN KERJA DOKTER PER SPESIALISASI
select specialization,
count(distinct d.doctor_id) total_dokter,
count(a.appt_id) total_janji_temu,
round(
count(a.appt_id) / count(distinct d.doctor_id), 2
) beban_kerja
from 3doc d
left join 1app a
	on d.doctor_id = a.doctor_id
group by d.specialization;

#2. REVENUE PASIEN TERTINGGI DARI ASURANSI APA?
SELECT ROUND(sum(fee_idr)) as 'total revenue', payment_method
FROM 1app a
join 2dia d
	on a.appt_id = d.appt_id
group by  payment_method;

#3 KELUHAN YANG PALING SERING DATANG
SELECT  a.complaint, count(a.complaint) total_keluhan
FROM 1app a
join 2dia d
	on a.appt_id = d.appt_id
group by  complaint
order by count(a.complaint) desc ;

#4 No-Show Rate per Dokter
select doctor_id, count(doctor_id) as total_janji,
count(d.appt_id) as total_temu, 
round(
((count(doctor_id)-count(d.appt_id))/count(doctor_id))*100
) persentase_mangkir
from 1app a 
left join 2dia d
	on a.appt_id = d.appt_id
group by doctor_id;

#5. pasien datang lagi atau engga
with freq as
(
select a.patient_id, count(a.appt_id) as total_hadir
from 1app a
join 2dia d
	on a.appt_id = d.appt_id
group by a.patient_id
), cte as (
select *, 
case
	when total_hadir > 1 then 'return'
    else 'one time'
end as keterangan
from freq
)
select keterangan, count(keterangan) from cte
group by keterangan;

#6. Kapan klinik rame?
select a.appt_time, count(appt_time) total_pasien
from 1app a
join 2dia d
	on a.appt_id = d.appt_id
group by appt_time;

#7. Obat yang paling sering diberikan ke pasien
select medicine_name, count(medicine_name) total_obat
from 5pre
group by medicine_name
order by total_obat desc;

#8. Kelompok kota pasien
select city ,count(city) total_pasien from 4pat
group by city order by total_pasien desc;

#9. Golongan darah terbanyak
select blood_type, count(blood_type) jumlah_pasien from 4pat
group by blood_type order by jumlah_pasien desc;

#10. Mayoritas Tipe asuransi 
select insurance_type, count(insurance_type) total_pengguna from 4pat
group by insurance_type order by total_pengguna;
