CREATE PROCEDURE usp_Top10ProfitableProducts
AS
/*
		-- Tables needed to be used:
		-- SupplierOrderProduct
		-- Product
		-- ProductItem
		BEGIN TRY 
			DECLARE @count INT
			SET @count = (SELECT COUNT(*) 
									  FROM SupplierOrderProduct s
										JOIN Product p
											ON s.productID = p.productID
										JOIN ProductItem pro
											ON p.prodictID = pro.productID)
			
			-- Insufficient data has been populated in the database to show the top 10.
			IF @count < 10
				BEGIN 
					PRINT 'Can only display top ' + CAST(@count AS CHAR)
					SELECT TOP @count p.productID, p.pName, s.qty, (pro.costPrice - pro.sellingPrice) AS profit
						FROM  SupplierOrderProduct s
							JOIN Product p
								ON s.productID = p.productID
							JOIN ProductItem pro
								ON p.prodictID = pro.productID
						ORDER BY profit AESC
				END
			ELSE
				BEGIN 					
					SELECT TOP 10 p.productID, p.pName, s.qty, (pro.costPrice - pro.sellingPrice) AS profit
					FROM  SupplierOrderProduct s
						JOIN Product p
							ON s.productID = p.productID
						JOIN ProductItem pro
							ON p.prodictID = pro.productID
					ORDER BY profit AESC
				END
		END TRY
		BEGIN CATCH 

		END CATCH
*/

GO