-- Created by: Jamie Sy
-- Student number: 3207040
-- Date created: 20-Apr-2017

--Needed when testing and changing statements
DROP PROCEDURE usp_generatePayslipPK
DROP PROCEDURE usp_createPayroll
GO


DROP TYPE EmployeeInfo
DROP TYPE AllowanceInfo
GO


--User defined function to auto-increment payslipID without having to change payslipID to INT
--finds the highest payslipID in the database, increments it by 1 and uses that for the new order
CREATE PROCEDURE usp_generatePayslipPK @newID VARCHAR(10) OUTPUT
AS
	DECLARE @highestID VARCHAR(10) = '00000000';
	DECLARE @tempID VARCHAR(10);

	--create cursor with custOrdIDs
	DECLARE cursorIDs CURSOR FOR
	SELECT payslipID
	FROM Payslip;
BEGIN
	OPEN cursorIDs
	FETCH NEXT FROM cursorIDs INTO @tempID
	WHILE @@FETCH_STATUS = 0
	BEGIN
		--remove front 2 characters so we can do integer comparison and to increment by 1 for newID
		SET @tempID = SUBSTRING(@tempID, 3, 10);
		--find highest ID
		IF @tempID >  @highestID
			SET @highestID = @tempID;			
		FETCH NEXT FROM cursorIDs INTO @tempID
	END
	CLOSE cursorIDs   
	DEALLOCATE cursorIDs	--close and remove cursor

	--increment highest ID by 1, pad zeroes on the left hand side and add the 'PS' to identify as a payslip ID
	SET @newID = @highestID+1;
	SET @newID = RIGHT('0000000' +  @newID, 7);
	SET @newID = LEFT('PS' + @newID, 10);	
END;
GO

------------------------------------------------------------------------------------
-- Table Valued parameters
-- employee hours worked information
CREATE TYPE EmployeeInfo AS TABLE 
(
    employeeID VARCHAR(10),
    workedHours INT,
    PRIMARY KEY (
        employeeID,
        workedHours
        )
);
GO

-- employee allowance information
CREATE TYPE AllowanceInfo AS TABLE 
(
    employeeID VARCHAR(10),
    allowanceTypeID VARCHAR(10),
    amount FLOAT
    PRIMARY KEY (
        employeeID,
        allowanceTypeID,
        amount
        )
);
GO
-- End of Table valued parameters


------------------------------------------------------------------------------------
-- Payroll procedure
CREATE PROCEDURE usp_createPayroll
	@payslipID	VARCHAR(10) OUTPUT,
	@startDate	DATE,
	@endDate	DATE,
	@taxBracketID	VARCHAR(10),
	@noHoursWorked EmployeeInfo READONLY,
	@allowanceBonus AllowanceInfo READONLY
AS
BEGIN
	DECLARE @newPayslipID VARCHAR(10);
	--get a unique ID for the payslipID
	--need to store the ID in the non-output variable as errors would occur
	EXECUTE usp_generatePayslipPK @newPayslipID OUTPUT;
	SET @payslipID = @newPayslipID;


	INSERT INTO payslip
		SELECT 
			@payslipID,
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
			TaxBracket t
		WHERE
			n.employeeID = pa.employeeID
			AND p.positionID = pa.positionID
			AND t.taxBracketID = @taxBracketID
END

------------------------------------------------------------------------------------
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
	a.allowanceTypeID,
	a.amount
FROM 
	Employee e,
	Allowance a,
	EmployeeAllowanceType ea,
	@employeeInfo emp
WHERE
	e.employeeID = emp.employeeID
	AND emp.employeeID = ea.employeeID
	AND a.allowanceTypeID = ea.allowanceTypeID

-- Payslip (payslipID, employeeID, taxBracketID, startDate, endDate, workedHours, basePay, taxPayable, netPay)

EXECUTE usp_createPayroll
GO
