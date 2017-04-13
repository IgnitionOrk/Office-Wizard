CREATE PROCEDURE usp_Top10ProfitableProducts
AS
		-- Tables needed to be used:
		-- SupplierOrderProduct
		-- Product
		-- ProductItem
		BEGIN 
			DECLARE @count INT
			-- @count essentially will determine the number of product items Office wizard has on the floor
			SET @count = (SELECT COUNT(*)
									  FROM ProductItem)
			
			-- Insufficient data has been populated in the database to show the top 10.
			IF @count < 10
				BEGIN 
					PRINT 'Can only display top ' + CAST(@count AS CHAR)
				END
			ELSE
				BEGIN
					PRINT 'Displaying top 10'
					SET @count = 10 					
				END
			SELECT DISTINCT(pro.productID), p.pName,100, pro.sellingPrice - pro.costPrice  AS profit
			FROM  Product p, ProductItem pro
			WHERE p.productID = pro.productID
			ORDER BY profit DESC 
		END
GO




EXECUTE usp_Top10ProfitableProducts
DROP PROCEDURE usp_Top10ProfitableProducts