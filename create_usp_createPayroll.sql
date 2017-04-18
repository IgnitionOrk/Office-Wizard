CREATE PROCEDURE usp_createPayroll
AS
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

GO
