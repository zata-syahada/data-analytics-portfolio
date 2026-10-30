### Total Dana Pihak Ketiga per Bulan
with pct_table as
(
select month(s.tgl_snapshot) as bulan,
date_format(s.tgl_snapshot, '%M') as bulan1,
sum(case when r.produk = 'TABUNGAN' then s.saldo else 0 end) as tabungan,
sum(case when r.produk = 'GIRO' then s.saldo else 0 end) as giro,
sum(case when r.produk = 'DEPOSITO' then s.saldo else 0 end) as deposito,
round(100.0*sum(case when r.produk in ('TABUNGAN','GIRO') then s.saldo else 0 end)/nullif(sum(s.saldo),0),2) as pct_casa
from saldo_bulanan s
join rekening r on r.no_rek = s.no_rek
group by MONTH(s.tgl_snapshot), date_format(s.tgl_snapshot, '%M')
order by MONTH(s.tgl_snapshot) asc
)
select *, pct_casa - LAG(pct_casa) over (order by bulan) delta_pct
from pct_table;

### Penyebab rasio casa turun drastis?
with cte as
(
select r.produk, month(s.tgl_snapshot) bulan, sum(s.saldo) total_saldo
from rekening r
join saldo_bulanan s on r.no_rek = s.no_rek
group by r.produk, month(s.tgl_snapshot)
), cte2 as
(
select *, lag(total_saldo) over(partition by produk order by bulan) saldo_bln_lalu,
total_saldo - lag(total_saldo) over(partition by produk order by bulan) selisih_dr_bln_lalu
from cte
order by produk, bulan
)
select produk, bulan, total_saldo, selisih_dr_bln_lalu, round(100.0*selisih_dr_bln_lalu/nullif(saldo_bln_lalu,0),2) as mom_pct
from cte2;

### karena nasabah narik uangnya ataukah tutup rekening?
with cte as
(
select r.produk, r.`status`,
sum(case when tgl_snapshot = '2026-07-31' then s.saldo else 0 end) tot_jul,
sum(case when tgl_snapshot = '2026-08-31' then s.saldo else 0 end) tot_aug
from rekening r 
join saldo_bulanan s 
on r.no_rek = s.no_rek
group by r.produk, r.`status`
order by r.produk, r.`status`
)
select *, tot_aug - tot_jul as 'selisih saldo'
from cte;

### rasio casa tanpa adanya rekening yg tutup ####################################################3
with pct_table as (
    select 
        month(s.tgl_snapshot) as bulan,
        date_format(s.tgl_snapshot, '%M') as bulan1,
        sum(case when r.produk = 'TABUNGAN' then s.saldo else 0 end) as tabungan,
        sum(case when r.produk = 'GIRO' then s.saldo else 0 end) as giro,
        sum(case when r.produk = 'DEPOSITO' then s.saldo else 0 end) as deposito,
        round(100.0 * sum(case when r.produk in ('TABUNGAN','GIRO') then s.saldo else 0 end) / nullif(sum(s.saldo),0), 2) as pct_casa
    from saldo_bulanan s
    join rekening r on r.no_rek = s.no_rek
    group by MONTH(s.tgl_snapshot), date_format(s.tgl_snapshot, '%M')
),
pct_aktif_table as (
    select 
        month(s.tgl_snapshot) as bulan,
        round(100.0 * sum(case when r.produk in ('TABUNGAN','GIRO') then s.saldo else 0 end) / nullif(sum(s.saldo),0), 2) as pct_casa_aktif
    from saldo_bulanan s
    join rekening r on r.no_rek = s.no_rek
    where r.status = 'aktif'
    group by MONTH(s.tgl_snapshot)
)
select 
    t.*,
    a.pct_casa_aktif,
    t.pct_casa - LAG(t.pct_casa) over (order by t.bulan) as delta_pct
from pct_table t
left join pct_aktif_table a on t.bulan = a.bulan
order by t.bulan asc;

### Yang jadi masalah itu yg nutup rekening
with cte as
(
select month(s.tgl_snapshot) as bulan,
date_format(s.tgl_snapshot, '%M') as bulan1,
round(100.0*sum(case when r.produk in ('TABUNGAN','GIRO') then s.saldo else 0 end)/nullif(sum(s.saldo),0),2) as pct_casa,
round(100.0*sum(case when r.produk in ('TABUNGAN','GIRO') and r.status = 'AKTIF' then s.saldo else 0 end)/
nullif(sum(case when r.status = 'AKTIF' then s.saldo else 0 end),0),2) as pct_casa_aktif
from saldo_bulanan s
join rekening r on r.no_rek = s.no_rek
group by MONTH(s.tgl_snapshot), date_format(s.tgl_snapshot, '%M')
order by MONTH(s.tgl_snapshot) asc
), cte2 as 
(
select bulan, bulan1, pct_casa, pct_casa_aktif, 
lag(pct_casa) over (order by bulan) utuh, 
lag(pct_casa_aktif) over (order by bulan) aktif 
from cte
group by bulan, bulan1
order by bulan, bulan1
), cte_3 as 
(
select *,
pct_casa-utuh as ratio_utuh,
pct_casa_aktif-aktif as ratio_aktif
from cte2
group by bulan, bulan1
order by bulan, bulan1 asc
)
select bulan, 
100.0*(ratio_utuh - ratio_aktif)/ratio_utuh as pct_pengaruh_rekening_tutup_dibbulan_itu
from cte_3
group by bulan, bulan1
order by bulan, bulan1 asc;

## sudah tau kalau agustus itu terjadi penutupan rekening terbesar, tapi dimaana?
select n.segmen, count(*) rek_tutup,
round(100.0*count(*)/sum(count(*)) over(),1) pct_rek_tutup,
sum(s.saldo) saldo_tutup,
round(100.0*sum(s.saldo)/sum(sum(s.saldo)) over(),1) pct_saldo_ilang
from rekening r
join nasabah n on n.cif=r.cif
join saldo_bulanan s on r.no_rek = s.no_rek and s.tgl_snapshot = '2026-07-31'
where r.status = 'TUTUP'
group by n.segmen
order by round(100.0*sum(s.saldo)/sum(sum(s.saldo)) over(),1) desc;

### konsentrasi dana terbaru
with cte as
(
select r.cif,
sum(s.saldo) as total
from rekening r
join saldo_bulanan s 
on r.no_rek = s.no_rek
where s.tgl_snapshot = (select max(tgl_snapshot) from  saldo_bulanan)
group by r.cif
), cte2 as(
select *, row_number() over(order by total desc) `rank`
from cte)
select round(100.0*sum(case when `rank` <=10 then total else 0 end)/sum(total),1) as pct_10
from cte2;

### Rekening baru (dibuka sejak 2025) berasal dari segmen mana, dan seberapa besar kontribusi saldonya?
select n.segmen, 
count(*) jml_rek,
round(100.0*count(*)/sum(count(*)) over(),1) pct_jml_rek,
sum(s.saldo) total_saldo,
round(100.0*sum(s.saldo)/sum(sum(s.saldo))over(),1) pct_saldo
from rekening r
join nasabah n on n.cif = r.cif
join saldo_bulanan s on r.no_rek = s.no_rek and tgl_snapshot = (select max(tgl_snapshot) from saldo_bulanan)
where r.status = 'AKTIF' and r.tgl_buka >= '2025-01-01'
group by n.segmen
order by pct_saldo desc;

### rkening diapke? rule-nys 3 bulan terakhir
with cte as(
select year(tgl_buka) thn_buka,
count(*) jml_rek,
round(avg(s.saldo),1) rerata_saldo_september,
sum(case when exists(
					select 1 from transaksi t
                    where t.no_rek = r.no_rek and t.tgl_trx >= '2026-07-27')
		 then 1 else 0 end) jml_aktif
from rekening r 
join saldo_bulanan s on r.no_rek = s.no_rek and s.tgl_snapshot = (select max(tgl_snapshot) from saldo_bulanan)
where r.`status` = 'aktif' and r.produk <> 'deposito'
group by year(tgl_buka)
order by year(tgl_buka)
) select *, round(100.0*jml_aktif/jml_rek,1) pct_aktif
from cte
group by thn_buka
order by thn_buka;


### rekening dormant (saldo bobo)
select count(*) jml_rek_bobo,
sum(s.saldo) saldo_bobo
from saldo_bulanan s 
join rekening r on r.no_rek = s.no_rek and tgl_snapshot = (select max(tgl_snapshot) from saldo_bulanan)
where r.status = 'aktif' and r.produk <> 'deposito'
and not exists (select 1 from transaksi t
					where t.no_Rek = r.no_Rek and t.tgl_trx >= '2026-07-27');


### berapa percent dormant dari seluruh saldo aktif?
with cte as(
select count(*) total_rek,
sum(case when not exists(select 1 from transaksi t where t.no_rek = r.no_rek and t.tgl_trx>='2026-07-31') then 1 else 0 end) jml_bobo
from rekening r
join saldo_bulanan s on s.no_rek = r.no_rek and tgl_snapshot = (select max(tgl_snapshot) from saldo_bulanan)
where r.status = 'aktif' and r.produk <> 'deposito'
)
select *,
round(100.0*jml_bobo/total_rek,1) pct_bobo from cte
;

