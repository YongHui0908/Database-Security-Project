-- Switch to master to create logins
USE master;
GO

-- Create logins for Data Admins
CREATE LOGIN DA1 WITH PASSWORD = 'SecurePassword1!';
CREATE LOGIN DA2 WITH PASSWORD = 'SecurePassword2!';
