-- Created by: Ryan Cunneen
-- Student number: 3179234
-- Date created: 19-Apr-2017
-- Date modified: 27-Apr-2017

EXECUTE sp_dropmessage 50005;
GO
EXECUTE sp_addmessage 50005, 11, 'Error: %s';
GO

CREATE TYPE productBarcodes_TVP AS TABLE
(
	barcodeID VARCHAR(10),
	PRIMARY KEY(barcodeID)
);
GO


CREATE PROCEDURE usp_CreateNewOrder
	@customerID VARCHAR(10), 
	@barcodeList productBarcodes_TVP READONLY, 
	@employeeID VARCHAR(10),
	@salesOrdID VARCHAR(10) OUTPUT
AS
			DECLARE @amountDue FLOAT
			DECLARE @productID VARCHAR(10)
			DECLARE @productDiscount FLOAT
			DECLARE @totalDiscount FLOAT
			DECLARE @barcode VARCHAR(10)
			DECLARE productDiscount CURSOR FOR
			SELECT productID, maxDiscount
			FROM Product
			OPEN productDiscount
			-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Firstly 		
			-- Need to calculate the discount,
			SET @totalDiscount = (SELECT SUM(maxDiscount) 
												  FROM Product pro, ProductItem pItem, @barcodeList bl 
												  WHERE pro.productID = pItem.productID AND pItem.itemNo = bl.barcodeID)
			PRINT 'a'
			-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Secondly
			-- determine the amound due of the customer order. 
			SET @amountDue = (SELECT SUM(sellingPrice)
									FROM ProductItem p , @barcodeList bl
									WHERE p.itemNo IN (SELECT bl.barcodeID FROM @barcodeList bl))
			PRINT 'b'
			-- Apply the discount given (if any)
			SET @amountDue = @amountDue - (@amountDue * @totalDiscount)
			PRINT 'c'


				-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Thirdly we update the product items that are associated with the newly created customer order (status = sold), and sellingPrice. 
			/*FETCH NEXT FROM productDiscount INTO @productID,  @productDiscount
		
			WHILE @@FETCH_STATUS = 0			
			BEGIN
				UPDATE ProductItem
				SET custOrdID = @salesOrdID, status = 'sold', sellingPrice = (sellingPrice - (sellingPrice * @productDiscount))
				SELECT custOrdID, status, sellingPrice
				FROM ProductItem p, @barcodeList bl
				WHERE p.itemNo = bl.barcodeID AND p.productID = @productID

				FETCH NEXT FROM productDiscount INTO @productID,  @productDiscount
			END
			*/
			PRINT 'l'
			-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Fourth associate the Products -> CustOrdProduct
			-- Note must determine the unitPurchase Price
			INSERT INTO CustOrdProduct (custOrdID, productID, qty, unitPurchasePrice, subtotal)
			SELECT 
				@salesOrdID, 
				pro.productID,
				-- Count all the Product Items that are a particular Product, and is found in the @barcodeList.
				(SELECT COUNT(*) FROM ProductItem WHERE productID = p.productID AND custOrdID = p.custOrdID),

				0.0, -- Need to calculate the unitPurchasePrice 

				-- Calculating the subtotal by adding all the sellingPrices of each Product Item that is a particular Product, and is found in @barcodeList.
				-- subtotal is the total price for a particular Product.
				(SELECT SUM(sellingPrice) FROM ProductItem WHERE productID = p.productID AND itemNo IN(SELECT barcodeID FROM @barcodeList)) 
			FROM Product pro, ProductItem p, @barcodeList bl
			WHERE NOT EXISTS (SELECT custOrdID,productID FROM CustOrdProduct)
			PRINT 'e'
			-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Fifth calculate the new available quantity Office Wizard has for each Product. 
			UPDATE Product
			SET availQty = (SELECT COUNT(*) FROM product pr, ProductItem pItem WHERE pItem.productID = pr.productID AND pItem.status = 'sold')
			PRINT 'f'
			-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Lastly insert the new created data.
			PRINT 'g'
			-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- The values will probably needed to be change. 
			INSERT INTO CustomerOrder VALUES(@salesOrdID,  @employeeID, @customerID, GETDATE(), @totalDiscount, @amountDue, 0.00, 'Awaiting Payment', 'Phone');
		
			-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			CLOSE productDiscount
			DEALLOCATE productDiscount
GO




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
			PRINT 'HERE'
			EXECUTE usp_CreateNewOrder @customerID, @barcodeList, @employeeID, @salesOrdID
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

			EXECUTE usp_CreateNewOrder @customerID, @barcodeList, @employeeID, @salesOrdID

			-- Raise error that is associated with a customer that does not exist in the database.
			RAISERROR(50005, 16, 1, 'Customer does not exist in the database! New customer order has been created without a Customer ')
		END
	END TRY

	BEGIN CATCH
		PRINT ERROR_MESSAGE()
	END CATCH
GO
/*
DROP PROCEDURE usp_CreateNewOrder
DROP PROCEDURE usp_createStoreCustomerOrder
DROP TYPE productBarcodes_TVP
*/