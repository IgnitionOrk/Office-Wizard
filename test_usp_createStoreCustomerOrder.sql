-- Created by: Ryan Cunneen, Micah Conway
-- Student number: 3179234, 3232648
-- Date created: 19-Apr-2017
-- Date modified: 1-May-2017

--Output parameter
DECLARE @salesOrdID VARCHAR(10)

--test case 0
DECLARE @customerProducts AS dbo.productBarcodes_TVP
INSERT INTO @customerProducts VALUES('PI10000050');
INSERT INTO @customerProducts VALUES('PI10000051');
INSERT INTO @customerProducts VALUES('PI10000052');
EXECUTE usp_createStoreCustomerOrder 'C2001', @customerProducts, 'E12345', @salesOrdID;

--test case 1
DECLARE @customerProducts1 AS dbo.productBarcodes_TVP
INSERT INTO @customerProducts1 VALUES('PI10000050');
INSERT INTO @customerProducts1 VALUES('PI10000051');
INSERT INTO @customerProducts1 VALUES('PI10000052');
EXECUTE usp_createStoreCustomerOrder NULL, @customerProducts1, 'E12345', @salesOrdID;

--test case 2
DECLARE @customerProducts2 AS dbo.productBarcodes_TVP
INSERT INTO @customerProducts2 VALUES('PI10000050');
INSERT INTO @customerProducts2 VALUES('PI10000051');
INSERT INTO @customerProducts2 VALUES('PI10000052');
EXECUTE usp_createStoreCustomerOrder NULL, @customerProducts2, 'E12345', @salesOrdID;

--test case 3
DECLARE @customerProducts3 AS dbo.productBarcodes_TVP
INSERT INTO @customerProducts3 VALUES('PI10000050');
INSERT INTO @customerProducts3 VALUES('PI10000051');
INSERT INTO @customerProducts3 VALUES('PI10000052');
EXECUTE usp_createStoreCustomerOrder NULL, @customerProducts3, 'E12345', @salesOrdID;

--test case 4
DECLARE @customerProducts4 AS dbo.productBarcodes_TVP
INSERT INTO @customerProducts4 VALUES('PI10000050');
INSERT INTO @customerProducts4 VALUES('PI10000051');
INSERT INTO @customerProducts4 VALUES('PI10000052');
EXECUTE usp_createStoreCustomerOrder NULL, @customerProducts4, 'E12345', @salesOrdID;




