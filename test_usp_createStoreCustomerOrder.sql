


DECLARE @customer1ID VARCHAR(10)
DECLARE @employeeID VARCHAR(10)
DECLARE @salesOrdID VARCHAR(10)
SET @customer1ID = 'CO0001077'
SET @employeeID = 'E12345'
SET @salesOrdID = '7121235337'
DECLARE @customer1Products AS dbo.productBarcodes_TVP

INSERT INTO @customer1Products VALUES('PI10000019');
INSERT INTO @customer1Products VALUES('PI10000015');
INSERT INTO @customer1Products VALUES('PI10000018');
--INSERT INTO @customer1Products VALUES('PI10000021');


EXECUTE usp_createStoreCustomerOrder @customer1ID, @customer1Products, @employeeID, @salesOrdID OUT


SELECT * FROM CustOrdProduct WHERE custOrdID =  '711235337'

DROP PROCEDURE usp_createStoreCustomerOrder