CREATE DATABASE supply_chain
select count(*) from supply_chain_data
select SKU, count(*) AS COUNT
from supply_chain_data
group by SKU
having COUNT(*) > 1;

EXEC sp_rename 'supply_chain_data.[Product_type]', 'product_type', 'COLUMN';
EXEC sp_rename 'supply_chain_data.[Number_of_products_sold]', 'products_sold', 'COLUMN';
EXEC sp_rename 'supply_chain_data.[Revenue_generated]', 'revenue', 'COLUMN';
EXEC sp_rename 'supply_chain_data.[Customer_demographics]', 'customer_type', 'COLUMN';
EXEC sp_rename 'supply_chain_data.[Stock_levels]', 'stock_levels', 'COLUMN';
EXEC sp_rename 'supply_chain_data.[Lead_times]', 'lead_times', 'COLUMN';
EXEC sp_rename 'supply_chain_data.[Order_quantities]', 'order_qty', 'COLUMN';
EXEC sp_rename 'supply_chain_data.[Shipping_times]', 'shipping_time', 'COLUMN';
EXEC sp_rename 'supply_chain_data.[Shipping_carriers]', 'shipping_carrier', 'COLUMN';
EXEC sp_rename 'supply_chain_data.[Shipping_costs]', 'shipping_cost', 'COLUMN';
EXEC sp_rename 'supply_chain_data.[Supplier_name]', 'supplier_name', 'COLUMN';
EXEC sp_rename 'supply_chain_data.[Lead_time]', 'supplier_lead_time', 'COLUMN';
EXEC sp_rename 'supply_chain_data.[Production_volumes]', 'production_volume', 'COLUMN';
EXEC sp_rename 'supply_chain_data.[Manufacturing_lead_time]', 'mfg_lead_time', 'COLUMN';
EXEC sp_rename 'supply_chain_data.[Manufacturing_costs]', 'mfg_cost', 'COLUMN';
EXEC sp_rename 'supply_chain_data.[Inspection_results]', 'inspection_result', 'COLUMN';
EXEC sp_rename 'supply_chain_data.[Defect_rates]', 'defect_rate', 'COLUMN';
EXEC sp_rename 'supply_chain_data.[Transportation_modes]', 'transport_mode', 'COLUMN';
EXEC sp_rename 'supply_chain_data.[Routes]', 'route', 'COLUMN';

select * FROM supply_chain_data;

SELECT 
    SKU,
    product_type,
    price
INTO products
FROM supply_chain_data;

SELECT 
    SKU,
    order_qty,
    revenue,
    shipping_time,
    shipping_cost,
    shipping_carrier
INTO orders
FROM supply_chain_data;

SELECT 
    SKU,
    stock_levels,
    availability
INTO inventory
FROM supply_chain_data;

SELECT 
    SKU,
    supplier_name,
    location,
    supplier_lead_time
INTO suppliers
FROM supply_chain_data;

SELECT
    SKU,
    production_volume,
    mfg_lead_time,
    mfg_cost,
    defect_rate
INTO manufacturing
FROM supply_chain_data;

CREATE VIEW final_dashboard AS
SELECT *,
    YEAR(order_date) AS year,
    MONTH(order_date) AS month,
    DATEPART(QUARTER, order_date) AS quarter,

    CASE 
        WHEN MONTH(order_date) >= 4 THEN YEAR(order_date)
        ELSE YEAR(order_date) - 1
    END AS fiscal_year

FROM (
    SELECT 
        p.SKU,
        p.product_type,
        p.price,

        o.order_qty,
        ROUND(o.revenue,2) AS revenue,
        o.shipping_time,
        ROUND(o.shipping_cost,2) AS shipping_cost,
        o.shipping_carrier,

        i.stock_levels,
        i.availability,

        s.supplier_name,
        s.location,
        s.supplier_lead_time,

        m.production_volume,
        m.mfg_lead_time,
        ROUND(m.mfg_cost,2) AS mfg_cost,
        ROUND(m.defect_rate,2) AS defect_rate,

        DATEADD(
            DAY,
            -(ABS(CHECKSUM(NEWID())) % 365),
            GETDATE()
        ) AS order_date

    FROM products p
    LEFT JOIN orders o 
        ON p.SKU = o.SKU

    LEFT JOIN inventory i 
        ON p.SKU = i.SKU

    LEFT JOIN suppliers s 
        ON p.SKU = s.SKU

    LEFT JOIN manufacturing m 
        ON p.SKU = m.SKU

) base;





ALTER VIEW final_dashboard AS

SELECT *,

    YEAR(order_date) AS year,
    MONTH(order_date) AS month,
    DATENAME(MONTH, order_date) AS month_name,
    DATEPART(QUARTER, order_date) AS quarter,

    CASE 
        WHEN MONTH(order_date) >= 4 THEN YEAR(order_date)
        ELSE YEAR(order_date) - 1
    END AS fiscal_year

FROM (

    SELECT 
        p.SKU,
        p.product_type,
        p.price,

        o.order_qty,
        ROUND(o.revenue, 2) AS revenue,
        o.shipping_time,
        ROUND(o.shipping_cost, 2) AS shipping_cost,
        o.shipping_carrier,

        i.stock_levels,
        i.availability,

        s.supplier_name,
        s.location,
        s.supplier_lead_time,

        m.production_volume,
        m.mfg_lead_time,
        ROUND(m.mfg_cost, 2) AS mfg_cost,
        ROUND(m.defect_rate, 2) AS defect_rate,

        -- Profit
        ROUND(
            o.revenue - (m.mfg_cost + o.shipping_cost),
            2
        ) AS estimated_profit,

        -- Inventory category
        CASE
            WHEN i.stock_levels < 20 THEN 'Low Stock'
            WHEN i.stock_levels < 50 THEN 'Medium Stock'
            ELSE 'Healthy Stock'
        END AS inventory_status,

        -- Shipping category
        CASE
            WHEN o.shipping_time <= 3 THEN 'Fast'
            WHEN o.shipping_time <= 6 THEN 'Moderate'
            ELSE 'Delayed'
        END AS shipping_performance,

        -- Defect category
        CASE
            WHEN m.defect_rate < 2 THEN 'Low Defect'
            WHEN m.defect_rate < 5 THEN 'Moderate Defect'
            ELSE 'High Defect'
        END AS defect_category,

        -- Random date
        DATEADD(
            DAY,
            -(ABS(CHECKSUM(NEWID())) % 365),
            GETDATE()
        ) AS order_date

    FROM products p

    LEFT JOIN orders o
        ON p.SKU = o.SKU

    LEFT JOIN inventory i
        ON p.SKU = i.SKU

    LEFT JOIN suppliers s
        ON p.SKU = s.SKU

    LEFT JOIN manufacturing m
        ON p.SKU = m.SKU

) base;

select * from final_dashboard;