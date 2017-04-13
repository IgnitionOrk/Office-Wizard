
--Created by: 
	--  Ryan Cunneen  :(c3179234)
	--  Micay Conway  :(c3232648)
	--  Jamie Sy	 	      :(c3207040)
--Date Created  4-Apr-2017
--Date Modified 11-Apr-2017
--Foreign key tables:
DROP TABLE EmployeeAllowanceType
DROP TABLE Allowance
DROP TABLE QuoteProduct
DROP TABLE SupplierProduct
DROP TABLE CustOrdProduct
DROP TABLE Payslip
DROP TABLE SupplierOrderProduct
DROP TABLE ProductItem
DROP TABLE Product
DROP TABLE Payment
DROP TABLE SupplierOrder
DROP TABLE Delivery
DROP TABLE Pickup
DROP TABLE CustomerOrder
DROP TABLE Quote
DROP TABLE Assignment

--Tables without foreign keys:
DROP TABLE Supplier
DROP TABLE ProductCategory
DROP TABLE Customer
DROP TABLE Employee
DROP TABLE Position
DROP TABLE AllowanceType
DROP TABLE TaxBracket

CREATE TABLE Supplier
(
	supplierID	VARCHAR(10),
	sName VARCHAR(100) NOT NULL,
	address VARCHAR(100) NOT NULL,
	phoneNo	VARCHAR(12)	NOT NULL,
	faxNo VARCHAR(12) DEFAULT NULL,
	contactPerson VARCHAR(50) DEFAULT NULL,
	PRIMARY KEY(supplierID)
);
GO

CREATE TABLE ProductCategory
(
	categoryID VARCHAR(10),
	categoryName VARCHAR(25) NOT NULL,
	PRIMARY KEY(categoryID) 
);
GO

CREATE TABLE Product
(
	productID VARCHAR(10),
	pName VARCHAR(50) NOT NULL,
	manufacturer VARCHAR(100),
	categoryID VARCHAR(10) NOT NULL,
	pDescription VARCHAR(255),
	qtyDescription VARCHAR(100), 
	pStatus VARCHAR(20)	NOT NULL CHECK(pStatus IN('Available', 'Out of stock')),
	availQty INT NOT NULL CHECK(availQty >= 0) DEFAULT 0,
	reorderLevel INT NOT NULL CHECK(reorderLevel > 0),
	maxDiscount FLOAT CHECK(maxDiscount >= 0.00),
	PRIMARY KEY(productID),
	FOREIGN KEY(categoryID) REFERENCES ProductCategory(categoryID) ON DELETE CASCADE
);
GO

CREATE TABLE SupplierProduct
(
	supplierID VARCHAR(10) NOT NULL,
	productID VARCHAR(10) NOT NULL,
	unitPrice FLOAT NOT NULL CHECK(NOT unitPrice < 0.00), -- Office Wizard could be giving them away for free.,
	FOREIGN KEY(supplierID) REFERENCES Supplier(supplierID) ON DELETE CASCADE,
	FOREIGN KEY(productID) REFERENCES Product(productID) ON DELETE CASCADE,
	PRIMARY KEY(supplierID, productID)
);
GO

CREATE TABLE Employee
(
	employeeID VARCHAR(10),
	eName VARCHAR(100) NOT NULL,
	gender	 CHAR(1)	CHECK(gender IN('M', 'F', 'O')),
	phoneNo VARCHAR(12)	NOT NULL,
	homeAddress	VARCHAR(100) NOT NULL,
	homePhone VARCHAR(12),
	DOB DATE CHECK(DOB BETWEEN  '1900-01-01' AND GETDATE()),
	PRIMARY KEY(employeeID)
);
GO


CREATE TABLE Quote
(
	quoteID VARCHAR(10),
	qDate DATE NOT NULL,
	validPeriod DATE,
	qDescription VARCHAR(255) DEFAULT NULL,
	supplierID VARCHAR(10) NOT NULL, 
	employeeID	 VARCHAR(10) NOT NULL,
	PRIMARY KEY(quoteID),
	FOREIGN KEY(supplierID) REFERENCES Supplier(supplierID) ON DELETE NO ACTION,
	FOREIGN KEY(employeeID) REFERENCES Employee(employeeID) ON DELETE NO ACTION	
);
GO

CREATE TABLE QuoteProduct
(
	productID VARCHAR(10),
	quoteID VARCHAR(10),
	qty INT CHECK(qty > 0),
	FOREIGN KEY(productID) REFERENCES Product(productID),
	FOREIGN KEY(quoteID) REFERENCES Quote(quoteID),
	PRIMARY KEY(productID, quoteID)
);
GO

CREATE TABLE SupplierOrder
(
	suppOrdID VARCHAR(10),
	suppOrdDate DATE NOT NULL, 
	suppOrdDescription VARCHAR(255) DEFAULT NULL,
	quoteID VARCHAR(10) NOT NULL,
	totalAmount FLOAT CHECK(totalAmount >= 0),
	suppOrdStatus VARCHAR(10) CHECK(suppOrdStatus  IN ('Processing','Delivered','Cancelled','Awaiting Payment','Completed')),
	suppOrdRcvDate DATE NOT NULL,
	PRIMARY KEY(suppOrdID),
	FOREIGN KEY(quoteID) REFERENCES Quote(quoteID) ON DELETE NO ACTION
);
GO


CREATE TABLE SupplierOrderProduct
(
	suppOrdID VARCHAR(10) NOT NULL,
	productID VARCHAR(10) NOT NULL,
	unitPurchasePrice FLOAT,
	qty INT,
	FOREIGN KEY(suppOrdID) REFERENCES SupplierOrder(suppOrdID) ON DELETE CASCADE,
	FOREIGN KEY(productID) REFERENCES Product(productID) ON DELETE NO ACTION,
	PRIMARY KEY(suppOrdID, productID)
);
GO


CREATE TABLE Customer
(
	customerID	VARCHAR(10),
	cName	 VARCHAR(100) NOT NULL,
	address VARCHAR(100),
	phoneNo VARCHAR(12),
	faxNo VARCHAR(12) DEFAULT NULL,
	email VARCHAR(100),
	contactPerson VARCHAR(100) DEFAULT NULL,		--Only provide if the customer is a company
	gender	 CHAR(1)	CHECK(gender IN('M', 'F', 'O')),
	PRIMARY KEY(customerID)
);
GO

CREATE TABLE CustomerOrder
(
	custOrdID VARCHAR(10),
	employeeID	 VARCHAR(10) DEFAULT NULL,						--Null because order may have been online. 
	customerID VARCHAR(10),
	orderDate DATE	NOT NULL,					
	discountGiven FLOAT DEFAULT NULL, 
	amountDue	 FLOAT,
	amountPaid FLOAT, 
	custOrdStatus VARCHAR(10) CHECK(custOrdStatus IN ('Processing','Delivered','Cancelled','Awaiting Payment','Completed')),
	modeOfSale VARCHAR(10) CHECK(modeOfSale IN ('Online','In Store','Phone')),
	PRIMARY KEY(custOrdID),
	FOREIGN KEY(employeeID) REFERENCES Employee(employeeID) ON DELETE NO ACTION,
	FOREIGN KEY(customerID) REFERENCES Customer(customerID) ON DELETE NO ACTION
);
GO

CREATE TABLE ProductItem
(
	itemNo VARCHAR(10),
	productID VARCHAR(10) NOT NULL,
	suppOrdID VARCHAR(10) NOT NULL,
	costPrice FLOAT CHECK(costPrice > 0), 
	sellingPrice FLOAT CHECK(sellingPrice > 0),
	custOrdID VARCHAR(10) NOT NULL,
	status VARCHAR(10) CHECK(status IN('in-stock', 'sold', 'lost')),
	PRIMARY KEY(itemNo),
	FOREIGN KEY(productID) REFERENCES Product(productID) ON DELETE CASCADE,
	FOREIGN KEY(suppOrdID) REFERENCES SupplierOrder(suppOrdID) ON DELETE CASCADE,
	FOREIGN KEY(custOrdID) REFERENCES CustomerOrder(custOrdID) ON DELETE CASCADE
);
GO

CREATE TABLE CustOrdProduct
(
	custOrdID VARCHAR(10),
	productID VARCHAR(10),
	qty INT CHECK(qty > 0),
	unitPurchasePrice FLOAT,
	subtotal FLOAT,
	FOREIGN KEY(custOrdID) REFERENCES CustomerOrder(custOrdID),
	FOREIGN KEY(productID) REFERENCES Product(productID),
	PRIMARY KEY(custOrdID, productID)
);
GO

CREATE TABLE Delivery
(
	custOrdID VARCHAR(10) NOT NULL,
	delAddress VARCHAR(100) NOT NULL,
	delCharge FLOAT CHECK(delCharge >= 0.00),
	delDateTime DATETIME	 NOT NULL,
	FOREIGN KEY(custOrdID) REFERENCES CustomerOrder(custOrdID) ON DELETE CASCADE
);
GO

CREATE TABLE Pickup
(
	custOrdID VARCHAR(10) NOT NULL,
	pickupDateTime DATETIME NOT NULL,
	FOREIGN KEY(custOrdID) REFERENCES CustomerOrder(custOrdID) ON DELETE CASCADE
);
GO

CREATE TABLE Payment
(
	paymentRefNo VARCHAR(10),
	paymentDate DATE NOT NULL,
	custOrdID VARCHAR(10),
	suppOrdID VARCHAR(10)	,
	PRIMARY KEY(paymentRefNo),
	FOREIGN KEY(custOrdID) REFERENCES CustomerOrder(custOrdID) ON DELETE NO ACTION,
	FOREIGN KEY(suppOrdID) REFERENCES SupplierOrder(suppOrdID) ON DELETE NO ACTION

);
GO

CREATE TABLE Position
(
	positionID VARCHAR(10),
	positionName VARCHAR(50) NOT NULL,
	hourlyRate FLOAT CHECK(hourlyRate >= 0.00),
	PRIMARY KEY(positionID)
);
GO

CREATE TABLE Assignment
(
	assignmentID VARCHAR(10),
	employeeID VARCHAR(10),
	positionID VARCHAR(10),
	startDate	 DATE NOT NULL,
	finishDate DATE DEFAULT NULL,
	PRIMARY KEY(assignmentID, employeeID, positionID),
	FOREIGN KEY(employeeID) REFERENCES Employee(employeeID) ON DELETE NO ACTION,
	FOREIGN KEY(positionID) REFERENCES Position(positionID) ON DELETE NO ACTION
);
GO


CREATE TABLE AllowanceType
(
	allowanceTypeID VARCHAR(10),	
	allowType VARCHAR(50),	
	aTDescription VARCHAR(100),       
	frequency VARCHAR(20) CHECK(frequency IN('Yearly', 'Monthly', 'Quarterly', 'Weekly','Daily', 'When needed')),
	PRIMARY KEY(allowanceTypeID)
);
GO


CREATE TABLE TaxBracket
(
	taxBracketID VARCHAR(10),
	startAmount FLOAT CHECK(startAmount >= 0),
	endAmount FLOAT CHECK(endAmount > 0),
	taxRate FLOAT,
	effectiveYear CHAR(4),
	PRIMARY KEY(taxBracketID)
);
GO

CREATE TABLE Payslip
(
	payslipID VARCHAR(10),
	employeeID VARCHAR(10) NOT NULL,
	taxBracketID VARCHAR(10) NOT NULL,
	startDate DATE NOT NULL,
	endDate DATE NOT NULL,
	workedHours FLOAT CHECK(workedHours >= 0),
	basePay FLOAT,
	taxableIncome FLOAT,
	netPay FLOAT,
	PRIMARY KEY(payslipID),
	FOREIGN KEY(employeeID) REFERENCES Employee(employeeID) ON DELETE NO ACTION,
	FOREIGN KEY(taxBracketID) REFERENCES TaxBracket(taxBracketID) ON DELETE NO ACTION
);
GO

CREATE TABLE Allowance 
(
	allowanceID VARCHAR(10),
	payslipID VARCHAR(10) NOT NULL,
	allowanceTypeID VARCHAR(10) NOT NULL,
	amount FLOAT,
	allowDescription VARCHAR(100),
	FOREIGN KEY(payslipID) REFERENCES Payslip(payslipID) ON DELETE CASCADE,
	FOREIGN KEY(allowanceTypeID) REFERENCES AllowanceType(allowanceTypeID) ON DELETE NO ACTION,
	PRIMARY KEY(allowanceID)
);
GO

CREATE TABLE EmployeeAllowanceType
(
	employeeID VARCHAR(10) NOT NULL,
	allowanceTypeID VARCHAR(10) NOT NULL,
	FOREIGN KEY(employeeID) REFERENCES Employee(employeeID) ON DELETE CASCADE ,
	FOREIGN KEY(allowanceTypeID) REFERENCES  AllowanceType(allowanceTypeID) ON DELETE CASCADE
);
GO


-- DATA
--Created by: 
	--  Ryan Cunneen  :(c3179234)
	--  Micay Conway  :(c3232648)
	--  Jamie Sy	  :(c3207040)
--Date Created  4-Apr-2017
--Date Modified 11-Apr-2017


INSERT INTO Supplier VALUES('S111111111', 'World of Pens', '121 Industrial Rd', '123456789012', '1234-1234-12', 'Mary Jane');
INSERT INTO Supplier VALUES('S222222222', 'Chair R Us', '11 Matthew Avenue',  '210987654321',  '12-4321-4321', 'Bob Walts');
INSERT INTO Supplier VALUES('S333333333', 'Paper Industries', '124/34 Cresent Head', '1234567192', '000-0000-00', 'Gary Mancolo');
INSERT INTO Supplier VALUES('S444444444', 'Furniture galore', '123/34 Cresent Head',  '1111111111', NULL , 'Ryan Sallvitore');
INSERT INTO Supplier VALUES('S555555555', 'Your Stock', '11 Matthew Avenue',  '0407022211', NULL , 'Sasha');
INSERT INTO Supplier VALUES('S666666666', 'Family fun', '332/22 Bay Rd', '02445568886', NULL, 'Barry');
INSERT INTO Supplier VALUES('S777777777', 'Stationary Centre', '23a Peak Hills', '0243588552', '12-4455-3322', 'Mary Sue');
INSERT INTO Supplier VALUES('S888888888', 'Electronic Planet', '1 First Avenue', '0455568886', '12-6662-1144', 'Jamie Gallagher');
INSERT INTO Supplier VALUES('S999999999', 'Machines', '889 Lovett Cresent', '6155225556', NULL, 'Henry');
INSERT INTO Supplier VALUES('S000000000', 'Everything Furniture', '1/22 Anzac Close', '6155998765', NULL, 'Arthur Curry');

INSERT INTO ProductCategory VALUES('PC12345671', 'Furniture');
INSERT INTO ProductCategory VALUES('PC12345673', 'Storage');
INSERT INTO ProductCategory VALUES('PC12345674', 'Stationary');
INSERT INTO ProductCategory VALUES('PC12345675', 'Electronic');
INSERT INTO ProductCategory VALUES('PC12345676', 'Book');

INSERT INTO Customer VALUES('C1234','Jamie Chake','11 Matthew Circuit, Mardi','0442221111',NULL,'jamie@hotmail.com', NULL,'M');
INSERT INTO Customer VALUES('C1235','Amy fay','111 Sydney Rd','0412345678',NULL,'amy@gmail.com',NULL,'F');
INSERT INTO Customer VALUES('C1236','Ryan Brax','32a Teralba Rd','0243533805',NULL,'brax93@hotmail.com',NULL,'M');
INSERT INTO Customer VALUES('C1237','Consumer World','112/11 Westfield Avenue','0244885222','0246461121','westfield@hotmail.com','Gary foster','O');
INSERT INTO Customer VALUES('C1238','Daniel Dots','22 Richard Avenue','0422022333',NULL,'dotsPots@gmail.com',NULL,'M');
INSERT INTO Customer VALUES('C1239','Rachael Ally','122/12 Bagle Street','0455566622',NULL,'rachael@hotmail.com',NULL,'F');
INSERT INTO Customer VALUES('C1220','Everything Furniture','112/11 Westfield Avenue','0244556888','0255665552','everythingFurn@customer.service.com.au','Jenny Alistair','O');
INSERT INTO Customer VALUES('C1200','Ben Foster','22 Cresent Head','0466558555',NULL,'ben@gmail.com',NULL,'M');
INSERT INTO Customer VALUES('C1221','Terry Foster','22 Cresent Head','0422552558',NULL,'foster@gmail.com',NULL,'M');
INSERT INTO Customer VALUES('C1000','Stationary Central','223/2w Industry Complex Avenue','0422252255','0255555555','sc@hotmail.com','Kristy Dire','O');

INSERT INTO Employee VALUES('E12345', 'Mohammad Isla', 'M', '0455566898', '34 Ballet Street', NULL, '1990-01-01');
INSERT INTO Employee VALUES('E12346', 'Gary Thuu', 'M', '0455873332', '99/22 Angel Bay', NULL, '1984-05-02');
INSERT INTO Employee VALUES('E12347', 'Fiona May', 'F', '0411111111', '23 Coral Rd', NULL, '1954-01-15');
INSERT INTO Employee VALUES('E12348', 'Sandra Alli', 'F', '0488998852', '221 Cobbs Hill', '45555525', '1964-11-12');
INSERT INTO Employee VALUES('E12349', 'Tim Flay', 'O', '0477885222', '56 Good Street', '0244552211', '1980-08-12');
INSERT INTO Employee VALUES('E68889', 'Jamie Bold', 'F','0456568856','11 Sun Close',NULL,'1967-12-12');
INSERT INTO Employee VALUES('E89897', 'Diane Kruger','F','6155540666','77/22 Hill Rd','56685525','1988-01-23');
INSERT INTO Employee VALUES('E12213', 'Zhou Ming', 'M','43535565','13 Richard Rd','06568865','1993-04-05');
INSERT INTO Employee VALUES('E00099', 'Suzanne Lowe', 'F','0456558889','33/22 Palla Street',NULL,'1950-05-30');
INSERT INTO Employee VALUES('E98898', 'Daniel McContyre','M','0455568931','668 Dagula Hill',NULL,'1989-06-07');

INSERT INTO Position VALUES('P22343', 'Salesperson', 20.00);
INSERT INTO Position VALUES('P22311', 'Manager', 23.00);
INSERT INTO Position VALUES('P22222', 'Store Manager', 30.00);
INSERT INTO Position VALUES('P33223', 'Stock Hand', 19.00);
INSERT INTO Position VALUES('P33211', 'Human Resources', 19.00);
INSERT INTO Position VALUES('P90999', 'Accountant', 21.00);

INSERT INTO TaxBracket VALUES('T111111', 10000.00, 20000.00, 0.10, '2017');
INSERT INTO TaxBracket VALUES('T222222', 20000.01, 30000.00, 0.15, '2017');
INSERT INTO TaxBracket VALUES('T556555', 30000.01, 40000.00, 0.17, '2009');
INSERT INTO TaxBracket VALUES('T443343', 40000.01, 50000.00, 0.20, '2017');
INSERT INTO TaxBracket VALUES('T898889', 50000.01, 60000.00, 0.21, '2017');
INSERT INTO TaxBracket VALUES('T444544', 60000.01, 70000.00, 0.22, '2006');

INSERT INTO AllowanceType VALUES('AT7778878', 'Sales bonus', 'End of year sales bonus', 'yearly');
INSERT INTO AllowanceType VALUES('AT7779966', 'Long service leave', '', 'quarterly');
INSERT INTO AllowanceType VALUES('AT3778783', 'Uniform allowance', 'Uniform cost', 'monthly');
INSERT INTO AllowanceType VALUES('AT7787987', 'Annual Leave', 'Leave', 'weekly'); 
INSERT INTO AllowanceType VALUES('AT0970970', 'Redundancy','Payment for being made redundant', 'weekly');
INSERT INTO AllowanceType VALUES('AT4087488', 'Disability', 'For person with a medical condition', 'daily');
INSERT INTO AllowanceType VALUES('AT6568565', 'Shift Allowance', 'People whom work undesirable hours', 'daily');
INSERT INTO AllowanceType VALUES('AT5865656', 'First aid allowance', 'Have medical skills', 'quarterly');
INSERT INTO AllowanceType VALUES('AT9869869', 'Maternity leave', '3 months leave', 'When needed');

-- Category: Stationary
INSERT INTO Product VALUES('P1234', 'Silly pens','All things stationary','PC12345674','Colour pens','Half dozen of pens','Available',23,5, 0.50);
INSERT INTO Product VALUES('P1223', 'Ruler', 'All things stationary','PC12345674','Measurement tool','Single ruler','Out of stock',0,10, 0.15);
INSERT INTO Product VALUES('P1254', 'Sticky Sticky Glue stick','All things stationary','PC12345674','Binding product','3 pack of glue stick', 'Available',20,10, 0.10);
INSERT INTO Product VALUES('P2112', 'Writing Pens','All things stationary','PC12345674','Everyday pens','Half dozen of pens','Available',14,5, 0.10);
-- Category: Storage
INSERT INTO Product VALUES('P9084', 'Your safe, all safe','Storage mania','PC12345673','Protective storage','Single safe','Available',5,2, 0.10);
INSERT INTO Product VALUES('P4378', 'Book shelf','Storage mania','PC12345673',NULL,'Half dozen of pens','Available',5, 4, 0.20);
INSERT INTO Product VALUES('P3911', 'Office desk','Storage mania','PC12345673', NULL,'Single desk','Out of stock',0 ,5, 0.20);
INSERT INTO Product VALUES('P1232', 'File Cabinet', 'Storage mania','PC12345673','Storage for important documents','Single cabinet','Available',15,5, 0.05);
-- Category: Electronic
INSERT INTO Product VALUES('P0000', 'Stereo Magic','Electronic Experts','PC12345675','Sound system','Single sound system','Available',10, 5, 0.20);
INSERT INTO Product VALUES('P5645', 'Gaming Monitor','Electronic Experts','PC12345675','Computer monitor','Single monitor','Out of stock',0,5, 0.15);
INSERT INTO Product VALUES('P8988', 'Power board','Electronic Experts','PC12345675',NULL,'Single power board','Available',6,5, 0.10);
INSERT INTO Product VALUES('P9999', 'Amazing Sound','Electronic Experts','PC12345675','Sound system','Single sound system','Available',7,3, 0.27);
-- Category: Book
INSERT INTO Product VALUES('P4565', 'Kids programming','All things Education','PC12345676','Programming textbook','Single textbook','Available',23,5, 0.50);
INSERT INTO Product VALUES('P7895', 'Programming for dummies','All things Education','PC12345676','Programming textbook','Single textbook','Available',10,8, 0.50);
INSERT INTO Product VALUES('P9885', 'Artbook','Art central','PC12345676','Picture book of art','Single book','Out of stock',20,10, 0.05);
INSERT INTO Product VALUES('P0022', 'Mathematics','All things Education','PC12345676','Mathematics textbook','Single textbook','Available',25,3, 0.75);
-- Category: Furniture
INSERT INTO Product VALUES('P1211', 'Office Desk','Furniture experts','PC12345671','Office Desk','Single desk','Available',6,3, 0.50);
INSERT INTO Product VALUES('P1235', 'Solid chair','Furniture experts','PC12345671','Desk chair','Single chair','Available',10, 2, 0.10);
INSERT INTO Product VALUES('P3265', 'Kids chair','Furniture experts','PC12345671','Child office chair','Single chair','Out of stock',0,10, 0.23);
INSERT INTO Product VALUES('P4566', 'Kids desk','Furniture experts','PC12345671','Child office desk','Single desk','Available',2,5, 0.10);

<<<<<<< HEAD
INSERT INTO Payslip VALUES ('PS0000000112', 'E00099', 'T556555', '2017-01-01', '2017-01-06', 12, 50000, 1000, 49000);
INSERT INTO Payslip VALUES ('PS0000000113', 'E00119', 'T111111', '2017-01-10', '2017-01-16', 20, 50000, 1000, 49000);
INSERT INTO Payslip VALUES ('PS0000000113', 'E00120', 'T111111', '2017-02-10', '2017-02-16', 20, 46000, 1000, 45000);
=======

INSERT INTO SupplierProduct VALUES('S777777777', 'P1234', 1.24);
INSERT INTO SupplierProduct VALUES('S111111111', 'P1234', 1.28);
INSERT INTO SupplierProduct VALUES('S777777777', 'P1223', 0.30);
INSERT INTO SupplierProduct VALUES('S777777777', 'P1254', 2.50);
INSERT INTO SupplierProduct VALUES('S111111111', 'P2112', 1.50);
INSERT INTO SupplierProduct VALUES('S777777777', 'P2112', 1.51);
INSERT INTO SupplierProduct VALUES('S222222222', 'P9084', 100.00);
INSERT INTO SupplierProduct VALUES('S000000000', 'P4378', 50.20);
INSERT INTO SupplierProduct VALUES('S000000000', 'P3911', 250.00);
INSERT INTO SupplierProduct VALUES('S444444444', 'P3911', 249.00);
INSERT INTO SupplierProduct VALUES('S000000000', 'P1232', 75.00);
INSERT INTO SupplierProduct VALUES('S888888888', 'P0000', 159.00);
INSERT INTO SupplierProduct VALUES('S888888888', 'P5645', 300.00);
INSERT INTO SupplierProduct VALUES('S888888888', 'P8988', 15.00);
INSERT INTO SupplierProduct VALUES('S999999999', 'P9999',150.00 );
INSERT INTO SupplierProduct VALUES('S666666666','P4565',12.75 );
INSERT INTO SupplierProduct VALUES('S666666666','P7895', 15.45);
INSERT INTO SupplierProduct VALUES('S666666666','P9885', 25.35);
INSERT INTO SupplierProduct VALUES('S333333333','P9885', 25.37);
INSERT INTO SupplierProduct VALUES('S555555555','P0022', 12.75);
INSERT INTO SupplierProduct VALUES('S555555555','P1211', 175.20);
INSERT INTO SupplierProduct VALUES('S444444444','P1235', 35.00);
INSERT INTO SupplierProduct VALUES('S444444444','P3265', 20.00);
INSERT INTO SupplierProduct VALUES('S444444444','P4566', 52.35);
INSERT INTO SupplierProduct VALUES('S000000000','P4566', 55.35);
INSERT INTO SupplierProduct VALUES('S222222222','P4566', 50.35);

--INSERT INTO Payslip VALUES ('PS0000000112', 'E00099', 'T556555', '2017-01-01', '2017-01-06', );
>>>>>>> origin/master

INSERT INTO Quote VALUES ('QUO1004567', '2017-01-02', '2017-01-03', 'Reasonable quote for a bulk supply of silly pens to suit all your silly stationary needs', 'S111111111', 'E68889');
INSERT INTO Quote VALUES ('QUO1022222', '2017-01-10', '2017-01-11', 'Supply of arty stuff for creative people', 'S111111111', 'E68889');
INSERT INTO Quote VALUES ('QUO2244237', '2017-02-02', '2017-02-03', 'Quote must be responded to ', 'S222222222', 'E68889');
INSERT INTO Quote VALUES ('QUO1231237', '2017-01-12', '2017-01-13', 'Silly pens to suit all your silly stationary needs', 'S111111111', 'E68889');

--INSERT INTO SupplierOrder VALUES ('SO10000011', )

--INSERT INTO SupplierOrderProduct VALUES ()

--INSERT INTO ProductItem VALUES


