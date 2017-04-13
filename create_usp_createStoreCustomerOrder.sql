
CREATE TYPE productBarcodes_TVP AS TABLE
(
	barcodeID VARCHAR(10),
	PRIMARY KEY(barcodeID)
);
GO

CREATE PROCEDURE  usp_createStoreCustomerOrder @customerID VARCHAR(10), @barcodeList productBarcodes_TVP READONLY, @employeeID VARCHAR(10)
AS


GO


DROP TYPE productBarcodes_TVP
DROP PROCEDURE usp_createStoreCustomerOrder