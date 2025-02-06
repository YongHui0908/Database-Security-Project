-- Switch to the database
USE ApArenaManagementSystemDB;

create login COMMAN
with password = 'comman123'

create user COMMAN for login COMMAN

alter role ComplexManager add member COMMAN

create login DAAD
with password = 'daad123'

create user DAAD for login DAAD

alter role DataAdmin add member DAAD

create login TOMORG
with password = 'tomorg123'

create user TOMORG for login TOMORG

alter role TournamentOrganizer add member TOMORG

create login INDICUS
with password = 'indicus123'

create user INDICUS for login INDICUS

alter role IndividualCustomer add member INDICUS

---test

CREATE FUNCTION dbo.fn_usersecuritypredicate(@Username AS NVARCHAR(50))
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS result
WHERE @Username = USER_NAME();  -- Assuming USER_NAME() returns the Username of the logged-in user

CREATE SECURITY POLICY dbo.UserSecurityPolicy
ADD FILTER PREDICATE dbo.fn_usersecuritypredicate(Username)
ON dbo.Users  -- Use fully qualified name
WITH (STATE = ON);

CREATE VIEW User_Data AS
SELECT 
    UserID, 
    UserType, 
    Username, 
    Email, 
    PhoneNumber, 
    CreatedAt, 
    UpdatedAt 
FROM 
    dbo.Users
WHERE 
    IsDeleted = 0;  -- Exclude deleted users

	GRANT SELECT ON User_Data TO ComplexManager;
	GRANT SELECT ON ComplexManDetails TO IndividualCustomer;

	SELECT * FROM User_Data;
	SELECT * FROM Users;

	-- Drop the security policy first
DROP SECURITY POLICY dbo.UserSecurityPolicy;

-- Drop the view if it depends on the function
DROP VIEW User_Data;

-- Finally, drop the function
DROP FUNCTION dbo.fn_usersecuritypredicate;


SELECT * FROM Facility;
SELECT * FROM Tournament
SELECT * FROM Booking
SELECT * FROM BusinessEntity


-- Create users in the database
CREATE USER DA1 FOR LOGIN DA1;
CREATE USER DA2 FOR LOGIN DA2;

-- Create roles for role-based access control
CREATE ROLE DataAdmin; -- Role for managing users and permissions
CREATE ROLE ComplexManager; -- Role for managing facilities and approvals
CREATE ROLE TournamentOrganizer; -- Role for creating and managing tournaments
CREATE ROLE IndividualCustomer; -- Role for individual facility booking

-- Assign users to roles
EXEC sp_addrolemember 'DataAdmin', 'DA1';
EXEC sp_addrolemember 'DataAdmin', 'DA2';

-- Grant permissions to roles
-- DataAdmin permissions
GRANT SELECT (UserID, UserType) ON Users TO DataAdmin;
GRANT INSERT, UPDATE, DELETE ON Users TO DataAdmin;
GRANT SELECT, INSERT, UPDATE, DELETE ON Facility TO DataAdmin;
GRANT SELECT, DELETE ON Booking TO DataAdmin; 
GRANT SELECT On Users TO DataAdmin

-- ComplexManager permissions
GRANT SELECT, UPDATE ON Booking TO ComplexManager;

-- IndividualCustomer permissions
GRANT SELECT, INSERT, UPDATE ON Booking TO IndividualCustomer;

-- TournamentOrganizer permissions
GRANT SELECT, INSERT, UPDATE ON Tournament TO TournamentOrganizer;
