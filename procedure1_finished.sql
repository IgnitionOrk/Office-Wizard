-- Created by: Micah Conway
-- Student number: 3232648
-- Date created: 19-Apr-2017
-- Date modified: 20-Apr-2017

CREATE PROCEDURE usp_top10ProfitableProducts
AS
	DECLARE @pID varchar(10);
	DECLARE @productName varchar(50);
	DECLARE @qtySold int;
	DECLARE @totalProfit float;

	DECLARE pItems CURSOR FOR
		SELECT TOP 10 ProductItem.productID, Product.pName, COUNT(*), SUM(ProductItem.sellingPrice - ProductItem.costPrice) AS profit
		FROM ProductItem, Product
		WHERE ProductItem.productID = Product.productID AND productItem.status = 'sold'
		GROUP BY ProductItem.productID, Product.pName
		ORDER BY profit;
BEGIN
	OPEN pItems
	FETCH NEXT FROM pItems INTO @pID, @productName, @qtySold, @totalProfit

	WHILE @@FETCH_STATUS = 0
	BEGIN
		PRINT (@pID + ' ' + @productName + ' ' + CAST(@qtySold AS CHAR) + ' Total profit: ' + CAST(@totalProfit AS CHAR));

		FETCH NEXT FROM pItems INTO @pID, @productName, @qtySold, @totalProfit
	END

	CLOSE pItems   
	DEALLOCATE pItems
	
END;

GO

EXECUTE usp_top10ProfitableProducts;

DROP PROCEDURE usp_top10ProfitableProducts;
