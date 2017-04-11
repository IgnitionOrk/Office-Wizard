/*
	CREATE PROCEDURE usp_top10ProfitableProducts
	AS
		BEGIN TRY 
			-- Tables needed to be used:
			-- SupplierOrderProduct
			-- Product
			-- ProductItem

			SELECT Top 10 p.productID, p.pName, s.qty, (pro.costPrice - pro.sellingPrice) AS profit
			FROM  SupplierOrderProduct s
				JOIN Product p
					ON s.productID = p.productID
				JOIN ProductItem pro
					ON p.prodictID = pro.productID
			ORDER BY profit AESC
		END TRY
		BEGIN CATCH 

		END CATCH

	GO
*/