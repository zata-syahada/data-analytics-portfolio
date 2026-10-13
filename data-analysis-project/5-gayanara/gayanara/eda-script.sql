########################## EDA ##########################
########### prod_dc
select * from cust_dc;
########### KOTA DENGAN PEMBELIAN TERBANYAK #############
select city, count(*) as total_pembelian from cust_dc
group by city 
order by 2 desc;
########### GENDER DENGAN PEMBELIAN TERBANYAK #############
select gender, count(*) as total_pembelian from cust_dc
group by gender
order by 2 desc; #### PEREMPUAN PALING BANYAK MELAKUKAN PEMBELIAN 
############## PROVINSI DENGAN PEMBELIAN TERBANYAK #################
select province, count(*) as total_pembelian from cust_dc
group by province
order by 2 desc; ### JABAR CO PALING BANYAK
############## KELOMPOK UMUR YG PALING BANYAK BELI ##################
select age_group, count(*) as total_pembelian from cust_dc
group by age_group; ### UMUR 25-34 PALING BANYAK MELAKUKAN PEMBELIAN
order by 2 desc;

############## oi_dc
select * from oi_dc;
select * from cust_dc;
#### PRODUK DENGAN HARGA TERTINGGI 
select product_id, unit_price_idr, dense_rank() over(order by unit_price_idr desc) as ranking
from oi_dc;

############### ord_dc
select * from oi_dc;
select * from cust_dc;
select * from ord_dc;
#### METODE PEMBAYARAN FAVORIT
select payment_method, count(*) as TOTAL from ORD_dc
group by payment_method
order by 2 desc;  ### TRANSFER BANK METODE PALING FAVORIT
##### COURIER YG Paling sering digunakan
select courier, count(*) as TOTAL from ORD_dc
group by courier
order by 2 desc; ### J&T paling sering di andalkan
##### persentase barang di kirim
select order_status, count(*) as TOTAL from ORD_dc
group by order_status
order by 2 desc;

################## prod_dc
select* from prod_dc;
### KATEGORI\ PRODUK YG SERING DIBELI
select category, count(*) as TOTAL from prod_dc
group by category
order by 2 desc;### KAOS JADI BARANG YG SERING DIBELI
### BRAND FAVORIT
select brand, count(*) as TOTAL from prod_dc
group by brand
order by 2 desc; 
### Barang dengan rating tertinggi yang stocknya masih ada
select `name`, AVG(avg_rating) rating from prod_dc
where stock > 0
group by `name`
order by 2 desc; 
### MATERIAL YANG PALING DIGEMARI 
select material, count(*) as TOTAL from prod_dc
group by material
order by 2 desc; 
### sub category
select sub_category, count(*) as TOTAL from prod_dc
group by sub_category
order by 2 desc; 

########## rev_dc
select * from rev_dc;
### rating di gayanara kebanyakan positf / engga?
select rating, count(*) as TOTAL from rev_dc
group by rating
order by 2 desc; ### mostly rating bagus
### rating 1 tapi komen bagus
select rating, count(*) as jumlah_anomali from rev_dc
where rating = 1 and (review_text like '%bagus%' or review_text like '%oke%' or review_text like '%suka%' or review_text like '%cocok%' or review_text like '%berkualitas%'
					or review_text like '%%keren%')
group by rating; ###(ada 24 rating 1 tpi komennya kontradiktif)

#################### cek penjualan yang paling laris
with penjualan_valid as
(
select oi.product_id, oi.order_id, o.order_status, oi.subtotal_idr
from ord_dc o
join oi_dc oi
	on o.order_id = oi.order_id
where o.order_status NOT IN ('cancelled', 'returned')
)
select  p.`name`, p.stock, sum(pv.subtotal_idr) total_revenue from penjualan_valid pv
join prod_dc p
	on pv.product_id = p.product_id
group by p.`name`, p.stock
order by sum(pv.subtotal_idr) desc
limit 5;

############# cek stok nganggur
select p.`name`, p.stock, count(oi.product_id) total_terjual from prod_dc p
join oi_dc oi
	on oi.product_id = p.product_id
group by `name`, p.stock, p.product_id
order by total_terjual asc, p.stock desc;

###### cek penjualan tertinggi (revenue) di setiap kota atau province
select c.province, sum(o.total_amount_idr) total_revenue, count(o.order_id) 'total penjualan'
from cust_dc c
join ord_dc o
	on c.customer_id = o.customer_id
where order_status NOT IN ('cancelled', 'returned')
group by c.province
order by sum(o.total_amount_idr) desc
limit 5;

############# CEK PERFORMA Q4 SETIAP TAHUN
### 2022
select order_date,
sum(total_amount_idr) total_2022_q4,
avg(total_amount_idr) rerata_pembelian
from ord_dc
where order_date NOT IN ('cancelled', 'returned')
group by order_date
having order_date between '2022-10-01' and '2022-12-30'
order by order_date asc;

### 2023
select order_date,
sum(total_amount_idr) total_2023_q4,
avg(total_amount_idr) rerata_pembelian
from ord_dc
where order_date NOT IN ('cancelled', 'returned')
group by order_date
having order_date between '2023-10-01' and '2023-12-31'
order by order_date asc;

### 2024
select MONTH(order_date),
sum(total_amount_idr) total_2024_q4,
avg(total_amount_idr) rerata_pembelian
from ord_dc
where order_date NOT IN ('cancelled', 'returned')
group by order_date
having order_date between '2024-10-01' and '2024-12-31'
order by order_date asc;

with month_cte as
(
select MONTH(order_date) months,
sum(total_amount_idr) total_2024_q4,
avg(total_amount_idr) rerata_pembelian
from ord_dc
where order_date NOT IN ('cancelled', 'returned')
group by order_date
having order_date between '2024-10-01' and '2024-12-31'
order by order_date asc
), last_3 as 
(
select months, sum(total_2024_q4) as sum_each_month from month_cte
group by months
)
select months, 
sum(sum_each_month) as 'total revenue 2024' from last_3
group by months;

###################### promo itu untung atau engga sih?
select 
	case
		when o.discount_amount_idr > 0 then 'pakai promo'
        else 'tanpa promo'
	end as keterangan_promo,
    count(o.order_id) total_pembelian,
    sum(o.total_amount_idr) total_revenue,
    avg(o.total_amount_idr) as rerata_belanja
from ord_dc o
where o.order_status NOT IN ('cancelled', 'returned')
group by keterangan_promo
order by total_revenue desc;

######################### Kurir yg buat barang kena return
select courier, 
count(order_id) as 'total barang yg dikembalikan', 
order_status
from ord_dc
where order_status = 'returned'
group by courier
order by count(order_id) desc;

###### rfm
select * from orders;
####### recency, frecuency, monetary
with rfm as
(
select customer_id,
datediff('2025-03-01', MAX(order_date)) as recency,
count(order_id) as frequency,
sum(total_amount_idr) as monetary
from ord_dc
where order_status NOT IN ('cancelled', 'returned')
group by customer_id 
)
select *, 
case
	when recency < 300 and frequency >= 2 and monetary > 1000000 then 'VIP'
    when recency >= 300 and frequency >=1 and monetary between 500000 and 1000000 then 'Pelanggan casual'
    when recency > 1000 and frequency = 1 then 'Perlu retargeting'
end as Klasifikasi_Pelanggan
from rfm;
