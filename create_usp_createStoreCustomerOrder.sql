-- Created by: Ryan Cunneen
-- Student number: 3179234
-- Date created: 19-Apr-2017
-- Date modified: 27-Apr-2017
EXECUTE sp_dropmessage 50005;
GO
EXECUTE sp_addmessage 50005, 11, 'Error: %s';
GO
---------------------------------------------------------------------------------------------------------------------------------------------------------
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
	DECLARE @productDiscount FLOAT
	DECLARE @productID VARCHAR(10)
	DECLARE productDiscount CURSOR FOR
	SELECT productID, maxDiscount
	FROM Product
	OPEN productDiscount
	FETCH NEXT FROM productDiscount INTO @productID,  @productDiscount		
	WHILE @@FETCH_STATUS = 0			
	BEGIN
		UPDATE ProductItem
		SET custOrdID = @salesOrdID, status = 'sold', sellingPrice = (sellingPrice - (sellingPrice * @productDiscount))
		FROM ProductItem p, @barcodeList bl
		WHERE p.itemNo IN(SELECT bl.barcodeID 
						  FROM @barcodeList bl) 
			  AND p.productID = @productID
		FETCH NEXT FROM productDiscount INTO @productID,  @productDiscount
	END
	CLOSE productDiscount
	DEALLOCATE productDiscount
GO
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Inserting into the table CustOrdProduct each type of product that was purchase.
--
CREATE PROCEDURE usp_AssignCustOrdProducts @salesOrdID VARCHAR(10),@barcodeList productBarcodes_TVP READONLY
AS
	-- Fourth associate the Products -> CustOrdProduct
	-- Note must determine the unitPurchase Price
	INSERT INTO CustOrdProduct (custOrdID, productID, qty, unitPurchasePrice, subtotal)
	SELECT DISTINCT @salesOrdID, pro.productID, 1, 0.0, 0.0
	FROM Product pro
		INNER JOIN ProductItem pItem
			ON pro.productID = pItem.productID	
		INNER JOIN @barcodeList bl
			ON pItem.itemNo = bl.barcodeID	
	WHERE 
		NOT EXISTS (SELECT c.custOrdID,c.productID 
					FROM CustOrdProduct c 
					WHERE c.custOrdID = @salesOrdID AND c.productID = pro.productID)
		AND @salesOrdID = pItem.custOrdID
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Creates a new Customer order 
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
			
			---------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Fifth calculate the new available quantity Office Wizard has for each Product. 
			/*UPDATE Product
			SET availQty = (SELECT COUNT(*) FROM product pr, ProductItem pItem WHERE pItem.productID = pr.productID AND pItem.status = 'sold')
			---------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Lastly insert the new created data.
			---------------------------------------------------------------------------------------------------------------------------------------------------------
			
			---------------------------------------------------------------------------------------------------------------------------------------------------------
			*/
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
			RAISERROR(50005, 16, 1, 'Customer does not exist in the database! Customer has been inserted into the database')			
		END
	-- The customer does not exist in the database, and we simply create a customer order without a customer associated with it. 
	ELSE
		BEGIN
			EXECUTE usp_CreateNewCustomerOrder @customerID, @barcodeList, @employeeID, @salesOrdID
			-- Raise error that is associated with a customer that does not exist in the database.
			RAISERROR(50005, 16, 1, 'Customer does not exist in the database! New customer order has been created without a Customer ')
		END
	END TRY
	BEGIN CATCH
		PRINT ERROR_MESSAGE()
	END CATCH
GO


DECLARE @customer1ID VARCHAR(10)
DECLARE @employeeID VARCHAR(10)
DECLARE @salesOrdID VARCHAR(10)
SET @customer1ID = 'CO0001077'
SET @employeeID = 'E12345'
SET @salesOrdID = '1w43323'
DECLARE @customer1Products AS dbo.productBarcodes_TVP

INSERT INTO @customer1Products VALUES('PI10000019');
INSERT INTO @customer1Products VALUES('PI10000015');
INSERT INTO @customer1Products VALUES('PI10000018');
INSERT INTO @customer1Products VALUES('PI10000021');


EXECUTE usp_createStoreCustomerOrder @customer1ID, @customer1Products, @employeeID, @salesOrdID OUT
GO


DROP PROCEDURE usp_UpdateProductItems
DROP PROCEDURE usp_AssignCustOrdProducts
DROP PROCEDURE usp_CreateNewCustomerOrder
DROP PROCEDURE usp_createStoreCustomerOrder
DROP TYPE productBarcodes_TVP
GO
