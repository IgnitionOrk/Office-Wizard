-- Created by: Jamie Sy
-- Student number: 3207040
-- Date created: 20-Apr-2017

/*REQUIREMENTS
start date (input) – Start date for start of pay period
end date (input) – End date for pay period
employee hours worked information (input) – A table-valued parameter with employee
id and hours worked for the pay period.
employee allowance information (input) – A table-valued parameter with employee id,
allowance type id and allowance amount.

In this stored procedure, employee payslips for the given employees will be generated
and stored in the database. Note that base pay, taxable income, tax and net pay needs
to be calculated and stored for each payslip.
Note that all errors must be caught and handled. Appropriate error messages must be
raised. The stored procedure must be extensively tested in the test script.
*/

/* 
	-- initial script to auto-generate payslip ID for this procedure but has since been changed on the actual payslip entity
	CREATE PROCEDURE create_payslipID
	(
	   @payslipNumberID int,
	   @payDate datetime  
	) AS Begin 

	-- calc 5th digit:
	DECLARE @fifthDigit int;
	SELECT 
	    @fifthDigit = count(*) + 1
	FROM payslipNumber AS bb
	INNER JOIN ItemMfg ii ON ii.payslipNumberID = bb.payslipNumberID 
	where bb.payslipNumberID = @payslipNumberID             -- single payslipNumber-row to get ItemType
	    AND ii.payDate <= @payate                              -- all previous datetimes
	    AND cast(ii.payDate as date) = cast(@payDate as date)   -- same day

	-- ManufactureID is Identity (i.e. autoincremented)
	INSERT INTO ItemMfg (payslipNumberID, payDate, SerialNumber)
	    SELECT @payslipNumberID
	        , @payDate
	        , 'PS' + bb.ItemType + cast(@fifthDigit as varchar(5))
	    FROM payslipNumber bb
	    WHERE bb.payslipNumber = @payslipNumber
	;

	END */


--ADD ERRORS AND STUFF

CREATE TYPE EmployeeInfo AS TABLE 
(
    employeeID INT,
    workedHours INT,
    PRIMARY KEY (
        employeeID,
        workedHours
        )
);
GO

CREATE TYPE AllowanceInfo AS TABLE 
(
    employeeID INT,
    allowanceID INT,
    allowanceAmount DECIMAL(7, 2),
    PRIMARY KEY (
        employeeID,
        allowanceID,
        allowanceAmount
        )
);
GO

CREATE PROCEDURE usp_createPayroll
	@startDate	DATE,
	@endDate	DATE,
	@taxBracketID	INT,
	@noHoursWorked EmployeeInfo READONLY,
	@allowanceBonus AllowanceInfo READONLY
    
AS
BEGIN
	INSERT INTO payslip
		SELECT 
			n.employeeID,
			n.taxBracketID,
			@startDate,
			@endDate,
			n.workedHours,
			n.workedHours * p.hourlyRate,
			(n.workedHours * p.hourlyRate) * t.taxRate, -- assumed that tax is not deducted from allowances
			(n.wokedHours * p.hourlyRate) - ((n.workedHours * p.hourlyRate) * t.taxRate)
		FROM
			@noHoursWorked n,
			@allowanceBonus a,
			Position p,
			Assignment pa,
			TaxBracket t
		WHERE
			p.positionID = pa.positionID
			AND pa.employeeID = n.employeeID
			AND t.taxBracketID = @taxBracketID
END


DECLARE @employeeInfo EmployeeInfo;
DECLARE @workedHours INT;

INSERT @employeeInfo
	SELECT 
		e.employeeID,
		@workedHours
	FROM 
		Employee e
	WHERE
		e.employeeID = 1
		AND @workedHours < 50


DECLARE @allowanceInfo AllowanceInfo;
DECLARE @emp EmployeeInfo;

INSERT @allowanceInfo
SELECT 
	e.employeeID, 
	a.allowanceID,
	a.amount
FROM 
	Employee e,
	Allowance a,
	EmployeeAllowanceType ea,
	@employeeInfo emp
WHERE
	e.employeeID = emp.employeeID
	AND emp.employeeID = ea.employeeID
	AND a.allowanceID = ea.allowanceID

-- Payslip (payslipID, employeeID, taxBracketID, startDate, endDate, workedHours, basePay, taxPayable, netPay)

EXECUTE usp_createPayroll
GO



