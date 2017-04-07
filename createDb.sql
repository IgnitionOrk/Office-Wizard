--Created by: 
	--  Ryan Cunneen  :(c3179234)
	--  Micay Conway  :(c3232648)
	--  Jamie Sy	 	  :(c3207040)
--Date Created 4/4/2017
--Date Modified 4/4/2017

--Foreign key tables:
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
DROP TABLE Allowance
DROP TABLE TaxBracket

CREATE TABLE Supplier
(
	supplierID							VARCHAR(10),
	sName									VARCHAR(100)					NOT NULL,
	address								VARCHAR(100)					NOT NULL,
	phoneNo								VARCHAR(12)						NOT NULL,
	faxNo									VARCHAR(12)						DEFAULT NULL,
	contactPerson					VARCHAR(50)						DEFAULT NULL,
	PRIMARY KEY(supplierID)
);
GO

CREATE TABLE ProductCategory
(
	categoryID							VARCHAR(10),
	categoryName					VARCHAR(25)						NOT NULL,
	PRIMARY KEY(categoryID) 
);
GO

CREATE TABLE Product
(
	productID							VARCHAR(10),
	pName								VARCHAR(50)						NOT NULL,
	manufacturer						VARCHAR(20),
	categoryID							VARCHAR(10)						NOT NULL,
	pDescription						VARCHAR(255),
	qtyDescription					VARCHAR(100),
	unitPrice								FLOAT									CHECK(unitPrice != 0.00),
	pStatus								VARCHAR(10)						CHECK(pStatus IN('available', 'out of stock')),
	availQty								INT										CHECK(availQty >= 0),
	reorderLevel						INT										CHECK(reorderLevel > 0),
	maxDiscount						FLOAT									CHECK(maxDiscount >= 0.00),
	PRIMARY KEY(productID),
	FOREIGN KEY(categoryID) REFERENCES ProductCategory(categoryID) ON DELETE CASCADE
);
GO

CREATE TABLE SupplierProduct
(
	supplierID							VARCHAR(10),
	productID							VARCHAR(10),
	FOREIGN KEY(supplierID) REFERENCES Supplier(supplierID),
	FOREIGN KEY(productID) REFERENCES Product(productID)
);
GO

CREATE TABLE Employee
(
	employeeID							VARCHAR(10),
	eName								VARCHAR(100),
	gender									CHAR(1)								CHECK(gender IN('M', 'F', 'O')),
	phoneNo								VARCHAR(12)						NOT NULL,
	homeAddress						VARCHAR(100)					NOT NULL,
	homePhone						VARCHAR(12),
	dob										DATE									CHECK(dob BETWEEN  '1900-01-01' AND GETDATE()),
	PRIMARY KEY(employeeID)
);
GO

CREATE TABLE CustomerOrder
(
	custOrdID							VARCHAR(10),
	employeeID							VARCHAR(10)						DEFAULT NULL,
	_date									DATE									NOT NULL,								--Date is already defined as a data type. 
	discountGiven						FLOAT									DEFAULT NULL, 
	amountDue							FLOAT,
	amountPAID						FLOAT, 
	custOrdStatus						VARCHAR(10)						CHECK(custOrdStatus IN ('Processing','Delivered','Cancelled','Awaiting Payment','Completed')),
	modeOfSale						VARCHAR(10)						CHECK(modeOfSale IN ('Online','In Store','Phone')),
	PRIMARY KEY(custOrdID),
	FOREIGN KEY(employeeID) REFERENCES Employee(employeeID)
);
GO

CREATE TABLE Quote
(
	quoteID								VARCHAR(10),
	qDate						    		DATE									NOT NULL,
	validPeriod							DATE,
	qDescription						VARCHAR(255)					DEFAULT NULL,
	supplierID							VARCHAR(10)						NOT NULL, 
	employeeID							VARCHAR(10)						NOT NULL,
	PRIMARY KEY(quoteID),
	FOREIGN KEY(supplierID) REFERENCES Supplier(supplierID),
	FOREIGN KEY(employeeID) REFERENCES Employee(employeeID)	
);
GO

CREATE TABLE QuoteProduct
(
	productID							VARCHAR(10),
	quoteID								VARCHAR(10),
	qty										INT										CHECK(qty > 0),
	unitPrice								FLOAT,
	FOREIGN KEY(productID) REFERENCES Product(productID),
	FOREIGN KEY(quoteID) REFERENCES Quote(quoteID),
	PRIMARY KEY(productID, quoteID)
);
GO

CREATE TABLE SupplierOrder
(
	suppOrdID				    		VARCHAR(10),
	suppOrdDate						DATE									NOT NULL, --Date in which the order was made
	supplierID							VARCHAR(10)						NOT NULL,
	suppOrdDescription			VARCHAR(255)					DEFAULT NULL,
	quoteID								VARCHAR(10)						NOT NULL,
	totalAmount						FLOAT									CHECK(totalAmount > 0),
	suppOrdStatus					VARCHAR(10)						CHECK(suppOrdStatus  IN ('Processing','Delivered','Cancelled','Awaiting Payment','Completed')),
	suppOrdRcvDate				DATE									NOT NULL,
	PRIMARY KEY(suppOrdID),
	FOREIGN KEY(supplierID) REFERENCES Supplier(supplierID),
	FOREIGN KEY(quoteID) REFERENCES Quote(quoteID)
);
GO

CREATE TABLE ProductItem
(
	itemNo								VARCHAR(10),
	productID							VARCHAR(10)						NOT NULL,
	suppOrdID							VARCHAR(10)						NOT NULL,
	costPrice								FLOAT									CHECK(costPrice > 0), 
	sellingPrice							FLOAT									CHECK(sellingPrice > 0),
	custOrdID							VARCHAR(10)						NOT NULL,
	status									VARCHAR(10)						CHECK(status IN('in-stock', 'sold', 'lost')),
	PRIMARY KEY(itemNo),
	FOREIGN KEY(productID) REFERENCES Product(productID),
	FOREIGN KEY(suppOrdID) REFERENCES SupplierOrder(suppOrdID),
	FOREIGN KEY(custOrdID) REFERENCES CustomerOrder(custOrdID)
);
GO

CREATE TABLE SupplierOrderProduct
(
	suppOrdID							VARCHAR(10)						NOT NULL,
	productID							VARCHAR(10)						NOT NULL,
	unitPurchasePrice				FLOAT,
	qty										INT,
	FOREIGN KEY(suppOrdID) REFERENCES SupplierOrder(suppOrdID),
	FOREIGN KEY(productID) REFERENCES Product(productID)
);
GO


CREATE TABLE Customer
(
	customerID							VARCHAR(10),
	cName									VARCHAR(100)					NOT NULL,
	address								VARCHAR(100)					NOT NULL,
	phoneNo								VARCHAR(12)						NOT NULL,
	faxNo									VARCHAR(12)						NOT NULL,
	email									VARCHAR(100),
	contactPerson   					VARCHAR(100)					DEFAULT NULL,		--Only provide if the customer is a company
	gender									CHAR(1)								CHECK(gender IN('M', 'F', 'O')),
	PRIMARY KEY(customerID)
);
GO

CREATE TABLE CustOrdProduct
(
	custOrdID							VARCHAR(10),
	productID							VARCHAR(10),
	qty										INT										CHECK(qty > 0),
	unitPurchasePrice				FLOAT,
	subtotal								FLOAT,
	FOREIGN KEY(custOrdID) REFERENCES CustomerOrder(custOrdID),
	FOREIGN KEY(productID) REFERENCES Product(productID)
);
GO

CREATE TABLE Delivery
(
	custOrdID							VARCHAR(10),
	delAddress							VARCHAR(100)					NOT NULL,
	delCharge							FLOAT									CHECK(delCharge >= 0.00),
	delDate								DATETIME							NOT NULL,
	FOREIGN KEY(custOrdID) REFERENCES CustomerOrder(custOrdID)
);
GO

CREATE TABLE Pickup
(
	custOrdID	    					VARCHAR(10),
	pickupDateTime	    			DATETIME							NOT NULL,
	FOREIGN KEY(custOrdID) REFERENCES CustomerOrder(custOrdID)
);
GO

CREATE TABLE Payment
(
	paymentRefNo		    		VARCHAR(10),
	paymentDate			    		DATE									NOT NULL,
	custOrdID							VARCHAR(10)						NOT NULL,
	suppOrdID							VARCHAR(10)						NOT NULL,
	PRIMARY KEY(paymentRefNo),
	FOREIGN KEY(custOrdID) REFERENCES CustomerOrder(custOrdID),
	FOREIGN KEY(suppOrdID) REFERENCES SupplierOrder(suppOrdID)

);
GO

CREATE TABLE Position
(
	positionID						VARCHAR(10),
	positionName					VARCHAR(10)							NOT NULL,
	hourlyRate						FLOAT										CHECK(hourlyRate > 0.00),
	PRIMARY KEY(positionID)
);
GO

CREATE TABLE Assignment
(
	assignmentID					VARCHAR(10),
	employeeID						VARCHAR(10)							NOT NULL,
	positionID						VARCHAR(10)							NOT NULL,
	startDate							DATE										CHECK(startDate >= GETDATE()),
	finishDate						DATE										DEFAULT NULL,
	PRIMARY KEY(assignmentID, employeeID, positionID),
	FOREIGN KEY(employeeID) REFERENCES Employee(employeeID),
	FOREIGN KEY(positionID) REFERENCES Position(positionID)
);
GO

-- added from feedback
CREATE TABLE Allowance 
(
	allowanceID					VARCHAR(10),
	amount							FLOAT,
	description						VARCHAR(100),
	PRIMARY KEY(allowanceID)
);
GO

CREATE TABLE AllowanceType
(
	allowanceTypeID			VARCHAR(10),
	allowType						VARCHAR(50)							CHECK(allowType IN('Sales bonus')),		--Check again once assignment 1 feedback is given
	aDescription					VARCHAR(100),       
	frequency						VARCHAR(10)							CHECK(frequency IN('yearly', 'monthly', 'quarterly', 'daily')),
	PRIMARY KEY(allowanceTypeID)
);
GO

CREATE TABLE TaxBracket
(
	taxBracketID					VARCHAR(10),
	startAmount					FLOAT										CHECK(startAmount > 0),
	endAmount						FLOAT,
	taxRate							FLOAT,
	effectiveYear					CHAR(4),
	PRIMARY KEY(taxBracketID)
);
GO

CREATE TABLE Payslip
(
	payslipID							VARCHAR(10),
	employeeID						VARCHAR(10)						NOT NULL,
	startDate							DATE,
	endDate							DATE,
	workedHours			    	FLOAT									CHECK(workedHours >= 0),
	hourlyRate						FLOAT									CHECK(hourlyRate >= 0.00),
	basePay							FLOAT,
	allowanceID					VARCHAR(10)						DEFAULT NULL,
	taxBracketID					VARCHAR(10)						NOT NULL,
	taxableIncome				FLOAT,
	netPay								FLOAT,
	PRIMARY KEY(payslipID),
	FOREIGN KEY(employeeID) REFERENCES Employee(employeeID),
	FOREIGN KEY(allowanceID) REFERENCES Allowance(allowanceID),
	FOREIGN KEY(taxBracketID) REFERENCES TaxBracket(taxBracketID)
);
GO

INSERT INTO Supplier VALUES('S111111111', 'World of Pens', '121 Industrial Rd', '123456789012', '1234-1234-12', 'Mary Jane');
INSERT INTO Supplier VALUES('S222222222', 'Chair R Us', '11 Matthew Avenue',  '210987654321',  '12-4321-4321', 'Bob Walts');
INSERT INTO Supplier VALUES('S333333333', 'Paper Industries', '123/34 Cresent Head', '1234567192', '000-0000-00', 'Gary Mancolo');
INSERT INTO Supplier VALUES('S444444444', 'Furniture galore', '123/34 Cresent Head',  '1111111111', NULL , 'Ryan Sallvitore');
INSERT INTO Supplier VALUES('S555555555', 'Your Stock', '11 Matthew Avenue',  '0407022211', NULL , 'Sasha');

 SELECT * 
 FROM Supplier