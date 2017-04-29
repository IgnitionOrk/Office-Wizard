-- DATA
--Created by: 
	--  Ryan Cunneen  :(c3179234)
	--  Jamie Sy	  :(c3207040)
--Date Created  4-Apr-2017
--Date Modified 18-Apr-2017

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
GO

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
	unitPrice FLOAT NOT NULL CHECK(unitPrice >= 0.00), -- To ensure Office Wizard can't give them away for free.,
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
	FOREIGN KEY(supplierID) REFERENCES Supplier(supplierID) ON DELETE CASCADE,
	FOREIGN KEY(productID) REFERENCES Product(productID) ON DELETE CASCADE,
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
	quoteID VARCHAR(10),
	productID VARCHAR(10),
	qty INT CHECK(qty > 0),
	unitPrice FLOAT	NOT NULL,
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
	cName	 VARCHAR(100) NOT NULL DEFAULT 'Unspecified',
	address VARCHAR(100) DEFAULT 'Unspecified',
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
	employeeID	 VARCHAR(10) DEFAULT NULL,			--Null because order may have been online. 
	customerID VARCHAR(10),
	orderDateTime DATETIME	NOT NULL,					
	discountGiven FLOAT DEFAULT NULL, 
	amountDue	 FLOAT,
	amountPaid FLOAT, 
	custOrdStatus VARCHAR(50) CHECK(custOrdStatus IN ('Processing','Delivered','Cancelled','Awaiting Payment','Completed')),
	modeOfSale VARCHAR(10) CHECK(modeOfSale IN ('Online','In Store','Phone')),
	PRIMARY KEY(custOrdID),
	FOREIGN KEY(employeeID) REFERENCES Employee(employeeID) ON DELETE NO ACTION,
	FOREIGN KEY(customerID) REFERENCES Customer(customerID) ON DELETE NO ACTION
);
GO

CREATE TABLE ProductItem
(
	itemNo VARCHAR(10),				-- itemNo is the code for each individual item (i.e. each printer would have a different item number for warranty purposes)
	productID VARCHAR(10) NOT NULL,
	suppOrdID VARCHAR(10) NOT NULL,
	costPrice FLOAT CHECK(costPrice > 0), 			--Cost price is the cost of each individual item. i.e. one carton($1) could have 10 pens and each pen would cost us 10 cents each pen.
	sellingPrice FLOAT CHECK(sellingPrice > 0),
	custOrdID VARCHAR(10) DEFAULT NULL,
	status VARCHAR(10) CHECK(status IN('in-stock', 'sold', 'lost')),
	PRIMARY KEY(itemNo),
	FOREIGN KEY(productID) REFERENCES Product(productID) ON DELETE CASCADE,
	FOREIGN KEY(suppOrdID) REFERENCES SupplierOrder(suppOrdID) ON DELETE CASCADE,
	FOREIGN KEY(custOrdID) REFERENCES CustomerOrder(custOrdID) ON DELETE NO ACTION
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
	startDate DATE NOT NULL,
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
	basePay FLOAT, -- should be a derived field based on Position
	taxPayable FLOAT, --should be derived from taxBracket. based on your position
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
	allowDescription VARCHAR(255),
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
--Date Modified 27-Apr-2017


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
INSERT INTO Customer VALUES('C1235','Amy Fay','111 Sydney Rd','0412345678',NULL,'amy@gmail.com',NULL,'F');
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

INSERT INTO EmployeeAllowanceType VALUES ('E12345', 'AT7779966');
INSERT INTO EmployeeAllowanceType VALUES ('E12346', 'AT7779966');
INSERT INTO EmployeeAllowanceType VALUES ('E12347', 'AT6568565');
INSERT INTO EmployeeAllowanceType VALUES ('E12348', 'AT7787987');
INSERT INTO EmployeeAllowanceType VALUES ('E12349', 'AT4087488');
INSERT INTO EmployeeAllowanceType VALUES ('E68889', 'AT6568565');
INSERT INTO EmployeeAllowanceType VALUES ('E89897', 'AT7779966');
INSERT INTO EmployeeAllowanceType VALUES ('E12213', 'AT7778878');
INSERT INTO EmployeeAllowanceType VALUES ('E00099', 'AT9869869');
INSERT INTO EmployeeAllowanceType VALUES ('E00099', 'AT7779966');
INSERT INTO EmployeeAllowanceType VALUES ('E98898', 'AT0970970');

INSERT INTO Payslip VALUES ('PS00000110', 'E68889', 'T556555', '2017-01-01', '2017-01-06', 12, 50000, 1000, 49000);
INSERT INTO Payslip VALUES ('PS00000111', 'E12346', 'T556555', '2017-01-01', '2017-01-06', 12, 50000, 1000, 49000);
INSERT INTO Payslip VALUES ('PS00000112', 'E12349', 'T556555', '2017-01-01', '2017-01-06', 12, 50000, 1000, 49000);
INSERT INTO Payslip VALUES ('PS00000113', 'E68889', 'T111111', '2017-01-10', '2017-01-16', 20, 50000, 1000, 49000);
INSERT INTO Payslip VALUES ('PS00000114', 'E68889', 'T111111', '2017-02-10', '2017-02-16', 20, 46000, 1000, 45000);
INSERT INTO Payslip VALUES ('PS00000115', 'E12213', 'T556555', '2017-01-01', '2017-01-06', 12, 50000, 1000, 49000);
INSERT INTO Payslip VALUES ('PS00000116', 'E00099', 'T111111', '2017-01-10', '2017-01-16', 20, 50000, 1000, 49000);
INSERT INTO Payslip VALUES ('PS00000117', 'E12347', 'T111111', '2017-02-10', '2017-02-16', 20, 46000, 1000, 45000);
INSERT INTO Payslip VALUES ('PS00000118', 'E12346', 'T111111', '2017-01-10', '2017-01-16', 20, 50000, 1000, 49000);
INSERT INTO Payslip VALUES ('PS00000119', 'E00099', 'T111111', '2017-02-10', '2017-02-16', 20, 46000, 1000, 45000);
INSERT INTO Payslip VALUES ('PS00000120', 'E89897', 'T111111', '2017-01-10', '2017-01-16', 20, 50000, 1000, 49000);
INSERT INTO Payslip VALUES ('PS00000121', 'E89897', 'T111111', '2017-02-10', '2017-02-16', 20, 46000, 1000, 45000);
INSERT INTO Payslip VALUES ('PS00000122', 'E12347', 'T111111', '2017-03-10', '2017-03-16', 20, 50000, 1000, 49000);
INSERT INTO Payslip VALUES ('PS00000123', 'E12345', 'T111111', '2017-02-10', '2017-02-16', 20, 46000, 1000, 45000);

INSERT INTO Allowance VALUES ('A00010010', 'PS00000110', 'AT6568565', 20, 'This allowance is rewarded to this employee due to working shifts that are undesirable.');
INSERT INTO Allowance VALUES ('A00010011', 'PS00000111', 'AT7779966',1500, 'This allowance is rewarded to this employee due to staying with Office Wizard for at least 5 years.');
INSERT INTO Allowance VALUES ('A00010012', 'PS00000112', 'AT4087488', 850, 'This allowance is rewarded to this employee due to their physical disability yet still makes the effort to work.');
INSERT INTO Allowance VALUES ('A00010013', 'PS00000113', 'AT6568565', 250, 'This allowance is rewarded to this employee due to working shifts that are during a storm tat might have put him in danger');
INSERT INTO Allowance VALUES ('A00010014', 'PS00000114', 'AT6568565', 250, 'This allowance is rewarded to this employee due to working shifts that are undesirable.');
INSERT INTO Allowance VALUES ('A00010015', 'PS00000115', 'AT7778878', 200, 'This allowance is rewarded to this employee due to performing the best in the sales team last year.');
INSERT INTO Allowance VALUES ('A00010016', 'PS00000116', 'AT7779966', 1000, 'This allowance is rewarded to this employee due to staying with Office Wizard for at least 5 years.');
INSERT INTO Allowance VALUES ('A00010017', 'PS00000117', 'AT6568565', 40, 'This allowance is rewarded to this employee due to working shifts that are undesirable.');
INSERT INTO Allowance VALUES ('A00010018', 'PS00000118', 'AT7779966', 800, 'This allowance is rewarded to this employee due to staying with Office Wizard for at least 5 years.');
INSERT INTO Allowance VALUES ('A00010019', 'PS00000119', 'AT9869869', 1500, 'This allowance is rewarded to this employee due to giving birth for another future wizard.');
INSERT INTO Allowance VALUES ('A00010020', 'PS00000120', 'AT7779966', 400, 'This allowance is rewarded to this employee due to staying with Office Wizard for at least 5 years.');
INSERT INTO Allowance VALUES ('A00010021', 'PS00000121', 'AT7779966', 350, 'This allowance is rewarded to this employee due to staying with Office Wizard for at least 5 years.');
INSERT INTO Allowance VALUES ('A00010022', 'PS00000122', 'AT6568565', 250, 'This allowance is rewarded to this employee due to working shifts that are undesirable.');
INSERT INTO Allowance VALUES ('A00010023', 'PS00000123', 'AT7779966', 400, 'This allowance is rewarded to this employee due to staying with Office Wizard for at least 5 years.');


-- Category: Stationary
INSERT INTO Product VALUES('P1234', 'Silly pens','All things stationary','PC12345674','Colour pens','Half dozen of pens', 1.00,'Available',23,5, 0.20);
INSERT INTO Product VALUES('P1223', 'Ruler', 'All things stationary','PC12345674','Measurement tool','Single ruler',0.75,'Out of stock',0,10, 0.15);
INSERT INTO Product VALUES('P1254', 'Sticky Sticky Glue stick','All things stationary','PC12345674','Binding product','3 pack of glue stick', 1.02, 'Available',20,10, 0.10);
INSERT INTO Product VALUES('P2112', 'Writing Pens','All things stationary','PC12345674','Everyday pens','Half dozen of pens',1.50,'Available',14,5, 0.10);
-- Category: Storage
INSERT INTO Product VALUES('P9283', 'Your safe, all safe','Storage mania','PC12345673','Protective storage','Single safe',150.00,'Available',8,3, 0.10);
INSERT INTO Product VALUES('P4378', 'Book shelf','Storage mania','PC12345673',NULL,'Single book shelf',50.00,'Available',5, 4, 15.00);
INSERT INTO Product VALUES('P3911', 'Office desk','Storage mania','PC12345673', NULL,'Single desk',460.00,'Available',10 ,5, 0.15);
INSERT INTO Product VALUES('P1232', 'File Cabinet', 'Storage mania','PC12345673','Storage for important documents','Single cabinet',210,'Out of stock',0,3, 0.05);
-- Category: Electronic
INSERT INTO Product VALUES('P0000', 'Stereo Magic','Electronic Experts','PC12345675','Sound system','Single sound system',200.00,'Available',10, 5, 0.20);
INSERT INTO Product VALUES('P5645', 'Gaming Monitor','Electronic Experts','PC12345675','Computer monitor','Single monitor',150.00,'Out of stock',0,5, 0.15);
INSERT INTO Product VALUES('P8988', 'Power board','Electronic Experts','PC12345675',NULL,'Single power board',25.75,'Available',6,5, 0.10);
INSERT INTO Product VALUES('P9999', 'Amazing Sound','Electronic Experts','PC12345675','Sound system','Single sound system',175.85,'Available',7,3, 0.27);
-- Category: Book
INSERT INTO Product VALUES('P4565', 'Kids programming','All things Education','PC12345676','Programming textbook','Single textbook',12.75 ,'Available',23,5, 0.50);
INSERT INTO Product VALUES('P7895', 'Programming for dummies','All things Education','PC12345676','Programming textbook','Single textbook',25.96,'Available',10,8, 0.50);
INSERT INTO Product VALUES('P9885', 'Artbook','Art central','PC12345676','Picture book of art','Single book',10.00,'Out of stock',20,10, 0.05);
INSERT INTO Product VALUES('P0022', 'Mathematics','All things Education','PC12345676','Mathematics textbook','Single textbook',20.00,'Available',25,3, 0.75);
-- Category: Furniture
INSERT INTO Product VALUES('P1211', 'Office Desk','Furniture experts','PC12345671','Office Desk','Single desk',175.00,'Available',6,3, 0.50);
INSERT INTO Product VALUES('P1235', 'Solid chair','Furniture experts','PC12345671','Desk chair','Single chair',57.63,'Available',10, 2, 0.10);
INSERT INTO Product VALUES('P3265', 'Kids chair','Furniture experts','PC12345671','Child office chair','Single chair',12.75,'Out of stock',0,10, 0.23);
INSERT INTO Product VALUES('P4566', 'Kids desk','Furniture experts','PC12345671','Child office desk','Single desk',25.75,'Available',2,5, 0.10);
<<<<<<< HEAD
=======
INSERT INTO Product VALUES('P9084', 'Footrest','Furniture experts','PC12345671','Foot rest designed to be placed under desk','Single footrest',30,'Available',11,3, 0.10);
>>>>>>> origin/master

INSERT INTO SupplierProduct VALUES('S777777777', 'P1234');
INSERT INTO SupplierProduct VALUES('S111111111', 'P1234');
INSERT INTO SupplierProduct VALUES('S777777777', 'P1223');
INSERT INTO SupplierProduct VALUES('S777777777', 'P1254');
INSERT INTO SupplierProduct VALUES('S111111111', 'P2112');
INSERT INTO SupplierProduct VALUES('S777777777', 'P2112');
INSERT INTO SupplierProduct VALUES('S222222222', 'P9084');
INSERT INTO SupplierProduct VALUES('S000000000', 'P4378');
INSERT INTO SupplierProduct VALUES('S000000000', 'P3911');
INSERT INTO SupplierProduct VALUES('S444444444', 'P3911');
INSERT INTO SupplierProduct VALUES('S000000000', 'P1232');
INSERT INTO SupplierProduct VALUES('S888888888', 'P0000');
INSERT INTO SupplierProduct VALUES('S888888888', 'P5645');
INSERT INTO SupplierProduct VALUES('S888888888', 'P8988');
INSERT INTO SupplierProduct VALUES('S999999999', 'P9999');
INSERT INTO SupplierProduct VALUES('S666666666','P4565');
INSERT INTO SupplierProduct VALUES('S666666666','P7895');
INSERT INTO SupplierProduct VALUES('S666666666','P9885');
INSERT INTO SupplierProduct VALUES('S333333333','P9885');
INSERT INTO SupplierProduct VALUES('S555555555','P0022');
INSERT INTO SupplierProduct VALUES('S555555555','P1211');
INSERT INTO SupplierProduct VALUES('S444444444','P1235');
INSERT INTO SupplierProduct VALUES('S444444444','P3265');
INSERT INTO SupplierProduct VALUES('S444444444','P4566');
INSERT INTO SupplierProduct VALUES('S000000000','P4566');
INSERT INTO SupplierProduct VALUES('S222222222','P4566');
<<<<<<< HEAD
=======
INSERT INTO SupplierProduct VALUES('S222222222','P1235');
INSERT INTO SupplierProduct VALUES('S444444444','P9283');
INSERT INTO SupplierProduct VALUES('S444444444','P1232');
>>>>>>> origin/master

INSERT INTO Quote VALUES ('QUO1022222', '2017-01-10', '2017-01-11', 'Supply of arty stuff for creative people', 'S111111111', 'E68889');
INSERT INTO Quote VALUES ('QUO2244237', '2017-02-02', '2017-02-03', 'Quote must be responded to as soon as possible to obtain your bulk supply of sitting needs', 'S222222222', 'E68889');
INSERT INTO Quote VALUES ('QUO1231238', '2017-01-12', '2017-01-13', 'This quote was obtained 20 minutes before the response was due', 'S222222222', 'E68889');
INSERT INTO Quote VALUES ('QUO1234438', '2017-03-12', '2017-03-13', '', 'S444444444', 'E12345');
INSERT INTO Quote VALUES ('QUO1231239', '2017-01-12', '2017-01-13', 'An easter special has been applied to this quote to ensure the few customers you have that have fun families will be slightly more fun.', 'S666666666', 'E68889');
INSERT INTO Quote VALUES ('QUO1234448', '2017-04-12', '2017-04-13', 'Stationary Centre staff Mary onstructed this quote a day before they required the feedback. Please respond before COB so ensure your fun stationary items will arrive in time.', 'S777777777', 'E12346');
INSERT INTO Quote VALUES ('QUO1231240', '2016-11-12', '2016-11-13', 'An easter special has been applied to this quote to ensure the few customers you have that froth over stationary will be slightly more neat.', 'S777777777', 'E12346');

<<<<<<< HEAD
INSERT INTO SupplierOrder VALUES ('SO00000011', '2017-01-04', 'This supplier order is filled with order for items that include a bulk supply of silly pens. Please refer back to quote for more information.', 'QUO1004567', 500, 'Completed','2017-01-06');
INSERT INTO SupplierOrder VALUES ('SO00000012', '2017-03-14', 'This supplier order is filled with order for items that include a bulk supply of family fun products. Please refer back to quote for more information.', 'QUO1234438', 5000, 'Completed','2017-03-15');
INSERT INTO SupplierOrder VALUES ('SO00000013', '2017-02-04', 'This supplier order is filled with order for items that include a bulk supply of silly seats. Please refer back to quote for more information.', 'QUO2244237', 2000, 'Completed','2017-02-05');
INSERT INTO SupplierOrder VALUES ('SO00000014', '2017-01-14', 'This supplier order is filled with order for items that include a bulk supply of silly body support stools. Please refer back to quote for more information.', 'QUO1231238', 1000, 'Completed','2017-01-15');
INSERT INTO SupplierOrder VALUES ('SO00000015', '2017-04-14', 'This supplier order is filled with order for items that include a supply of pretty stationary. Please refer back to quote for more information.', 'QUO1234448', 6000, 'Completed','2017-04-15');
INSERT INTO SupplierOrder VALUES ('SO00000016', '2016-11-14', 'This supplier order is filled with order for items that include a big amount of normal pens, normal paper, and 100 pack of folders to organise unorganised people. Please refer back to quote for more information.', 'QUO1231240', 2500, 'Completed','2016-11-15');
INSERT INTO SupplierOrder VALUES ('SO00000017', '2017-01-12', 'This supplier order is filled with order for items that include a small supply of creative inducing pens. Please refer back to quote for more information.', 'QUO1022222', 500, 'Completed','2017-01-14');
INSERT INTO SupplierOrder VALUES ('SO00000018', '2017-01-14', 'This supplier order is filled with order for items that include a bulk supply of fun family items. Please refer back to quote for more information.', 'QUO1231239', 1102.8, 'Completed','2017-01-16');

INSERT INTO SupplierOrderProduct VALUES ('SO00000011', 'P1234', 1.30, 2);
INSERT INTO SupplierOrderProduct VALUES ('SO00000012', 'P4565', 13, 300);
INSERT INTO SupplierOrderProduct VALUES ('SO00000013', 'P9084', 6, 6);
INSERT INTO SupplierOrderProduct VALUES ('SO00000014', 'P4566', 50.35, 20);
=======
INSERT INTO SupplierOrder VALUES ('SO00000012', '2017-03-14', 'This supplier order is filled with order for items that include a bulk supply of storage products. Please refer back to quote for more information.', 'QUO1234438', 5035, 'Completed','2017-03-15');
INSERT INTO SupplierOrder VALUES ('SO00000013', '2017-02-04', 'This supplier order is filled with order for items that include a bulk supply of seats. Please refer back to quote for more information.', 'QUO2244237', 955, 'Completed','2017-02-05');
INSERT INTO SupplierOrder VALUES ('SO00000015', '2017-04-14', 'This supplier order is filled with order for items that include a supply of pretty stationary. Please refer back to quote for more information.', 'QUO1234448', 600, 'Completed','2017-04-15');
INSERT INTO SupplierOrder VALUES ('SO00000018', '2017-01-14', 'This supplier order is filled with order for items that include a bulk supply of fun family items. Please refer back to quote for more information.', 'QUO1231239', 1102.8, 'Completed','2017-01-16');

-- SO00000012 
INSERT INTO SupplierOrderProduct VALUES ('SO00000012', 'P3911', 350, 10);
INSERT INTO SupplierOrderProduct VALUES ('SO00000012', 'P9283', 110, 10);
INSERT INTO SupplierOrderProduct VALUES ('SO00000012', 'P1232', 145, 3);

-- SO00000013
INSERT INTO SupplierOrderProduct VALUES ('SO00000013', 'P9084', 20, 14);
INSERT INTO SupplierOrderProduct VALUES ('SO00000013', 'P1235', 45, 15);

>>>>>>> origin/master
INSERT INTO SupplierOrderProduct VALUES ('SO00000015', 'P9999', 150.00, 20);
INSERT INTO SupplierOrderProduct VALUES ('SO00000015', 'P1234', 150.00, 20);

INSERT INTO SupplierOrderProduct VALUES ('SO00000018', 'P1235', 0.8, 1);
INSERT INTO SupplierOrderProduct VALUES ('SO00000018', 'P2112', 2, 1);
INSERT INTO SupplierOrderProduct VALUES ('SO00000018', 'P9999', 100, 11);

INSERT INTO CustomerOrder VALUES ('CO0001001', 'E68889', 'C1234', '2017-03-05', 0.1, 100, 50, 'Awaiting Payment', 'Phone');
INSERT INTO CustomerOrder VALUES ('CO0001002', 'E68889', 'C1239', '2017-04-05', 0, 0, 50, 'Completed', 'Online');
INSERT INTO CustomerOrder VALUES ('CO0001003', 'E68889', 'C1000', '2017-04-05', 0, 0, 50, 'Processing', 'Phone');
INSERT INTO CustomerOrder VALUES ('CO0001004', 'E68889', 'C1239', '2017-04-06', 0, 0, 100, 'Completed', 'Online');
INSERT INTO CustomerOrder VALUES ('CO0001005', 'E12346', 'C1000', '2017-04-09', 0, 120, 200, 'Awaiting Payment', 'In Store');
INSERT INTO CustomerOrder VALUES ('CO0001006', 'E12346', 'C1237', '2017-04-10', 0.2, 0, 50, 'Completed', 'Phone');
INSERT INTO CustomerOrder VALUES ('CO0001007', 'E12346', 'C1234', '2017-04-11', 0.05, 0, 150, 'Delivered', 'Phone');
INSERT INTO CustomerOrder VALUES ('CO0001008', 'E12346', 'C1237', '2017-04-11', 0.05, 0, 0, 'Cancelled', 'Phone');
INSERT INTO CustomerOrder VALUES ('CO0001009', 'E12346', 'C1221', '2017-04-20 11:18:12', 0, 930, 930, 'Completed', 'In-store');

<<<<<<< HEAD
INSERT INTO Payment VALUES ('PAY000101', '2017-03-06', 'CO0001001', 'SO00000011');
INSERT INTO Payment VALUES ('PAY000102', '2017-04-15', 'CO0001002', 'SO00000012');
INSERT INTO Payment VALUES ('PAY000103', '2017-04-10', 'CO0001003', 'SO00000013');
INSERT INTO Payment VALUES ('PAY000104', '2017-04-10', 'CO0001004', 'SO00000014');
INSERT INTO Payment VALUES ('PAY000105', '2017-04-11', 'CO0001005', 'SO00000015');
INSERT INTO Payment VALUES ('PAY000106', '2017-04-12', 'CO0001006', 'SO00000016');
INSERT INTO Payment VALUES ('PAY000107', '2017-04-15', 'CO0001007', 'SO00000017');
INSERT INTO Payment VALUES ('PAY000108', '2017-04-15', 'CO0001008', 'SO00000018');

INSERT INTO Delivery VALUES('CO0001001','88 Cornwell Street',1.25,'');
INSERT INTO Delivery VALUES('CO0001002','77/22 Aboloni Cresent',0.35,'');
INSERT INTO Delivery VALUES('CO0001003','72 Anita Close',2.10,'');
INSERT INTO Delivery VALUES('CO0001004','1 Prince Road',1.23,'');
=======
-- TO UPDATE BASED ON PRODUCT ITEM AND CUSTOMER ORDER
--CO0001001
INSERT INTO CustOrdProduct VALUES ('CO0001001', 'P1234', 2, 1.70, 8.5);
>>>>>>> origin/master

--CO0001002
INSERT INTO CustOrdProduct VALUES ('CO0001002', 'P4565', 1, 15, 8.5);

--CO0001004
INSERT INTO CustOrdProduct VALUES ('CO0001004', 'P4566', 4, 55, 8.5);

--CO0001005
INSERT INTO CustOrdProduct VALUES ('CO0001005', 'P1234', 2, 1.70, 8.5);

--CO0001006
INSERT INTO CustOrdProduct VALUES ('CO0001006', 'P2112', 1, 1.70, 8.5);

--CO0001008
INSERT INTO CustOrdProduct VALUES ('CO0001008', 'P2112', 4, 1.70, 8.5);

--Storage order
INSERT INTO CustOrdProduct VALUES ('CO0001009', 'P9283', 2, 150, 300);
INSERT INTO CustOrdProduct VALUES ('CO0001009', 'P1232', 3, 210, 630);

<<<<<<< HEAD
INSERT INTO ProductItem VALUES ('PI10000004', 'P4566', 'SO00000014', 50, 55, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000005', 'P1234', 'SO00000015', 1, 1.70, 'CO0001005', 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000006', 'P2112', 'SO00000016', 1.5, 2.5, 'CO0001006', 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000007', 'P1234', 'SO00000017', 0.50, 1.70, 'CO0001007', 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000008', 'P2112', 'SO00000018', 2, 2.5, 'CO0001008', 'in-stock');
=======
--Seating order
INSERT INTO CustOrdProduct VALUES ('CO0001003', 'P9084', 3, 30, 90);
INSERT INTO CustOrdProduct VALUES ('CO0001003', 'P1235', 3, 70, 210);

--CO0001007 paid 150 TOTAL
INSERT INTO CustOrdProduct VALUES ('CO0001007', 'P1254', 16, 2, 32);
INSERT INTO CustOrdProduct VALUES ('CO0001007', 'P1234', 2, 1.70, 8.5); -- change

INSERT INTO Payment VALUES ('PAY000101', '2017-04-15 10:50:00', NULL, 'SO00000012');
INSERT INTO Payment VALUES ('PAY000102', '2017-04-15 15:33:00', NULL, 'SO00000013');
INSERT INTO Payment VALUES ('PAY000103', '2017-04-10 16:03:00', 'CO0001003', NULL);
INSERT INTO Payment VALUES ('PAY000105', '2017-04-16 09:43:00', NULL, 'SO00000015');
INSERT INTO Payment VALUES ('PAY000108', '2017-01-18 13:19:00', NULL, 'SO00000018');
INSERT INTO Payment VALUES ('PAY000109', '2017-04-20 12:09:00', 'CO0001009', NULL);

INSERT INTO Delivery VALUES('CO0001001','88 Cornwell Street',60,'');
INSERT INTO Delivery VALUES('CO0001002','77/22 Aboloni Cresent',40,'');
INSERT INTO Delivery VALUES('CO0001003','72 Anita Close',50,'2017-04-05 12:50:00');
INSERT INTO Delivery VALUES('CO0001004','1 Prince Road',50,'');

INSERT INTO Pickup VALUES('CO0001005', '');
INSERT INTO Pickup VALUES('CO0001006', '');
INSERT INTO Pickup VALUES('CO0001007', '');
INSERT INTO Pickup VALUES('CO0001008', '2017-04-20 11:18:12');
INSERT INTO Pickup VALUES('CO0001009', '2017-04-20 11:18:12');
INSERT INTO Pickup VALUES('CO0001009', '2017-04-20 11:18:12');

>>>>>>> origin/master


---------------------
INSERT INTO ProductItem VALUES ('PI10000009', 'P9999', 'SO00000018', 100, 175.85, NULL, 'sold');
INSERT INTO ProductItem VALUES ('PI10000016', 'P9999', 'SO00000018', 100, 175.85, NULL, 'sold');
INSERT INTO ProductItem VALUES ('PI10000017', 'P9999', 'SO00000018', 100, 175.85, NULL, 'sold');
INSERT INTO ProductItem VALUES ('PI10000018', 'P9999', 'SO00000018', 100, 175.85, NULL, 'sold');
INSERT INTO ProductItem VALUES ('PI10000019', 'P9999', 'SO00000018', 100, 175.85, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000020', 'P9999', 'SO00000018', 100, 175.85, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000021', 'P9999', 'SO00000018', 100, 175.85, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000022', 'P9999', 'SO00000018', 100, 175.85, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000023', 'P9999', 'SO00000018', 100, 175.85, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000024', 'P9999', 'SO00000018', 100, 175.85, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000025', 'P9999', 'SO00000018', 100, 175.85, NULL, 'in-stock');

<<<<<<< HEAD
INSERT INTO ProductItem VALUES ('PI10000010', 'P9885', 'SO00000011', 20, 30, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000011', 'P3265', 'SO00000011', 20, 25, 'CO0001008', 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000012', 'P1235', 'SO00000018', 0.80, 2.50, 'CO0001008', 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000013', 'P3911', 'SO00000012', 2, 2.50, 'CO0001008', 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000014', 'P3265', 'SO00000017', 20, 25, 'CO0001008', 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000015', 'P0000', 'SO00000013', 159, 250, 'CO0001008', 'in-stock');
=======
INSERT INTO ProductItem VALUES ('PI10000050', 'P1235', 'SO00000013', 45, 70, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000051', 'P1235', 'SO00000013', 45, 70, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000052', 'P1235', 'SO00000013', 45, 70, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000053', 'P1235', 'SO00000013', 45, 70, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000054', 'P1235', 'SO00000013', 45, 70, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000055', 'P1235', 'SO00000013', 45, 70, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000056', 'P1235', 'SO00000013', 45, 70, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000057', 'P1235', 'SO00000013', 45, 70, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000058', 'P1235', 'SO00000013', 45, 70, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000059', 'P1235', 'SO00000013', 45, 70, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000060', 'P1235', 'SO00000013', 45, 70, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000061', 'P1235', 'SO00000013', 45, 70, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000062', 'P1235', 'SO00000013', 45, 70, 'CO0001003', 'sold');
INSERT INTO ProductItem VALUES ('PI10000063', 'P1235', 'SO00000013', 45, 70, 'CO0001003', 'sold');
INSERT INTO ProductItem VALUES ('PI10000064', 'P1235', 'SO00000013', 45, 70, 'CO0001003', 'sold');

INSERT INTO ProductItem VALUES ('PI10000065', 'P9084', 'SO00000013', 20, 30, NULL, 'in-stock'); 
INSERT INTO ProductItem VALUES ('PI10000066', 'P9084', 'SO00000013', 20, 30, NULL, 'in-stock'); 
INSERT INTO ProductItem VALUES ('PI10000067', 'P9084', 'SO00000013', 20, 30, NULL, 'in-stock'); 
INSERT INTO ProductItem VALUES ('PI10000068', 'P9084', 'SO00000013', 20, 30, NULL, 'in-stock'); 
INSERT INTO ProductItem VALUES ('PI10000069', 'P9084', 'SO00000013', 20, 30, NULL, 'in-stock'); 
INSERT INTO ProductItem VALUES ('PI10000070', 'P9084', 'SO00000013', 20, 30, NULL, 'in-stock'); 
INSERT INTO ProductItem VALUES ('PI10000071', 'P9084', 'SO00000013', 20, 30, NULL, 'in-stock'); 
INSERT INTO ProductItem VALUES ('PI10000072', 'P9084', 'SO00000013', 20, 30, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000073', 'P9084', 'SO00000013', 20, 30, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000074', 'P9084', 'SO00000013', 20, 30, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000075', 'P9084', 'SO00000013', 20, 30, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000076', 'P9084', 'SO00000013', 20, 30, 'CO0001003', 'sold');
INSERT INTO ProductItem VALUES ('PI10000077', 'P9084', 'SO00000013', 20, 30, 'CO0001003', 'sold');
INSERT INTO ProductItem VALUES ('PI10000078', 'P9084', 'SO00000013', 20, 30, 'CO0001003', 'sold');



INSERT INTO ProductItem VALUES ('PI10000079', 'P3911', 'SO00000012',350, 460, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000080', 'P3911', 'SO00000012',350, 460, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000081', 'P3911', 'SO00000012',350, 460, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000082', 'P3911', 'SO00000012',350, 460, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000083', 'P3911', 'SO00000012',350, 460, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000084', 'P3911', 'SO00000012',350, 460, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000085', 'P3911', 'SO00000012',350, 460, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000086', 'P3911', 'SO00000012',350, 460, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000087', 'P3911', 'SO00000012',350, 460, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000088', 'P3911', 'SO00000012',350, 460, NULL, 'in-stock');

INSERT INTO ProductItem VALUES ('PI10000089', 'P9283', 'SO00000012',110, 150, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000091', 'P9283', 'SO00000012',110, 150, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000092', 'P9283', 'SO00000012',110, 150, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000093', 'P9283', 'SO00000012',110, 150, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000094', 'P9283', 'SO00000012',110, 150, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000095', 'P9283', 'SO00000012',110, 150, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000096', 'P9283', 'SO00000012',110, 150, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000097', 'P9283', 'SO00000012',110, 150, NULL, 'in-stock');
INSERT INTO ProductItem VALUES ('PI10000098', 'P9283', 'SO00000012',110, 150, 'CO0001009', 'sold');
INSERT INTO ProductItem VALUES ('PI10000099', 'P9283', 'SO00000012',110, 150, 'CO0001009', 'sold');

INSERT INTO ProductItem VALUES ('PI10000100', 'P1232', 'SO00000012',145, 210, 'CO0001009', 'sold');
INSERT INTO ProductItem VALUES ('PI10000101', 'P1232', 'SO00000012',145, 210, 'CO0001009', 'sold');
INSERT INTO ProductItem VALUES ('PI10000102', 'P1232', 'SO00000012',145, 210, 'CO0001009', 'sold');


-- Stationary Product Items
-- SO00000015 HAS 600 product items
-- Product P1234
INSERT INTO ProductItem VALUES('PI10001001', 'P1234','SO00000015', 1, 1.70, NULL, 'in-stock');
INSERT INTO ProductItem VALUES('PI10001002', 'P1234','SO00000015', 1, 1.70, NULL, 'in-stock');
INSERT INTO ProductItem VALUES('PI10001003', 'P1234','SO00000015', 1, 1.70, NULL, 'in-stock');
INSERT INTO ProductItem VALUES('PI10001004', 'P1234','SO00000015', 1, 1.70, NULL, 'in-stock');
INSERT INTO ProductItem VALUES('PI10001005', 'P1234','SO00000015', 1, 1.70, NULL, 'in-stock');
INSERT INTO ProductItem VALUES('PI10001006', 'P1234','SO00000015', 1, 1.70, NULL, 'in-stock');
INSERT INTO ProductItem VALUES('PI10001007', 'P1234','SO00000015', 1, 1.70, 'CO0001001', 'sold');
INSERT INTO ProductItem VALUES('PI10001008', 'P1234','SO00000015', 1, 1.70, 'CO0001001', 'sold');
INSERT INTO ProductItem VALUES('PI10001009', 'P1234','SO00000015', 1, 1.70, 'CO0001001', 'sold');
INSERT INTO ProductItem VALUES('PI10001010', 'P1234','SO00000015', 1, 1.70, 'CO0001001', 'sold');
INSERT INTO ProductItem VALUES('PI10001011', 'P1234','SO00000015', 1, 1.70, 'CO0001001', 'sold');
INSERT INTO ProductItem VALUES('PI10001012', 'P1234','SO00000015', 1, 1.70, 'CO0001001', 'sold');
INSERT INTO ProductItem VALUES('PI10001013', 'P1234','SO00000015', 1, 1.70, 'CO0001001', 'sold');
INSERT INTO ProductItem VALUES('PI10001012', 'P1234','SO00000015', 1, 1.70, 'CO0001001', 'sold');
INSERT INTO ProductItem VALUES('PI10001013', 'P1234','SO00000015', 1, 1.70, 'CO0001001', 'sold');

--Product P1223 OUT OF STOCK IN PRODUCT
INSERT INTO ProductItem VALUES('PI10001214', 'P1223','SO00000015', 0.75, 1.50, 'CO0001002', 'sold');
INSERT INTO ProductItem VALUES('PI10001213', 'P1223','SO00000015', 0.75, 1.50, 'CO0001002', 'sold');
INSERT INTO ProductItem VALUES('PI10001214', 'P1223','SO00000015', 0.75, 1.50, 'CO0001002', 'sold');
INSERT INTO ProductItem VALUES('PI10001215', 'P1223','SO00000015', 0.75, 1.50, 'CO0001002', 'sold');
INSERT INTO ProductItem VALUES('PI10001216', 'P1223','SO00000015', 0.75, 1.50, 'CO0001003', 'sold');
INSERT INTO ProductItem VALUES('PI10001217', 'P1223','SO00000015', 0.75, 1.50, 'CO0001003', 'sold');
INSERT INTO ProductItem VALUES('PI10001218', 'P1223','SO00000015', 0.75, 1.50, 'CO0001003', 'sold');
INSERT INTO ProductItem VALUES('PI10001219', 'P1223','SO00000015', 0.75, 1.50, 'CO0001003', 'sold');
INSERT INTO ProductItem VALUES('PI10001220', 'P1223','SO00000015', 0.75, 1.50, 'CO0001003', 'sold');
INSERT INTO ProductItem VALUES('PI10001221', 'P1223','SO00000015', 0.75, 1.50, 'CO0001003', 'sold');
INSERT INTO ProductItem VALUES('PI10001222', 'P1223','SO00000015', 0.75, 1.50, 'CO0001006', 'sold');
INSERT INTO ProductItem VALUES('PI10001223', 'P1223','SO00000015', 0.75, 1.50, 'CO0001003', 'sold');
INSERT INTO ProductItem VALUES('PI10001224', 'P1223','SO00000015', 0.75, 1.50, 'CO0001007', 'sold');
INSERT INTO ProductItem VALUES('PI10001225', 'P1223','SO00000015', 0.75, 1.50, 'CO0001003', 'sold');
INSERT INTO ProductItem VALUES('PI10001226', 'P1223','SO00000015', 0.75, 1.50, 'CO0001003', 'sold');
INSERT INTO ProductItem VALUES('PI10001227', 'P1223','SO00000015', 0.75, 1.50, 'CO0001003', 'sold');

-- Product P1254
INSERT INTO ProductItem VALUES('PI00001301', 'P1254', 'SO00000015', 1.02, 2.00, 'CO0001007', 'sold');
INSERT INTO ProductItem VALUES('PI00001302', 'P1254', 'SO00000015', 1.02, 2.00, 'CO0001007', 'sold');
INSERT INTO ProductItem VALUES('PI00001303', 'P1254', 'SO00000015', 1.02, 2.00, 'CO0001007', 'sold');
INSERT INTO ProductItem VALUES('PI00001304', 'P1254', 'SO00000015', 1.02, 2.00, 'CO0001007', 'sold');
INSERT INTO ProductItem VALUES('PI00001305', 'P1254', 'SO00000015', 1.02, 2.00, 'CO0001007', 'sold');
INSERT INTO ProductItem VALUES('PI00001306', 'P1254', 'SO00000015', 1.02, 2.00, 'CO0001007', 'sold');
INSERT INTO ProductItem VALUES('PI00001307', 'P1254', 'SO00000015', 1.02, 2.00, 'CO0001007', 'sold');
INSERT INTO ProductItem VALUES('PI00001308', 'P1254', 'SO00000015', 1.02, 2.00, 'CO0001007', 'sold');
INSERT INTO ProductItem VALUES('PI00001309', 'P1254', 'SO00000015', 1.02, 2.00, 'CO0001007', 'sold');
INSERT INTO ProductItem VALUES('PI00001310', 'P1254', 'SO00000015', 1.02, 2.00, 'CO0001007', 'sold');
INSERT INTO ProductItem VALUES('PI00001311', 'P1254', 'SO00000015', 1.02, 2.00, 'CO0001007', 'sold');
INSERT INTO ProductItem VALUES('PI00001312', 'P1254', 'SO00000015', 1.02, 2.00, 'CO0001007', 'sold');
INSERT INTO ProductItem VALUES('PI00001313', 'P1254', 'SO00000015', 1.02, 2.00, 'CO0001007', 'sold');
INSERT INTO ProductItem VALUES('PI00001314', 'P1254', 'SO00000015', 1.02, 2.00, 'CO0001007', 'sold');
INSERT INTO ProductItem VALUES('PI00001315', 'P1254', 'SO00000015', 1.02, 2.00, 'CO0001007', 'sold');
INSERT INTO ProductItem VALUES('PI00001316', 'P1254', 'SO00000015', 1.02, 2.00, 'CO0001007', 'sold');
INSERT INTO ProductItem VALUES('PI00001317', 'P1254', 'SO00000015', 1.02, 2.00, NULL, 'in-stock');
INSERT INTO ProductItem VALUES('PI00001318', 'P1254', 'SO00000015', 1.02, 2.00, NULL, 'in-stock');
INSERT INTO ProductItem VALUES('PI00001319', 'P1254', 'SO00000015', 1.02, 2.00, NULL, 'in-stock');

--Product P2112
INSERT INTO ProductItem VALUES('PI00002100', 'P2112', 'SO00000015', 1.50, 3.00, NULL, 'in-stock');
INSERT INTO ProductItem VALUES('PI00002101', 'P2112', 'SO00000015', 1.50, 3.00, NULL, 'in-stock');
INSERT INTO ProductItem VALUES('PI00002102', 'P2112', 'SO00000015', 1.50, 3.00, NULL, 'in-stock');
INSERT INTO ProductItem VALUES('PI00002103', 'P2112', 'SO00000015', 1.50, 3.00, NULL, 'in-stock');
INSERT INTO ProductItem VALUES('PI00002104', 'P2112', 'SO00000015', 1.50, 3.00, 'CO0001006', 'sold');
INSERT INTO ProductItem VALUES('PI00002105', 'P2112', 'SO00000015', 1.50, 3.00, 'CO0001006', 'sold');
INSERT INTO ProductItem VALUES('PI00002106', 'P2112', 'SO00000015', 1.50, 3.00, 'CO0001006', 'sold');
INSERT INTO ProductItem VALUES('PI00002107', 'P2112', 'SO00000015', 1.50, 3.00, 'CO0001006', 'sold');
INSERT INTO ProductItem VALUES('PI00002108', 'P2112', 'SO00000015', 1.50, 3.00, 'CO0001006', 'sold');
INSERT INTO ProductItem VALUES('PI00002109', 'P2112', 'SO00000015', 1.50, 3.00, 'CO0001006', 'sold');
INSERT INTO ProductItem VALUES('PI00002110', 'P2112', 'SO00000015', 1.50, 3.00, 'CO0001006', 'sold');
INSERT INTO ProductItem VALUES('PI00002111', 'P2112', 'SO00000015', 1.50, 3.00, 'CO0001006', 'sold');
INSERT INTO ProductItem VALUES('PI00002112', 'P2112', 'SO00000015', 1.50, 3.00, 'CO0001006', 'sold');
INSERT INTO ProductItem VALUES('PI00002113', 'P2112', 'SO00000015', 1.50, 3.00, 'CO0001006', 'sold');
INSERT INTO ProductItem VALUES('PI00002114', 'P2112', 'SO00000015', 1.50, 3.00, 'CO0001006', 'sold');

>>>>>>> origin/master



<<<<<<< HEAD
INSERT INTO CustOrdProduct VALUES ('CO0001001', 'P1234', 2, 1.70, 8.5);
INSERT INTO CustOrdProduct VALUES ('CO0001002', 'P4565', 1, 15, 8.5);
INSERT INTO CustOrdProduct VALUES ('CO0001003', 'P9084', 3, 140, 8.5);
INSERT INTO CustOrdProduct VALUES ('CO0001004', 'P4566', 4, 55, 8.5);
INSERT INTO CustOrdProduct VALUES ('CO0001005', 'P1234', 2, 1.70, 8.5);
INSERT INTO CustOrdProduct VALUES ('CO0001006', 'P2112', 1, 1.70, 8.5);
INSERT INTO CustOrdProduct VALUES ('CO0001007', 'P1234', 2, 1.70, 8.5);
INSERT INTO CustOrdProduct VALUES ('CO0001008', 'P2112', 4, 1.70, 8.5);

=======
>>>>>>> origin/master
INSERT INTO Assignment VALUES('A1234', 'E12345', 'P22311', '2010-12-12', NULL);
INSERT INTO Assignment VALUES('A1235', 'E12346', 'P33223', '2010-12-12', NULL);
INSERT INTO Assignment VALUES('A1236', 'E12347', 'P33223', '2009-01-12', '2009-07-09');
INSERT INTO Assignment VALUES('A1222', 'E12347', 'P22311', '2009-07-10', NULL);
INSERT INTO Assignment VALUES('A1237', 'E12348', 'P90999', '2001-04-21', NULL);
INSERT INTO Assignment VALUES('A1238', 'E12349', 'P90999', '2007-04-21', NULL);
INSERT INTO Assignment VALUES('A1239', 'E68889', 'P22222', '2001-05-04', NULL);
INSERT INTO Assignment VALUES('A1230', 'E89897', 'P33211', '2004-09-09', '2005-10-11');
INSERT INTO Assignment VALUES('A1241', 'E89897', 'P22311', '2005-10-12', NULL);
INSERT INTO Assignment VALUES('A1231', 'E12213', 'P22343', '2008-11-23', NULL);
INSERT INTO Assignment VALUES('A1232', 'E00099', 'P22343', '2008-07-24', NULL);
INSERT INTO Assignment VALUES('A1233', 'E98898', 'P33223', '2010-12-12', '2015-12-24');

INSERT INTO QuoteProduct VALUES ('QUO1004567', 'P1234',  200, 0.8);
INSERT INTO QuoteProduct VALUES ('QUO1022222', 'P2112',  200, 1.70);
<<<<<<< HEAD
INSERT INTO QuoteProduct VALUES ('QUO2244237', 'P9084',  150, 140);
=======
>>>>>>> origin/master
INSERT INTO QuoteProduct VALUES ('QUO1231238', 'P4566',  15, 55);

--Seating things
INSERT INTO QuoteProduct VALUES ('QUO2244237', 'P9084',  14, 20);
INSERT INTO QuoteProduct VALUES ('QUO2244237', 'P1235', 15, 45);

--SO00000012 
INSERT INTO QuoteProduct VALUES ('QUO1234438', 'P3911',  10, 350);
INSERT INTO QuoteProduct VALUES ('QUO1234438', 'P9283',  10, 110);
INSERT INTO QuoteProduct VALUES ('QUO1234438', 'P1232',  10, 145);

INSERT INTO QuoteProduct VALUES ('QUO1231239', 'P9885',  80, 10.00);
INSERT INTO QuoteProduct VALUES ('QUO1234448', 'P1254',  150, 1.02);
INSERT INTO QuoteProduct VALUES ('QUO1231240', 'P1223',  200, 0.75);


GO
 
-- Determining the delivery date to 5 days after the customer order has been made.
CREATE PROCEDURE usp_OrderDelivery5To7Days
  AS
  	DECLARE @custOrdID VARCHAR(10)
	DECLARE @date DATE
 	SET @custOrdID = ''
 	DECLARE weekendCursor CURSOR
 	FOR 
 	SELECT custOrdID
 	FROM CustomerOrder

	-- Essentially determining all the customer orders assoicated with a delivery (and not a pickup).
 	WHERE custOrdID NOT IN(SELECT custOrdID FROM Pickup)
 	FOR READ ONLY
 
 	OPEN weekendCursor
  	FETCH NEXT FROM weekendCursor INTO @custOrdID
  	WHILE @@FETCH_STATUS = 0
  		BEGIN 
  			SET @date =  (SELECT orderDateTime FROM CustomerOrder WHERE CustomerOrder.custOrdID = @custOrdID)

			-- 5 days will be added to the date the order was made (orderDate).
 			UPDATE Delivery SET delDateTime = DATEADD(day, 5, @date)
 			FROM CustomerOrder, Delivery
 			WHERE Delivery.custOrdID = @custOrdID
  			FETCH NEXT FROM weekendCursor INTO @custOrdID	
  		END
  	CLOSE weekendCursor
	DEALLOCATE weekendCursor
 GO

-- Determining the pickup date to 3 days after the customer order has been made.
 CREATE PROCEDURE usp_PickupOrderIn3Days
 AS
 	-- So the Customer can pick up their order, 3 days after they have submitted their order.
 	UPDATE Pickup SET pickupDateTime = DATEADD(day, 3, CustomerOrder.orderDateTime)
 	FROM CustomerOrder, Pickup
 	WHERE CustomerOrder.custOrdID = Pickup.custOrdID
 GO
 
 EXECUTE usp_OrderDelivery5To7Days
 EXECUTE usp_PickupOrderIn3Days
 GO

 DROP PROCEDURE usp_OrderDelivery5To7Days
 DROP PROCEDURE usp_PickupOrderIn3Days
 GO