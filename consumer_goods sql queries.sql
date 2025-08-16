-- REQUESTS
-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates its
-- business in the APAC region.

select 
	distinct market 	
from dim_customer 
where customer="Atliq Exclusive" and region="APAC";



-- 2. What is the percentage of unique product increase in 2021 vs. 2020? The
-- final output contains these fields:unique_products_2020,unique_products_2021,percentage_chg

with cte1 as(
  select count(distinct product_code) as unique_products_2020 
 from fact_sales_monthly where fiscal_year="2020"),
cte2 as(
  select count(distinct product_code) as unique_products_2021 
 from fact_sales_monthly where fiscal_year="2021")
select *,
  round((unique_products_2021 - unique_products_2020)*100/unique_products_2020,2) as percentage_cng
 from cte1 , cte2;



-- 3. Provide a report with all the unique product counts for each segment and
-- sort them in descending order of product counts. The final output contains
-- 2 fields:segment,product_count

select 
 segment, count( distinct product_code) as product_count 
from dim_product
group by segment 
order by product_count desc;



-- 4. Follow-up: Which segment had the most increase in unique products in
-- 2021 vs 2020? The final output contains these fields:
-- segment,product_count_2020,product_count_2021,difference

WITH unique_product AS (
    SELECT 
        b.segment AS segment,
        COUNT(DISTINCT CASE WHEN fiscal_year = 2020 
                            THEN a.product_code END) AS product_count_2020,
        COUNT(DISTINCT CASE WHEN fiscal_year = 2021 
                            THEN a.product_code END) AS product_count_2021
    FROM fact_sales_monthly AS a
    INNER JOIN dim_product AS b
        ON a.product_code = b.product_code
    GROUP BY b.segment
)
SELECT 
    segment,
    product_count_2020,
    product_count_2021,
    (product_count_2021 - product_count_2020) AS difference
FROM unique_product
ORDER BY difference DESC;



-- 5. Get the products that have the highest and lowest manufacturing costs.
-- The final output should contain these fields,
-- product_code product manufacturing_cost 

select
    p.product_code,p.product,m.manufacturing_cost 
 from dim_product p join fact_manufacturing_cost m using(product_code)
 where manufacturing_cost in
  ((select max(manufacturing_cost) from fact_manufacturing_cost),
  (select min(manufacturing_cost) from fact_manufacturing_cost));



-- 6. Generate a report which contains the top 5 customers who received an
-- average high pre_invoice_discount_pct for the fiscal year 2021 and in the
-- Indian market. The final output contains these fields,
-- customer_code customer average_discount_percentage

select 
  customer_code,customer,
  concat(round(avg(pre_invoice_discount_pct)*100,2),"%") as average_discount_percentage
 from fact_pre_invoice_deductions 
 join dim_customer using(customer_code)
 where fiscal_year=2021 and market="India" 
 group by customer_code,customer
 order by avg(pre_invoice_discount_pct)  desc  
 limit 5;

 

-- 7. Get the complete report of the Gross sales amount for the customer “Atliq
-- Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions.
-- The final report contains these columns:Month Year Gross sales Amount

select 
	monthname(date) as month,
    year(date) as year ,
	round(sum(gross_price*sold_quantity),2) as gross_sales_amount 
  from fact_sales_monthly 
  join fact_gross_price using(product_code,fiscal_year)
  join dim_customer using(customer_code)
  where customer="Atliq Exclusive"
  group by date;




-- 8. In which quarter of 2020, got the maximum total_sold_quantity? The final
-- output contains these fields sorted by the total_sold_quantity,Quarter total_sold_quantity
SELECT CASE
		WHEN MONTH(date) IN (9,10,11) THEN 'Q1' /* Atliq hardware has september as it's first financial month*/
		WHEN MONTH(date) IN (12,1,2) THEN 'Q2'
		WHEN MONTH(date) IN (3,4,5) THEN 'Q3'
		ELSE 'Q4'
		END AS quarters,
	   SUM(sold_quantity) AS total_quantity_sold
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY quarters
ORDER BY total_quantity_sold DESC;



--  9. Which channel helped to bring more gross sales in the fiscal year 2021
-- and the percentage of contribution? The final output contains these fields,
-- channel gross_sales_mln percentage

with cte as(
	select c.channel,round(sum(fm.sold_quantity*fg.gross_price)/1000000,2) as total_gross_sales_mln
  from fact_sales_monthly fm
  join fact_gross_price fg using(product_code,fiscal_year)
  join dim_customer c on c.customer_code=fm.customer_code 
  where fm.fiscal_year="2021"
  group by c.channel)
select
	channel,total_gross_sales_mln,
	round(total_gross_sales_mln*100/sum(total_gross_sales_mln)over(),2) as percentage
  from cte 
  order by percentage desc;

 
 
-- 10. Get the Top 3 products in each division that have a high
-- total_sold_quantity in the fiscal_year 2021? The final output contains these
-- fields,division product_code product total_sold_quantity rank_order

 with cte1 as 
	(select p.division,p.product_code,p.product,sum(sold_quantity) as total_qty
  from fact_sales_monthly s
  join dim_product p on p.product_code=s.product_code
  where fiscal_year=2021 group by p.division, p.product_code,p.product),
cte2 as 
	(select  *,
	dense_rank() over (partition by division order by total_qty desc) as drnk
	from cte1)
select * from cte2 where drnk<=3
