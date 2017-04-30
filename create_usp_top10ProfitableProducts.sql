-- Created by: Micah Conway
-- Student number: 3232648
-- Date created: 19-Apr-2017
-- Date modified: 1-May-2017
-- Gets the 10 products, less if there are less than 10, that have made the most profit

CREATE PROCEDURE usp_top10ProfitableProducts
AS
	DECLARE @pID varchar(10);
	DECLARE @productName char(40);
	DECLARE @qtySold int;
	DECLARE @totalProfit float;

	--Cursor so that we can iterate through the data to be selected
	DECLARE pItems CURSOR FOR
	SELECT TOP 10 ProductItem.productID, Product.pName, COUNT(*), SUM(ProductItem.sellingPrice - ProductItem.costPrice) AS profit
	FROM ProductItem, Product
	WHERE ProductItem.productID = Product.productID AND productItem.status = 'sold'	-- we only want the products that were sold, as profit can only be made on sold items
	GROUP BY ProductItem.productID, Product.pName
	ORDER BY profit DESC;
	
	BEGIN
		PRINT ('Product ID		Product Name							Quantity Sold					Total Profit'); --column headers
		OPEN pItems
		FETCH NEXT FROM pItems INTO @pID, @productName, @qtySold, @totalProfit

		WHILE @@FETCH_STATUS = 0	--while there are more lines to read from the cursor
		BEGIN
			PRINT (@pID + '			' + @productName + '	' + CAST(@qtySold AS CHAR) + '	' + CAST(@totalProfit AS CHAR));	--print the data we need

			FETCH NEXT FROM pItems INTO @pID, @productName, @qtySold, @totalProfit	--loop
		END
	CLOSE pItems   
	DEALLOCATE pItems	--close and remove cursor
	END;
GO
