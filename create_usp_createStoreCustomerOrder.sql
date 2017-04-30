-- Created by: Ryan Cunneen
-- Student number: 3179234
-- Date created: 19-Apr-2017
-- Date modified: 29-Apr-2017
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- User defined error message
--
EXECUTE sp_dropmessage 50005;
GO
EXECUTE sp_addmessage 50005, 11, 'Error: %s';
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
	@salesOrdID VARCHAR(10) OUTPUT
AS
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

	INSERT INTO CustomerOrder VALUES(@salesOrdID,  @employeeID, @customerID, GETDATE(), @totalDiscount, @amountDue, 0.00, 'Awaiting Payment', 'Phone');

	EXECUTE usp_UpdateProductItems @salesOrdID, @barcodeList

	EXECUTE usp_AssignCustOrdProducts @salesOrdID, @barcodeList		
			
	EXECUTE usp_UpdateInventory
GO



---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Either creates a new Customer or a new Customer order (regardless if the customerID is null or not).
CREATE PROCEDURE  usp_createStoreCustomerOrder 
	@customerID VARCHAR(10), 
	@barcodeList productBarcodes_TVP READONLY, 
	@employeeID VARCHAR(10),
	@salesOrdID VARCHAR(10) OUTPUT
AS
	BEGIN TRY 
	-- The @param @customerID is not null, and it references a customer in the database,
	-- Simply create a new customer order associated with @param @customerID
	IF @customerID IS NOT NULL AND EXISTS (SELECT customerID FROM Customer WHERE customerID = @customerID)
		BEGIN	
			EXECUTE usp_CreateNewCustomerOrder @customerID, @barcodeList, @employeeID, @salesOrdID
		END
	-- The @param customerID is not null, and it does reference a customer in the database,
	-- create a new customer.

	ELSE IF  @customerID IS NOT NULL AND NOT EXISTS (SELECT customerID FROM	 Customer WHERE customerID = @customerID)
	    BEGIN
			-- Should have a gender value for as Unspecified but that can be added later O will suffice for now.
			INSERT INTO Customer VALUES(@customerID, DEFAULT,DEFAULT,'', NULL,'', NULL,'O');
			-- Raise error that is associated with a customer that does not exist in the database.
			RAISERROR(50005, 16, 1, 'Customer ID does not exist in the database! A new customer has been inserted into the database')			
		END
	-- The customer does not exist in the database, and we simply create a customer order without a customer associated with it. 
	ELSE
		BEGIN
			EXECUTE usp_CreateNewCustomerOrder @customerID, @barcodeList, @employeeID, @salesOrdID
			-- Raise error that is associated with a customer that does not exist in the database.
			RAISERROR(50005, 16, 1, 'Customer ID is NULL, therefore, it does not exist in the database! New customer order has been created without a customer ')
		END
	END TRY
	BEGIN CATCH
		PRINT ERROR_MESSAGE()
	END CATCH
GO


DECLARE @customer1ID VARCHAR(10)
DECLARE @employeeID VARCHAR(10)
DECLARE @salesOrdID VARCHAR(10)

SET @customer1ID = NULL
SET @employeeID = 'E12345'
SET @salesOrdID = 'CO00002200'

DECLARE @customer1Products AS dbo.productBarcodes_TVP

INSERT INTO @customer1Products VALUES('PI10000019');
INSERT INTO @customer1Products VALUES('PI10000018');
INSERT INTO @customer1Products VALUES('PI10001001');
INSERT INTO @customer1Products VALUES('PI10001222');
INSERT INTO @customer1Products VALUES('PI00001301');
INSERT INTO @customer1Products VALUES('PI00001302');
INSERT INTO @customer1Products VALUES('PI10000097');
INSERT INTO @customer1Products VALUES('PI10000098');



EXECUTE usp_createStoreCustomerOrder @customer1ID, @customer1Products, @employeeID, @salesOrdID OUT
GO


SELECT * FROM CustOrdProduct

DROP PROCEDURE usp_UpdateProductItems
DROP PROCEDURE usp_AssignCustOrdProducts
DROP PROCEDURE usp_UpdateInventory
DROP PROCEDURE usp_CreateNewCustomerOrder
DROP PROCEDURE usp_createStoreCustomerOrder
DROP TYPE productBarcodes_TVP
GO