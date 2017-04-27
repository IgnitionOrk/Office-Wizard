/*
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
*/

CREATE PROCEDURE usp_createPayroll 
AS
	@payslipID VARCHAR(10);
	@employeeID VARCHAR(10);
	@taxBracketID VARCHAR(10);
	@startDate DATE;
	@endDate DATE;
	@workedHours FLOAT;
	@basePay 
    ,@allowanceBonus AllowanceInfo READONLY
AS
BEGIN


EXECUTE usp_createPayroll;
GO
/*
start date (input) – Start date for start of pay period
end date (input) – End date for pay period
employee hours worked information (input) – A table-valued parameter with employee
id and hours worked for the pay period.
employee allowance information (input) – A table-valued parameter with employee id,
allowance type id and allowance amount.
*/
/*
In this stored procedure, employee payslips for the given employees will be generated
and stored in the database. Note that base pay, taxable income, tax and net pay needs
to be calculated and stored for each payslip.
Note that all errors must be caught and handled. Appropriate error messages must be
raised. The stored procedure must be extensively tested in the test script.
*/
