-- Created by: Jamie Sy
-- Student number: 3207040
-- Date created: 20-Apr-2017


-- User defined function to auto-increment payslipID without having to change payslipID to INT
create function nextPayslipNo ()
returns char (8)
as
begin
	declare @lastval char(8)
	set @lastval = (select max(payslipID) from Payslip)
	if @lastval is null set @lastval = 'PS00000110'
	declare @i int
	set @i = right(@lastval,7)+1
	return 'PS' + right ('00' + convert(varchar(10),@i,7)
end

-- Table Valued parameters
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
			payslipID,
			n.employeeID,
			@taxBracketID,
			@startDate,
			@endDate,
			n.workedHours,
			n.workedHours * p.hourlyRate, -- calculates base pay
			(n.workedHours * p.hourlyRate) * t.taxRate, -- calculates tax payable: assume that tax is not deducted from allowances
			(n.workedHours * p.hourlyRate) - ((n.workedHours * p.hourlyRate) * t.taxRate) -- calculates net pay = base pay - tax payable
		FROM
			@noHoursWorked n,
			@allowanceBonus a,
			Position p,
			Assignment pa,
			TaxBracket t,
		WHERE
			n.employeeID = pa.employeeID
			AND p.positionID = pa.positionID
			AND t.taxBracketID = @taxBracketID
END


-- inserts the imput parameters into @employeeInfo
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


-- inserts the imput parameters into @allowanceInfo
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
