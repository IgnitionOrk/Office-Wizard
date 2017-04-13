CREATE PROCEDURE usp_Top10ProfitableProducts
AS
		-- Tables needed to be used:
		-- SupplierOrderProduct
		-- Product
		-- ProductItem
		BEGIN 
			SELECT TOP 10 pro.productID, p.pName,100, pro.sellingPrice - pro.costPrice  AS profit
			FROM  Product p, ProductItem pro
			WHERE p.productID = pro.productID
			ORDER BY profit DESC 
		END
GO




EXECUTE usp_Top10ProfitableProducts
DROP PROCEDURE usp_Top10ProfitableProducts