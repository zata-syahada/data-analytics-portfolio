SELECT * FROM gayanara.customers;
SELECT * FROM gayanara.order_items;
SELECT * FROM gayanara.orders;
SELECT * FROM gayanara.products;
SELECT * FROM gayanara.reviews;

##########################################################  customers ################################################################
########################################################## cleaning data ###########################################################
SELECT * FROM gayanara.customers;
create table cust_dc
like customers;
Insert cust_dc
select *
from customers;
select * from cust_dc;



########### 1. cek duplikat ###########
SELECT * , 
row_number() over (partition by customer_id, `name`, 
email, phone, city, province, registration_date, gender, age_group ) as row_num
FROM cust_dc;

with cust_dup_cte as
(
SELECT * , 
row_number() over (partition by customer_id, `name`, 
email, phone, city, province, registration_date, gender, age_group ) as row_num
FROM cust_dc
)
select * 
from cust_dup_cte 
where row_num > 1 ; #### Gaada duplikat 

########################################################## standarisasi data ########################################################
SELECT * 
FROM cust_dc;

####### cek kolom pertama
select distinct customer_id
from cust_dc;

###### cek kolom kedua
select distinct `name`
from cust_dc
order by `name` asc;

####### hapus spasi berlebih
select `name`, trim(`name`) 
from cust_dc;

update cust_dc
set `name` = trim(`name`);

########## cek kolom 3
select email
from cust_dc
where email like '%gma%';

select email
from cust_dc
where email like '%yahoo%';

select email
from cust_dc
where email like '%out%';


########## cek kolom 4
select *
from cust_dc;

select distinct city 
from cust_dc
order by 1 asc;

############ cek kolom 5

select *
from cust_dc;

select distinct registration_date
from cust_dc
order by 1 asc;

### ubah format nya jadi date
alter table cust_dc
modify column registration_date DATE;

############# cek kolom 6
select *
from cust_dc;

select distinct gender
from cust_dc
order by 1 asc;

############# cek kolom 7
select *
from cust_dc;

select distinct age_group
from cust_dc
order by 1 asc;

############################################## handle missing and null value ############################################
select *
from cust_dc
where phone = ''; #### cek siapa aja yang gaada nomor hp

select count(*)
from cust_dc
where phone = '';

############################################### order_items #######################################################
##### cek dupli #######
select * from order_items;
create table oi_dc
like order_items;
insert oi_dc
select *
from order_items;
select *
from oi_dc;

with oi_dc_cte as
(
SELECT * , 
row_number() over (partition by item_id, order_id, product_id, 
quantity, unit_price_idr, subtotal_idr) as row_num
FROM oi_dc
)
select * from oi_dc_cte
where row_num > 1 ;

#################### standarisasi data #####################3
select * from oi_dc;
select distinct item_id 
from oi_dc;
select distinct order_id 
from oi_dc;
select distinct product_id 
from oi_dc;
select distinct quantity
from oi_dc;
select distinct unit_price_idr
from oi_dc;
select distinct subtotal_idr
from oi_dc;
#### cari missing value and null
select * from oi_dc
where quantity = '' or unit_price_idr = '' or subtotal_idr = '';
select * from oi_dc
where item_id = '' or order_id = '' or product_id = '';

#################################################### orders ########################################################
############ dupli
select * 
from orders;
create table ord_dc
like orders;
insert ord_dc
select *
from orders;
select *
from ord_dc;

with ord_cte as 
(
select *,
row_number() over(
partition by order_id, customer_id, order_date, total_amount_idr, shipping_city, 
shipping_province, shipping_cost_idr, payment_method, order_status, 
promo_code, discount_amount_idr, courier) as row_num
from ord_dc
)
select * from ord_cte
where row_num > 1;

############################### standarisasi data #######################################
select * from ord_dc;
select distinct order_id from ord_dc;
select distinct customer_id from ord_dc  order by 1 asc;
select distinct order_date from ord_dc order by 1 asc;
select distinct shipping_city from ord_dc order by 1 asc;
select distinct shipping_province from ord_dc order by 1 asc;
select distinct order_status from ord_dc order by 1 asc;
select distinct promo_code from ord_dc order by 1 asc;
select distinct courier from ord_dc order by 1 asc;
select distinct payment_method from ord_dc order by 1 asc;

#####ubah format date
alter table ord_dc
modify column order_date DATE;
######### ubah format diskon jadi int
alter table ord_dc
modify column discount_amount_idr int;


############################# missing value ############################################
select * from ord_dc;
where promo_code is null and discount_amount_idr is null;

update ord_dc
set discount_amount_idr = null
where discount_amount_idr = '';

############################################# Products #####################################
################ dupli
select * from products;

create table prod_dc
like products;
insert prod_dc
select * from products;

select * from prod_dc;

with prod_dc_cte as
(
select *, row_number() over (partition by product_id, `name`, category, 
sub_category, price_idr, stock, brand, material, avg_rating) as row_num
 from products
 )
 select * from prod_dc_cte
 where row_num > 1;
 
 ########################################### standarisasi data ##############################################
 select * from prod_dc;
 select distinct product_id from prod_dc;
 select distinct `name` from prod_dc;
 
 select distinct category from prod_dc
 where category like 'ja%'; ### (nama jacket dan jaket sama)
 
 update prod_dc
 set category = 'Jaket'
 where category like 'Jack%'; ### (ubah nama jacket)
 
 select distinct `name`, category from prod_dc
 where category = 'shirt' or category = 'kaos'
 or category = 'T-shirt';  ### (shirt, t-shirt, kaos) seragamin jadi 'Kaos' 
 
  select distinct `name`, category from prod_dc
 where category like 'aks%' or category like 'acc%';  ### (acces) seragamin jadi 'Aksesoris' 
 
  select distinct `name`, category from prod_dc
 where category = 'pants' or category = 'celana';  ### (pants) seragamin jadi 'celana' 
 
 select category, 
 case
	when category IN('shirt','T-shirt','kaos') then 'Kaos'
    when category IN('Accessories', 'aksesoris') then 'Aksesoris' 
    when category IN('Pants', 'celana') then 'Celana'
    else category
end as 'standarized category' 
from prod_dc;

update prod_dc
set category =
case
	when category IN('shirt','T-shirt','kaos') then 'Kaos'
    when category IN('Accessories', 'aksesoris') then 'Aksesoris' 
    when category IN('Pants', 'celana') then 'Celana'
    else category 
end;

select distinct category from prod_dc; 

update prod_dc
set category = 'Kemeja'
where category = 'kemeja';

############### kategori udah clean ##################
##### kolom sub kategori
select * from prod_dc;
select distinct sub_category from prod_dc;

################ brand
select distinct brand from prod_dc;

############### material
select distinct material from prod_dc;

######################################################### reviewas ###############################################33
select * from reviews;
## dupli
create table rev_dc
like reviews;
insert rev_dc
select * from reviews;
select * from rev_dc;

with rev_dc_cte as (
select *, row_number() over (partition by review_id, order_id, product_id, 
customer_id, rating, review_text, review_date, helpful_count) as row_num
from rev_dc
)
select * from rev_dc_cte
where row_num > 1;

################################################### standarisasi data ###################################################
select * from rev_dc;
alter table rev_dc
modify column review_date DATE;





 
























