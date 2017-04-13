DROP TYPE productBarcodes_TVP

CREATE TYPE productBarcodes_TVP AS TABLE
(
	barcodeID VARCHAR(10),
	PRIMARY KEY(barcodeID)
);
GO

CREATE PROCEDURE  usp_createStoreCustomerOrder 
	@customerID VARCHAR(10), 
	@barcodeList productBarcodes_TVP READONLY, 
	@employeeID VARCHAR(10),
	@salesOrdID VARCHAR(10) OUTPUT
AS
	-- The @param @customerID is not null, and it references a customer in the database,
	-- Simply create a new customer order associated with @param @customerID
	IF @customerID IS NOT NULL AND EXISTS (SELECT customerID FROM Customer WHERE customerID = @customerID)
		-- INSERT INTO CustomerOrder VALUES();
		PRINT ''
	-- The @param customerID is not null, and it does reference a customer in the database,
	-- create a new customer.
	ELSE IF  @customerID IS NOT NULL AND NOT EXISTS (SELECT customerID FROM	 Customer WHERE customerID = @customerID)
	    -- INSERT INTO Customer VALUES(@customerID, '','','','','','');
		PRINT ''
	ELSE
		-- INSERT INTO CustomerOrder VALUES('','','','','','');
		PRINT ''
GO


DROP PROCEDURE usp_createStoreCustomerOrder