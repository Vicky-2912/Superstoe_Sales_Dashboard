CREATE DATABASE superstore_db;

ALTER TABLE superstore_data
ADD COLUMN Order_Date_Fixed DATE,
ADD COLUMN Ship_Date_Fixed DATE;

UPDATE superstore_data
SET Order_Date_Fixed = STR_TO_DATE(`Order Date`, '%m/%d/%Y'),
    Ship_Date_Fixed = STR_TO_DATE(`Ship Date`, '%m/%d/%Y');
    

-- Query 1: Basic — Total Sales & Profit
SELECT
	SUM(Sales) AS Total_Sales,
	SUM(Profit) AS Total_Profit
FROM superstore_data; 

-- Query 2: Category-wise Performance (GROUP BY)
SELECT
	Category,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    COUNT(*) AS Total_Orders
FROM superstore_data
GROUP BY Category
ORDER BY Total_Sales DESC;

-- Query 3: Top 10 Products by Sales
SELECT
	  `Product Name`,
      SUM(Sales) AS Total_Sales
FROM superstore_data
GROUP BY `Product Name`
ORDER BY Total_Sales DESC
LIMIT 10;

-- Query 4: RANK() — Har Category Mein Products Ko Rank Karo
SELECT
	  Category,
      `Product Name`,
      SUM(Sales) AS Total_Sales,
      RANK() OVER(PARTITION BY Category ORDER BY SUM(Sales) DESC) AS Sales_Rank
FROM superstore_data
GROUP BY Category, `Product Name`
ORDER BY Category, Sales_Rank;
      
-- Query 5: CTE Se Sirf Top Product Per Category Nikalo
WITH Ranked_Products AS (
	SELECT
	  Category,
      `Product Name`,
      SUM(Sales) AS Total_Sales,
      RANK() OVER(PARTITION BY Category ORDER BY SUM(Sales) DESC) AS Sales_Rank
      FROM superstore_data
      GROUP BY Category, `Product Name`
	)
SELECT
	  Category, `Product Name`, Total_Sales
FROM Ranked_Products
WHERE Sales_Rank = 1;
 
 -- Query 6: Year-wise Total Sales (Pehla Step)
 SELECT
	   YEAR(Order_Date_Fixed) AS Order_Year,
       SUM(Sales) AS Total_Sales
FROM superstore_data
GROUP BY YEAR(Order_Date_Fixed)
ORDER BY Order_Year;

-- Query 7: YoY Growth Calculate Karo

WITH YearlySales AS(
	 SELECT
	   YEAR(Order_Date_Fixed) AS Order_Year,
       SUM(Sales) AS Total_Sales
	 FROM superstore_data
	 GROUP BY YEAR(Order_Date_Fixed)
	 ORDER BY Order_Year
     )
SELECT
	 Order_Year,
     Total_Sales,
     LAG(Total_Sales) OVER (ORDER BY Order_Year) AS Previou_Year_Sales,
     ROUND(
           ((Total_Sales - LAG(Total_Sales) OVER (ORDER BY Order_Year)) / LAG(Total_Sales) OVER (ORDER BY Order_Year)) *100, 2
		  ) AS YoY_Growth_Percent
FROM YearlySales
ORDER BY Order_Year;

-- Query 9 : Naya Chhota Table Banao

CREATE TABLE region_targets (
    Region VARCHAR(50),
    Sales_Target DECIMAL(10,2)
);

INSERT INTO region_targets (Region, Sales_Target) VALUES
('East', 250000),
('West', 250000),
('Central', 200000),
('South', 150000);

UPDATE region_targets SET Sales_Target = 700000 WHERE Region = 'West';
UPDATE region_targets SET Sales_Target = 700000 WHERE Region = 'East';
UPDATE region_targets SET Sales_Target = 550000 WHERE Region = 'South';
UPDATE region_targets SET Sales_Target = 500000 WHERE Region = 'Central';
SELECT * FROM region_targets;

-- Query 10 : JOIN Query — Actual Sales vs Target

SELECT
	  s.Region,
      SUM(s.Sales) AS Actual_Sales,
      r.Sales_Target,
      ROUND(SUM(s.Sales) - r.Sales_Target, 2) AS DIfference,
      ROUND((SUM(s.Sales) / r.Sales_Target) * 100, 2) AS Percentage_Of_Target
FROM superstore_data s
JOIN region_targets r ON s.Region = r.Region
GROUP BY s.Region, r.Sales_Target
ORDER BY Percentage_Of_Target DESC;
