-- Created by: Jamie Sy
-- Student number: 3207040
-- Date Created: 26-Apr-2017
-- Date modified: 1-May-2017

--Output parameters
DECLARE @payslipID VARCHAR(10);

--comment out following line to remove testing - used to compare before and after state of Payslip table
SELECT * FROM Payslip

--test case 0
DECLARE @employeeHours AS dbo.EmployeeInfo
DECLARE @employeeAllowance AS dbo.AllowanceInfo
INSERT INTO @employeeHours VALUES ('E12345',15);
INSERT INTO @employeeAllowance VALUES ('E12345', 'AT7779966',40);
EXECUTE usp_createPayroll '2017-01-20', '2017-01-25', 'T111111',@employeeHours, @employeeAllowance, @payslipID;
--test case 1
DECLARE @employeeHours1 AS dbo.EmployeeInfo
DECLARE @employeeAllowance1 AS dbo.AllowanceInfo
INSERT INTO @employeeHours1 VALUES ('E12348',15);
INSERT INTO @employeeAllowance1 VALUES ('E12348', 'AT7787987',0);
EXECUTE usp_createPayroll '2017-01-20', '2017-01-25', 'T111111',@employeeHours, @employeeAllowance, @payslipID;
--test case 2
DECLARE @employeeHours2 AS dbo.EmployeeInfo
DECLARE @employeeAllowance2 AS dbo.AllowanceInfo
INSERT INTO @employeeHours2 VALUES ('E12347',15);
INSERT INTO @employeeAllowance2 VALUES ('E12347', 'AT6568565',10);
EXECUTE usp_createPayroll '2017-02-20', '2017-02-25', 'T111111',@employeeHours, @employeeAllowance, @payslipID;
--test case 3
DECLARE @employeeHours3 AS dbo.EmployeeInfo
DECLARE @employeeAllowance3 AS dbo.AllowanceInfo
INSERT INTO @employeeHours3 VALUES ('E12213',15);
INSERT INTO @employeeAllowance3 VALUES ('E12213', 'AT7778878',10);
EXECUTE usp_createPayroll '2017-04-20', '2017-04-25', 'T556555',@employeeHours, @employeeAllowance, @payslipID;
--test case 4
DECLARE @employeeHours4 AS dbo.EmployeeInfo
DECLARE @employeeAllowance4 AS dbo.AllowanceInfo
INSERT INTO @employeeHours4 VALUES ('E98898',15);
INSERT INTO @employeeAllowance4 VALUES ('E98898', 'AT0970970',20);
EXECUTE usp_createPayroll '2017-04-20', '2017-04-25', 'T111111',@employeeHours, @employeeAllowance, @payslipID;

--comment out following line to remove testing
SELECT * FROM Payslip
