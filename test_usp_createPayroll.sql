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
	DECLARE @payslipID VARCHAR(10);
	DECLARE @employeeID VARCHAR(10);
	DECLARE @taxBracketID VARCHAR(10);
	DECLARE @startDate DATE;
	DECLARE @endDate DATE;
	DECLARE @workedHours FLOAT;
	DECLARE @basePay 
    ,@allowanceBonus AllowanceInfo READONLY
AS
BEGIN
    INSERT INTO Payslip
    SELECT @startDate
        ,@endDate
        ,n.hoursWorked
        ,p.hourlyRate
        ,p.hourlyRate * n.hoursWorked
        ,(p.hourlyRate * n.hoursWorked) + a.allowanceAmount
        ,((p.hourlyRate * n.hoursWorked) + a.allowanceAmount) * t.taxRate / 100
        ,@taxID
        ,a.allowanceID
        ,n.employeeID
    FROM @workedHours n
        ,@allowanceBonus a
        ,Position p
        ,Employee e
        ,Tax t
    WHERE p.positionID = e.positionID
        AND e.employeeID = n.employeeID
        AND t.taxID = @taxID
END

DECLARE @employeeInfo EmployeeInfo;
DECLARE @hoursWorked INT;

INSERT @employeeInfo
SELECT e.employeeID
    ,@hoursWorked
FROM Employee e
WHERE e.employeeID = 1
    AND @hoursWorked = 160

DECLARE @allowanceInfo AllowanceInfo;
DECLARE @empInfo EmployeeInfo

INSERT @allowanceInfo
SELECT e.employeeID
    ,a.allowanceID
    ,a.allowanceAmount
FROM Employee e
    ,Allowance a
    ,@empInfo emp
WHERE e.employeeID = emp.employeeID
    AND a.allowanceID = 1

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
