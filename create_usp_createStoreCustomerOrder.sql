-- Created by: Ryan Cunneen
-- Student number: 3179234
-- Date created: 19-Apr-2017
-- Date modified: 27-Apr-2017
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
			DECLARE @discount FLOAT
			DECLARE @barcode VARCHAR(10)
			-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Firstly 		
			-- Need to calculate the discount,
			-- Some how calculate discount

			-- Secondly
			-- determine the amound due of the customer order. 
			SET @amountDue = (SELECT SUM(sellingPrice)
									FROM ProductItem p , @barcodeList bl
									WHERE p.itemNo =  bl.barcodeID)

			-- Apply the discount given (if any)
			SET @amountDue = @amountDue - (@amountDue * @discount)
			-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Thirdly we update the product items that are associated with the newly created customer order (status = sold), and sellingPrice. 
			UPDATE ProductItem
			SET custOrdID = @salesOrdID, status = 'sold', sellingPrice = (sellingPrice - (sellingPrice * @discount))
			SELECT custOrdID, status, sellingPrice
			FROM ProductItem p, @barcodeList bl
			WHERE p.itemNo = bl.barcodeID

			-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Fourth associate the Products -> CustOrdProduct
			-- Note must determine the unitPurchase Price
			INSERT INTO CustOrdProduct (custOrdID, productID, qty, unitPurchasePrice, subtotal)
			SELECT 
				@salesOrdID, 
				p.productID,
				(SELECT COUNT(*) FROM ProductItem p2 WHERE p2.productID = p.productID), -- Determining the quantity
				0.0, -- Need to calculate the unitPurchasePrice 
				(SELECT SUM(sellingPrice) FROM ProductItem p3 WHERE p3.productID = p.productID) -- Calculating the subtotal
			FROM ProductItem p, @barcodeList bl
			WHERE p.itemNo = bl.barcodeID


			-- Fifth calculate the new available quantity Office Wizard has for each Product. 
			/*
					IMPORTANT!!!
			*/
			-- So maybe add another table into the database (called Inventory) which stores the number of productItems (associated with each Product) Office Wizard has in stock at the time.
			-- As I'm not sure we should we should be updating Product, as the availQty is associated with the number of items in inventory at the Supplier, not the number of items in Office Wizard. 
			UPDATE Product
			SET availQty = (SELECT COUNT(*) FROM product pr, ProductItem pItem WHERE pItem.productID = pr.productID AND pItem.status = 'sold')

			-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Lastly insert the new created data.
			INSERT INTO CustomerOrder VALUES(@salesOrdID,  @employeeID, @customerID, GETDATE(), @discount, @amountDue, 0.00, 'Awaiting Payment', 'Phone');
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
			EXECUTE usp_CreateNewOrder @customerID, @barcodeList, @employeeID, @salesOrdID
		END
	-- The @param customerID is not null, and it does reference a customer in the database,
	-- create a new customer.
	ELSE IF  @customerID IS NOT NULL AND NOT EXISTS (SELECT customerID FROM	 Customer WHERE customerID = @customerID)
	    BEGIN
			-- Should have a gender value for as Unspecified but that can be added later O will suffice for now.
			INSERT INTO Customer VALUES(@customerID, DEFAULT,DEFAULT,'', NULL,'', NULL,'O');
		END
	-- The customer does not exist in the database, and we simply create a customer order without a customer associated with it. 
	ELSE
		BEGIN
			EXECUTE usp_CreateNewOrder @customerID, @barcodeList, @employeeID, @salesOrdID
		END
	END TRY
	BEGIN CATCH
		
	END CATCH
GO



DROP PROCEDURE usp_createStoreCustomerOrder
DROP PROCEDURE usp_CreateNewOrder
DROP TYPE productBarcodes_TVP
GO