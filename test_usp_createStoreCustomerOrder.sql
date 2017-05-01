-- Created by: Ryan Cunneen, Micah Conway
-- Student number: 3179234, 3232648
-- Date created: 19-Apr-2017
-- Date modified: 1-May-2017
-- Contains test code for create_usp_createStoreCustomerOrder.sql


--Output parameter
DECLARE @salesOrdID VARCHAR(10);


--test case 0: customer exists
DECLARE @customerProducts AS dbo.productBarcodes_TVP --table valued parameter as defined in usp_createStoreCustomerOrder, stores item IDs (barcodes)
INSERT INTO @customerProducts VALUES('PI10000050');
INSERT INTO @customerProducts VALUES('PI10000051');
INSERT INTO @customerProducts VALUES('PI10000052');
EXECUTE usp_createStoreCustomerOrder 'C1234', @customerProducts, 'E12345', @salesOrdID OUTPUT;
PRINT ('New Customer Order ID is ' + @salesOrdID);

--test case 1: customer doesn't exist
DECLARE @customerProducts1 AS dbo.productBarcodes_TVP
INSERT INTO @customerProducts1 VALUES('PI10000019');
INSERT INTO @customerProducts1 VALUES('PI10000020');
INSERT INTO @customerProducts1 VALUES('PI10000021');
INSERT INTO @customerProducts1 VALUES('PI10000022');
EXECUTE usp_createStoreCustomerOrder 'C2010', @customerProducts1, 'E12345', @salesOrdID OUTPUT;
PRINT ('New Customer Order ID is ' + @salesOrdID);

--test case 2: customer is null
DECLARE @customerProducts2 AS dbo.productBarcodes_TVP
INSERT INTO @customerProducts2 VALUES('PI10000023');
INSERT INTO @customerProducts2 VALUES('PI10000024');
EXECUTE usp_createStoreCustomerOrder NULL, @customerProducts2, 'E12345', @salesOrdID OUTPUT;
PRINT ('New Customer Order ID is ' + @salesOrdID);

--test case 3: many items
DECLARE @customerProducts3 AS dbo.productBarcodes_TVP
INSERT INTO @customerProducts3 VALUES('PI10000053');
INSERT INTO @customerProducts3 VALUES('PI10000054');
INSERT INTO @customerProducts3 VALUES('PI10000055');
INSERT INTO @customerProducts3 VALUES('PI10000056');
INSERT INTO @customerProducts3 VALUES('PI10000057');
INSERT INTO @customerProducts3 VALUES('PI10000058');
INSERT INTO @customerProducts3 VALUES('PI10000059');
INSERT INTO @customerProducts3 VALUES('PI10000060');
INSERT INTO @customerProducts3 VALUES('PI10000061');
INSERT INTO @customerProducts3 VALUES('PI10000066');
INSERT INTO @customerProducts3 VALUES('PI10000067');
INSERT INTO @customerProducts3 VALUES('PI10000068');
INSERT INTO @customerProducts3 VALUES('PI10000069');
INSERT INTO @customerProducts3 VALUES('PI10000070');
INSERT INTO @customerProducts3 VALUES('PI10000071');
INSERT INTO @customerProducts3 VALUES('PI10000072');
INSERT INTO @customerProducts3 VALUES('PI10000073');
EXECUTE usp_createStoreCustomerOrder NULL, @customerProducts3, 'E12345', @salesOrdID OUTPUT;
PRINT ('New Customer Order ID is ' + @salesOrdID);

--test case 4: one item doesn't exist
DECLARE @customerProducts4 AS dbo.productBarcodes_TVP
INSERT INTO @customerProducts4 VALUES('PI10000079');
INSERT INTO @customerProducts4 VALUES('PI10000080');
INSERT INTO @customerProducts4 VALUES('PI19999952');
EXECUTE usp_createStoreCustomerOrder 'C1234', @customerProducts4, 'E12345', @salesOrdID OUTPUT;
PRINT ('New Customer Order ID is ' + @salesOrdID);

--test case 5: no items present
DECLARE @customerProducts5 AS dbo.productBarcodes_TVP
EXECUTE usp_createStoreCustomerOrder 'C1234', @customerProducts5, 'E12345', @salesOrdID OUTPUT;
PRINT ('New Customer Order ID is ' + @salesOrdID);

--test case 6: no items are valid
DECLARE @customerProducts6 AS dbo.productBarcodes_TVP
INSERT INTO @customerProducts6 VALUES('PI19999953');
INSERT INTO @customerProducts6 VALUES('PI19999954');
INSERT INTO @customerProducts6 VALUES('PI19999955');
INSERT INTO @customerProducts6 VALUES('PI19999956');
INSERT INTO @customerProducts6 VALUES('PI19999957');
EXECUTE usp_createStoreCustomerOrder 'C1234', @customerProducts6, 'E12345', @salesOrdID OUTPUT;
PRINT ('New Customer Order ID is ' + @salesOrdID);

--test case 7: repeat customer
DECLARE @customerProducts7 AS dbo.productBarcodes_TVP
INSERT INTO @customerProducts7 VALUES('PI10000079');
INSERT INTO @customerProducts7 VALUES('PI10000080');
EXECUTE usp_createStoreCustomerOrder 'C1234', @customerProducts7, 'E12345', @salesOrdID OUTPUT;
PRINT ('New Customer Order ID is ' + @salesOrdID);

--test case 8: a different customer
DECLARE @customerProducts8 AS dbo.productBarcodes_TVP
INSERT INTO @customerProducts8 VALUES('PI10000081');
INSERT INTO @customerProducts8 VALUES('PI10000082');
EXECUTE usp_createStoreCustomerOrder 'C1236', @customerProducts8, 'E12345', @salesOrdID OUTPUT;
PRINT ('New Customer Order ID is ' + @salesOrdID);

--test case 9: repeat of new customer
DECLARE @customerProducts9 AS dbo.productBarcodes_TVP
INSERT INTO @customerProducts9 VALUES('PI10000083');
INSERT INTO @customerProducts9 VALUES('PI10000084');
INSERT INTO @customerProducts9 VALUES('PI10000085');
INSERT INTO @customerProducts9 VALUES('PI10000086');
EXECUTE usp_createStoreCustomerOrder 'C2010', @customerProducts9, 'E12345', @salesOrdID OUTPUT;
PRINT ('New Customer Order ID is ' + @salesOrdID);*/
