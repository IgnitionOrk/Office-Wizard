-- Created by: Ryan Cunneen, Micah Conway
-- Student number: 3179234, 3232648
-- Date created: 19-Apr-2017
-- Date modified: 1-May-2017
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
DROP PROCEDURE usp_UpdateInventory
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
	SET custOrdID = @salesOrdID, status = 'sold', sellingPrice = ROUND(sellingPrice - (sellingPrice * p.maxDiscount), 2)
	FROM ProductItem pro 
		INNER JOIN Product p 
			ON pro.productID = p.productID
	WHERE pro.itemNo IN(SELECT bl.barcodeID 
					  FROM @barcodeList bl)
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Inserting into the table CustOrdProduct each type of product that was purchase.
--
CREATE PROCEDURE usp_AssignCustOrdProducts @salesOrdID VARCHAR(10),@barcodeList productBarcodes_TVP READONLY
AS
	-- Fourth associate the Products -> CustOrdProduct
	-- Note must determine the unitPurchase Price
	DECLARE @productID VARCHAR(10)
	DECLARE @qty INT
	DECLARE custOrdProductCursor CURSOR FOR
	-- Count quantity, and sum selling price for each product type associated with the customer order.
	SELECT pro.productID,COUNT(pro.productID) AS qty 
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
		FETCH NEXT FROM custOrdProductCursor INTO @productID, @qty
	END
	
	-- Close, and deallocate the cursor
	CLOSE custOrdProductCursor
	DEALLOCATE custOrdProductCursor
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Updates all quantites for each product type.
--
CREATE PROCEDURE usp_UpdateInventory
AS
	UPDATE Product
	SET availQty = (SELECT COUNT(*) FROM product pr, ProductItem pItem WHERE pItem.productID = pr.productID AND pItem.status = 'sold')
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Creates a new Customer order 
--
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
			---------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Firstly 		
			-- Need to calculate the discount,
			SET @totalDiscount = (SELECT SUM(maxDiscount) 
									FROM Product pro, ProductItem pItem, @barcodeList bl 
									WHERE pro.productID = pItem.productID AND pItem.itemNo = bl.barcodeID)
			---------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Secondly
			-- determine the amound due of the customer order. 
			SET @amountDue = (SELECT SUM(sellingPrice)
								FROM ProductItem p , @barcodeList bl
								WHERE p.itemNo = bl.barcodeID)
			-- Apply the discount given (if any)
			SET @amountDue = @amountDue - (@amountDue * @totalDiscount)
			INSERT INTO CustomerOrder VALUES(@salesOrdID,  @employeeID, @customerID, GETDATE(), @totalDiscount, @amountDue, 0.00, 'Awaiting Payment', 'In Store');
			EXECUTE usp_UpdateProductItems @salesOrdID, @barcodeList
			EXECUTE usp_AssignCustOrdProducts @salesOrdID, @barcodeList				
			EXECUTE usp_UpdateInventory
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
	DECLARE @highestID VARCHAR(10) = '00000000';
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
	--if a barcode isnt in the system, return a message saying so
	DECLARE @tempBarcodeID VARCHAR(10);
	DECLARE @atLeastOneValidItem BIT = 0;
	DECLARE itemCheckCursor CURSOR FOR
	SELECT *
	FROM @barcodeList;
	OPEN itemCheckCursor
	FETCH NEXT FROM itemCheckCursor INTO @tempBarcodeID;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF NOT EXISTS (SELECT itemNo FROM ProductItem WHERE itemNo = @tempBarcodeID)
			PRINT('Item number: ' + @tempBarcodeID + ' does not exist');
		ELSE
			SET @atLeastOneValidItem = 1;
		FETCH NEXT FROM itemCheckCursor INTO @tempBarcodeID;
	END
	CLOSE itemCheckCursor;
	DEALLOCATE itemCheckCursor;	

	--at least one item is valid, continue on
	BEGIN TRY 
	
	--if none of the scanned items are valid, give control to catch statement, transaction terminated
	IF @atLeastOneValidItem = 0	
		RAISERROR('No items were valid, transaction was terminated', 15, -1);

	DECLARE @newCustOrdID VARCHAR(10);
	--get a unique ID for the Customer Order ID
	--need to store ID in the non-output variable as errors occur otherwise
	EXECUTE usp_generatePrimaryKey @newCustOrdID OUTPUT;
	SET @salesOrdID = @newCustOrdID;	
	-- The @param @customerID is not null, and it references a customer in the database,
	-- Simply create a new customer order associated with @param @customerID
	IF @customerID IS NOT NULL AND EXISTS (SELECT customerID FROM Customer WHERE customerID = @customerID)
		BEGIN	
			EXECUTE usp_CreateNewCustomerOrder @customerID, @barcodeList, @employeeID, @newCustOrdID;
		END
	-- The @param customerID is not null, and it does reference a customer in the database,
	-- create a new customer.

	ELSE IF  @customerID IS NOT NULL AND NOT EXISTS (SELECT customerID FROM	 Customer WHERE customerID = @customerID)
	    BEGIN
			-- Should have a gender value for as Unspecified but that can be added later O will suffice for now.
			INSERT INTO Customer VALUES(@customerID, DEFAULT,DEFAULT,'', NULL,'', NULL,'O');
			EXECUTE usp_CreateNewCustomerOrder @customerID, @barcodeList, @employeeID, @newCustOrdID;
			PRINT('New customer was created with the provided customer ID');
		END
	-- The customer does not exist in the database, and we simply create a customer order without a customer associated with it. 
	ELSE
		BEGIN
			EXECUTE usp_CreateNewCustomerOrder @customerID, @barcodeList, @employeeID, @newCustOrdID;
		END
	END TRY
	BEGIN CATCH
		PRINT ERROR_MESSAGE()
	END CATCH
GO
