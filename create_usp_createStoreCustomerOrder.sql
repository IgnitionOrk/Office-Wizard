-- Created by: Ryan Cunneen, Micah Conway
-- Student number: 3179234, 3232648
-- Date created: 19-Apr-2017
-- Date modified: 2-May-2017
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- User defined error message
--
EXECUTE sp_dropmessage 50005;
GO
EXECUTE sp_addmessage 50005, 11, 'Error: %s';
GO



--Needed when testing and changing statements
DROP PROCEDURE usp_UpdateProductItems
DROP PROCEDURE usp_AssignCustOrdProducts
DROP PROCEDURE usp_CreateNewCustomerOrder
DROP PROCEDURE usp_generatePrimaryKey
DROP PROCEDURE usp_createStoreCustomerOrder
DROP TYPE productBarcodes_TVP
GO



---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Table-valued parameter
--
CREATE TYPE productBarcodes_TVP AS TABLE
(
	barcodeID VARCHAR(10),
	PRIMARY KEY(barcodeID)
);
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Updates all the Product items so they are associated with a Customer order.
--
CREATE PROCEDURE usp_UpdateProductItems @salesOrdID VARCHAR(10), @barcodeList productBarcodes_TVP READONLY
AS 
	-- Essentially we are going through the ProductItem table, and determine if that ProductItem's itemNo
	-- is found in the barcodeList, and retrieving max discount for each type of Product. 
	UPDATE ProductItem
	SET custOrdID = @salesOrdID, ProductItem.status = 'sold', sellingPrice = ROUND(sellingPrice - (sellingPrice * p.maxDiscount), 2)
	FROM ProductItem pro 
		INNER JOIN Product p 
			ON pro.productID = p.productID
	WHERE pro.itemNo IN(SELECT bl.barcodeID 
					  FROM @barcodeList bl)
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Inserting into the table CustOrdProduct each type of product that was purchased.
CREATE PROCEDURE usp_AssignCustOrdProducts @salesOrdID VARCHAR(10),@barcodeList productBarcodes_TVP READONLY
AS
	-- Fourth associate the Products -> CustOrdProduct
	-- Note must determine the unitPurchase Price
	DECLARE @productID VARCHAR(10)
	DECLARE @qty INT --quanity of product purchased in this order
	DECLARE @updatedQuantity INT; --quantity of product available after order made
	DECLARE custOrdProductCursor CURSOR FOR
	-- Count quantity, and sum selling price for each product type associated with the customer order.
	SELECT pro.productID, COUNT(pro.productID) AS qty 
	FROM ProductItem pro
		INNER JOIN @barcodeList bl
			ON pro.itemNo = bl.barcodeID
	GROUP BY pro.productID;
	-- End of cursor
	---------------------------------------------------------------------------------------------------------------------------------------------------------
	OPEN custOrdProductCursor
	FETCH NEXT FROM custOrdProductCursor INTO @productID,  @qty
	WHILE @@FETCH_STATUS = 0
	BEGIN 
		INSERT INTO CustOrdProduct (custOrdID, productID, qty, unitPurchasePrice, subtotal)
		SELECT DISTINCT 
			@salesOrdID, 
			pro.productID, 
			@qty,
			pro.sellingPrice AS unitPurchasePrice,
			(@qty * pro.sellingPrice) AS subtotal
		FROM ProductItem pro
			INNER JOIN @barcodeList bl
				ON pro.itemNo = bl.barcodeID	
		WHERE 
			NOT EXISTS (SELECT c.custOrdID,c.productID 
						FROM CustOrdProduct c 
						WHERE c.custOrdID = @salesOrdID AND c.productID = pro.productID)
			AND @salesOrdID = pro.custOrdID
			AND pro.productID = @productID
		
		--update available quantity of the product
		SET @updatedQuantity = (SELECT (availQty - @qty) FROM Product WHERE productID = @productID);
		UPDATE Product SET availQty = @updatedQuantity WHERE productID = @productID;
		IF @updatedQuantity = 0 --if available qty is 0, set product to out of stock
			UPDATE Product SET pStatus = 'Out of stock' WHERE productID = @productID;
		
		FETCH NEXT FROM custOrdProductCursor INTO @productID, @qty
	END
	
	-- Close, and deallocate the cursor
	CLOSE custOrdProductCursor
	DEALLOCATE custOrdProductCursor
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Creates a new Customer order 
CREATE PROCEDURE usp_CreateNewCustomerOrder
	@customerID VARCHAR(10), 
	@barcodeList productBarcodes_TVP READONLY, 
	@employeeID VARCHAR(10),
	@salesOrdID VARCHAR(10)
AS	
	BEGIN TRY
	-- Checking if the table-valued parameter is empty.
	 IF NOT EXISTS (SELECT * FROM @barcodeList)
		BEGIN
			RAISERROR(50005, 16, 1, 'Table-valued parameter is empty')
		END 
	ELSE
		BEGIN 
			DECLARE @amountDue FLOAT
			DECLARE @totalDiscount FLOAT

			--get total discount for order(sum of: each item's price multiplied by discount)
			SET @totalDiscount = (SELECT SUM(pro.unitPrice * pro.maxDiscount)
								FROM Product pro, ProductItem pItem, @barcodeList bl 
								WHERE pro.productID = pItem.productID AND pItem.itemNo = bl.barcodeID);			
			--get total amount that woudld've been due without discount
			SET @amountDue = (SELECT SUM(p.sellingPrice)
								FROM ProductItem p , @barcodeList bl
								WHERE p.itemNo = bl.barcodeID)
			--then subtract away discount
			SET @amountDue = @amountDue - @totalDiscount;

			INSERT INTO CustomerOrder VALUES(@salesOrdID,  @employeeID, @customerID, GETDATE(), @totalDiscount, @amountDue, 0.00, 'Awaiting Payment', 'In Store');
			EXECUTE usp_UpdateProductItems @salesOrdID, @barcodeList
			EXECUTE usp_AssignCustOrdProducts @salesOrdID, @barcodeList				
		END
	END TRY
	BEGIN CATCH 
		PRINT ERROR_MESSAGE()
	END CATCH
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------

--finds the highest customer order ID in the database, increments it by 1 and uses that for the new order
CREATE PROCEDURE usp_generatePrimaryKey @newID VARCHAR(10) OUTPUT
AS
	DECLARE @highestID VARCHAR(10) = '00000000'; --default to compare to when searching for max
	DECLARE @tempID VARCHAR(10);

	--create cursor with custOrdIDs
	DECLARE cursorIDs CURSOR FOR
	SELECT custOrdID
	FROM CustomerOrder;
BEGIN
	OPEN cursorIDs
	FETCH NEXT FROM cursorIDs INTO @tempID
	WHILE @@FETCH_STATUS = 0
	BEGIN
		--remove front 2 characters so we can do integer comparison and to increment by 1 for newID
		SET @tempID = SUBSTRING(@tempID, 3, 10);
		--find highest ID
		IF @tempID >  @highestID
			SET @highestID = @tempID;			
		FETCH NEXT FROM cursorIDs INTO @tempID
	END
	CLOSE cursorIDs   
	DEALLOCATE cursorIDs	--close and remove cursor

	--increment highest ID by 1, pad zeroes on the left hand side and add the 'CO' to identify as a customer order ID
	SET @newID = @highestID+1;
	SET @newID = RIGHT('0000000' +  @newID, 7);
	SET @newID = LEFT('CO' + @newID, 10);	
END;
GO


---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Either creates a new Customer and Customer order or a new Customer order (regardless if the customerID is null or not).
CREATE PROCEDURE  usp_createStoreCustomerOrder 
	@customerID VARCHAR(10), 
	@barcodeList productBarcodes_TVP READONLY, 
	@employeeID VARCHAR(10),
	@salesOrdID VARCHAR(10) OUTPUT
AS

	--if a barcode isnt in the system or has been sold already, must inform user and remove from TVP
	DECLARE @tempBarcodeID VARCHAR(10);
	DECLARE @atLeastOneValidItem BIT = 0;
	DECLARE @statusCheck VARCHAR(10); --used to check for if item hasn't already been sold
	DECLARE @barcodeListNew AS dbo.productBarcodes_TVP --values which exist in database and haven't been sold yet are added here
	
	--create cursor to check valid barcodes
	DECLARE itemCheckCursor CURSOR FOR
	SELECT *
	FROM @barcodeList;
	
	--open cursor and loop through
	OPEN itemCheckCursor
	FETCH NEXT FROM itemCheckCursor INTO @tempBarcodeID;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		--if item doesn't exist in database, let user know
		IF NOT EXISTS (SELECT itemNo FROM ProductItem WHERE itemNo = @tempBarcodeID)
		BEGIN
			PRINT 'Item number: ' + @tempBarcodeID + ' does not exist';
		END
		ELSE 
		BEGIN	
			--following block checks if item has already been sold - if it has, delete it from order, else, add it to order	
			SET @statusCheck = (SELECT ProductItem.status FROM ProductItem WHERE itemNo = @tempBarcodeID);
			IF @statusCheck = 'sold'
			BEGIN
				PRINT 'Item number: ' + @tempBarcodeID + ' has already been sold and has been removed from the order';
			END
			ELSE --item hasn't already been sold
			BEGIN			
				SET @atLeastOneValidItem = 1;				
				INSERT INTO @barcodeListNew VALUES(@tempBarcodeID);
			END			
		END
		FETCH NEXT FROM itemCheckCursor INTO @tempBarcodeID;
	END
	CLOSE itemCheckCursor;
	DEALLOCATE itemCheckCursor;	

	BEGIN TRY 		
		--if none of the scanned items are valid, give control to catch statement, transaction terminated
		IF @atLeastOneValidItem = 0	
			RAISERROR('No items were valid, transaction was terminated', 15, -1);		

		--get a unique ID for the Customer Order ID
		--need to store ID in the non-output variable as errors occur otherwise
		DECLARE @newCustOrdID VARCHAR(10);
		EXECUTE usp_generatePrimaryKey @newCustOrdID OUTPUT;
		SET @salesOrdID = @newCustOrdID;	
		
		-- The @param @customerID is not null, and it references a customer in the database,
		-- Simply create a new customer order associated with @param @customerID
		IF @customerID IS NOT NULL AND EXISTS (SELECT customerID FROM Customer WHERE customerID = @customerID)
			BEGIN	
				EXECUTE usp_CreateNewCustomerOrder @customerID, @barcodeListNew, @employeeID, @newCustOrdID;
			END
		
		-- The @param customerID is not null, and it does reference a customer in the database,
		-- create a new customer.
		ELSE IF  @customerID IS NOT NULL AND NOT EXISTS (SELECT customerID FROM	 Customer WHERE customerID = @customerID)
			BEGIN
				-- Should have a gender value for as Unspecified but that can be added later, O will suffice for now.
				INSERT INTO Customer VALUES(@customerID, DEFAULT,DEFAULT,'', NULL,'', NULL,'O');
				EXECUTE usp_CreateNewCustomerOrder @customerID, @barcodeListNew, @employeeID, @newCustOrdID;	
				PRINT('New customer was created with the provided customer ID');		
			END

		-- The customer does not exist in the database, and we simply create a customer order without a customer associated with it. 
		ELSE
			BEGIN
				EXECUTE usp_CreateNewCustomerOrder @customerID, @barcodeListNew, @employeeID, @newCustOrdID;
			END
	END TRY
	BEGIN CATCH
		PRINT ERROR_MESSAGE()
	END CATCH
GO
