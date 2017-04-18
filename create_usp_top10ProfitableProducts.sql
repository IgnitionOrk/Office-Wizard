-- Created by: Ryan Cunneen
-- Student number: 3179234
-- Date created: 18-Apr-2017
-- Date modified: 18-Apr-2017
DROP TABLE productQuantityProfit

CREATE TABLE productQuantityProfit(
	productID VARCHAR(10),
	pName VARCHAR(50),
	sQuantity INT, 
	profit FLOAT
);
GO

CREATE PROCEDURE usp_Top10ProfitableProducts
AS
	-- Table used by procedure:
	-- Product
	-- CustOrdProduct
	--ProductItem
	DECLARE @productID VARCHAR(10)
	DECLARE @pName VARCHAR(50)
	DECLARE @qty INT
	DECLARE @profit FLOAT

	-- Declaring our new Cursor that will store only productIDs
	-- Why? Because we can determine which products were sold, and how many.
	DECLARE cProduct CURSOR
	FOR
	SELECT productID
	FROM Product
	FOR READ ONLY

	-- Open, and populate the Cursor
	OPEN cProduct

	-- Retrieve the first row from the Cursor
	FETCH NEXT FROM cProduct INTO @productID


	-- For each productID in the Cursor we determine the pName, how many were sold
	-- And the total pricing by adding the sellingPrice - costPrice.
	WHILE @@FETCH_STATUS  = 0
		BEGIN

			-- There will be some products that have not been sold.
			-- Therefore, there quantity will be null.
			SET @qty = (SELECT SUM(qty) 
							FROM Product 
							INNER JOIN CustOrdProduct 
								ON Product.productID = CustOrdProduct.productID
							WHERE Product.productID = @productID)


			-- Determine if the variable @qty is null, so we can determine the rest of the variables used.
			-- We are saving time checking if @qty is null.
			IF @qty IS NOT NULL
			BEGIN
					SET @pName = (SELECT pName 
												FROM Product 
												WHERE productID = @productID) 

					 -- Sum the profit made, by finding all the product items that were sold by productID
					 -- Product item is the physically (single) item. Each item will have a unique barcode. 
					 SET @profit = (SELECT SUM(sellingPrice - costPrice )
											 FROM ProductItem 
											 WHERE productID = @productID)

					 -- Insert into our temporary table.
					 INSERT INTO productQuantityProfit VALUES(@productID, @pName, @qty,@profit); 
			END


			-- Fetching the next row in the Cursor
			FETCH NEXT FROM cProduct INTO @productID
	END	

	CLOSE cProduct

	-- Destroy the Cursor reference
	DEALLOCATE cProduct	


	-- View the top 10 most profitable products 
	-- Note will also sort in 'descending order'
	SELECT TOP 10 * 
	FROM productQuantityProfit
	ORDER BY profit DESC
GO


EXECUTE usp_Top10ProfitableProducts
GO


DROP PROCEDURE usp_Top10ProfitableProducts