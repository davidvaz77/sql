-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

--DROP TABLE vendor_product_list

CREATE TEMPORARY TABLE vendor_product_list AS 
SELECT vendor_id,
	   product_id, 
	   original_price
	   
FROM vendor_inventory
GROUP BY vendor_id, product_id; 

-- Checking the state of the table   
SELECT * 
FROM vendor_product_list;

--Adding Vendor name to the table 
ALTER TABLE vendor_product_list
ADD COLUMN vendor_name VARCHAR(255);

--updating the vendor name list 
UPDATE vendor_product_list
SET vendor_name = (
    SELECT v.vendor_name
    FROM vendor AS v
    WHERE v.vendor_id = vendor_product_list.vendor_id
);

--Adding the product names to the table 
ALTER TABLE vendor_product_list
ADD COLUMN product_name VARCHAR(255);

--Updating th prouct names in the list 
UPDATE vendor_product_list
SET product_name = (
	SELECT p.product_name
	FROM product as p
	WHERE p.product_id = vendor_product_list.product_id
);

--Adding the quantity to the table 
ALTER TABLE vendor_product_list
ADD COLUMN quantity DECIMAL (16,2);

UPDATE vendor_product_list
SET quantity = 5
	
--Adding the sales to the table 
ALTER TABLE vendor_product_list
ADD COLUMN sales DECIMAL (16,2);

--Update the sales number 

UPDATE vendor_product_list
SET sales = (original_price * quantity) 
	
WITH customer_count AS (
	SELECT COUNT(*) AS total_customers
	FROM customer
), 
vendor_sales AS (
    SELECT vendor_id, product_id, vendor_name, product_name, sales
    FROM vendor_product_list
)

SELECT v.vendor_name, v.product_name,
	   v.sales * c.total_customers as total_revenue --getting the sales X number of total customers 

FROM vendor_sales as v 
CROSS JOIN customer_count as c 
ORDER BY v.vendor_name, v.product_name



-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

CREATE TABLE product_units AS
SELECT *, 
       CURRENT_TIMESTAMP AS snapshot_timestamp
FROM product
WHERE product_qty_type = 'unit';

INSERT INTO product_units (product_id, product_name,product_size, product_category_id, product_qty_type, snapshot_timestamp)
VALUES (91, 'Apple Pie', '10oz' ,'1' ,'unit', CURRENT_TIMESTAMP);



/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

INSERT INTO product_units (product_id, product_name,product_size, product_category_id, product_qty_type, snapshot_timestamp)
VALUES (91, 'Apple Pie', '10oz' ,'1' ,'unit', CURRENT_TIMESTAMP);

-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/

DELETE FROM product_units
WHERE product_name = 'Apple Pie' 
AND snapshot_timestamp = '2024-09-22 18:57:04'

-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */

ALTER TABLE product_units
ADD current_quantity INT;

UPDATE product_units
SET current_quantity = (
    SELECT COALESCE(v.quantity, 0)
    FROM vendor_inventory AS v
    WHERE v.product_id = product_units.product_id
    ORDER BY v.market_date DESC
    LIMIT 1
)
WHERE product_id IN (
    SELECT DISTINCT product_id
    FROM vendor_inventory
);

