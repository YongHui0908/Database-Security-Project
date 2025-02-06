USE ApArenaManagementSystemDB;
GO
select * from Users

-- Create Schema for user to edit only they data
CREATE SCHEMA Security;
GO

CREATE FUNCTION Security.securitypredicate(
	@Username AS varchar(50))
	RETURNS TABLE
WITH SCHEMABINDING
AS
	RETURN SELECT 1 AS securitypredicate_result
WHERE @Username = USER_NAME() OR IS_MEMBER('Data Admin') = 1 OR IS_MEMBER('Individual Customer') = 1 OR IS_MEMBER('Tournament Organizer') = 1;
GO

CREATE SECURITY POLICY userFilter
ADD FILTER PREDICATE Security.securitypredicate(Username)
ON dbo.Users
WITH (STATE = ON);

ALTER SECURITY POLICY userFilter WITH ( STATE = OFF );


ALTER SECURITY POLICY userFilter WITH ( STATE = ON );

CREATE VIEW ComplexManDetails AS
SELECT
	UserID,
    Username,
    PhoneNumber,
    Email
FROM
    Users

select * from users

CREATE OR ALTER VIEW CustomerDetails AS
SELECT
   UserID,
   Username,
   PhoneNumber,
   Email
FROM
   Users
WHERE
   UserType = 'Individual Customer';
GO

CREATE OR ALTER VIEW DataAdminDetails AS
SELECT
   UserID,
   Username,
   PhoneNumber,
   Email
FROM
   Users
WHERE
   UserType = 'Data Admin';
GO

CREATE OR ALTER VIEW OrganizerDetails AS
SELECT
   UserID,
   Username,
   PhoneNumber,
   Email
FROM
   Users
WHERE
   UserType = 'Tournament Organizer';
GO

-- Grant SELECT permission on ComplexManDetails view
GRANT SELECT ON ComplexManDetails TO ComplexManager;

-- Grant SELECT permission on CustomerDetails view
GRANT SELECT ON CustomerDetails TO ComplexManager;

-- Grant SELECT permission on DataAdminDetails view
GRANT SELECT ON DataAdminDetails TO ComplexManager;

-- Grant SELECT permission on OrganizerDetails view
GRANT SELECT ON OrganizerDetails TO ComplexManager;
GO


GRANT EXECUTE ON OBJECT::UpdateComplexManagerDetails TO [ComplexManager];
GO

GRANT SELECT ON AuditLog TO DataAdmin;

CREATE OR ALTER PROCEDURE UpdateComplexManagerDetails
    @NewPhoneNumber NVARCHAR(15),
    @NewEmail NVARCHAR(100)
AS
BEGIN
    -- Enable error handling
    BEGIN TRY
        -- Update the PhoneNumber and Email for the currently logged-in user
        UPDATE dbo.Users
        SET
            PhoneNumber = @NewPhoneNumber,
            Email = @NewEmail
        WHERE
            Username = USER_NAME();

        -- Check if any rows were updated
        IF @@ROWCOUNT = 0
        BEGIN
            THROW 50001, 'No rows were updated. Ensure you have permission to update your details.', 1;
        END

        PRINT 'User details updated successfully.';
    END TRY
    BEGIN CATCH
        -- Handle errors
        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

--Delete User For DataAdmin
CREATE OR ALTER PROCEDURE DeleteUser
    @UserID VARCHAR(50)
AS BEGIN 
	SET NOCOUNT ON;
 
	IF EXISTS (SELECT 0 FROM Users WHERE UserID = @UserID AND IsDeleted = 0)
	BEGIN
	DELETE FROM Users WHERE UserID = @UserID;
 
	END
	ELSE
	BEGIN
         RAISERROR('User does not exist or already deleted.', 16, 1);
     END
END;
 
--Delete Booking For DataAdmin
CREATE OR ALTER PROCEDURE DeleteBooking
    @BookingID VARCHAR(50)
AS BEGIN 
	SET NOCOUNT ON;
 
	IF EXISTS (SELECT 1 FROM Booking WHERE @BookingID = @BookingID AND IsDeleted = 0)
	BEGIN
	DELETE FROM Booking WHERE BookingID = @BookingID;
 
	END
	ELSE
	BEGIN
         RAISERROR('Booking does not exist or already deleted.', 16, 1);
     END
END;
 
--Delete Facility For DataAdmin
CREATE OR ALTER PROCEDURE DeleteFacility
    @FacilityID VARCHAR(50)
AS BEGIN 
	SET NOCOUNT ON;
 
	IF EXISTS (SELECT 1 FROM Facility WHERE FacilityID = @FacilityID AND IsDeleted = 0)
	BEGIN
	DELETE FROM Facility WHERE FacilityID = @FacilityID;
 
	END
	ELSE
	BEGIN
         RAISERROR('Facility does not exist or already deleted.', 16, 1);
     END
END;
 
 --Recover Soft Deleted User For DataAdmin
CREATE OR ALTER PROCEDURE RecoverSoftDeletedUser
    @UserID VARCHAR(50)
AS BEGIN 
	SET NOCOUNT ON;
 
	IF EXISTS (SELECT 1 FROM Users WHERE UserID = @UserID AND IsDeleted = 1)
	BEGIN
	UPDATE Users SET IsDeleted = 0 WHERE UserID = @UserID;
 
	-- Log the action in AuditLog
	DECLARE @TESTINGID INT = SCOPE_IDENTITY();
        INSERT INTO AuditLog (UserID, Action, TableName, Timestamp, Details, SessionID)
        VALUES (
            @TESTINGID,
            'Recover',
            'User',
            GETDATE(),
            CONCAT('Recover booking: BookingID = ', @UserID),
            NEWID()
        );
	END
	ELSE
	BEGIN
         RAISERROR('User is not marked as soft delete or does not exist.', 16, 1);
     END
END;
 
--Recover Soft Deleted Booking For DataAdmin
CREATE OR ALTER PROCEDURE RecoverSoftDeletedBooking
    @BookingID VARCHAR(50)
AS BEGIN 
	SET NOCOUNT ON;
 
	IF EXISTS (SELECT 1 FROM Booking WHERE BookingID = @BookingID AND IsDeleted = 1)
	BEGIN
	UPDATE Booking SET IsDeleted = 0 WHERE BookingID = @BookingID;
 
	-- Log the action in AuditLog
		DECLARE @UserID INT = SCOPE_IDENTITY();
        INSERT INTO AuditLog (UserID, Action, TableName, Timestamp, Details, SessionID)
        VALUES (
            @UserID,
            'Recover',
            'Booking',
            GETDATE(),
            CONCAT('Recover booking: BookingID = ', @BookingID),
            NEWID()
        );
	END
	ELSE
	BEGIN
         RAISERROR('User is not marked as soft delete or does not exist.', 16, 1);
     END
END;
 
--Recover Soft Deleted Facility For DataAdmin
CREATE OR ALTER PROCEDURE RecoverSoftDeletedFacility
    @FacilityID VARCHAR(50)
AS BEGIN 
	SET NOCOUNT ON;
 
	IF EXISTS (SELECT 1 FROM Facility WHERE FacilityID = @FacilityID AND IsDeleted = 1)
	BEGIN
	UPDATE Facility SET IsDeleted = 0 WHERE FacilityID = @FacilityID;
 
	-- Log the action in AuditLog
		DECLARE @UserID INT = SCOPE_IDENTITY();
        INSERT INTO AuditLog (UserID, Action, TableName, Timestamp, Details, SessionID)
        VALUES (
            @UserID,
            'Recover',
            'Facility',
            GETDATE(),
            CONCAT('Recover booking: BookingID = ', @FacilityID),
            NEWID()
        );
	END
	ELSE
	BEGIN
         RAISERROR('User is not marked as soft delete or does not exist.', 16, 1);
     END
END;
 
GRANT EXEC ON RecoverSoftDeletedUser TO DataAdmin;
GRANT EXEC ON RecoverSoftDeletedBooking TO DataAdmin;
GRANT EXEC ON RecoverSoftDeletedFacility TO DataAdmin;

select * from Booking
GRANT EXEC ON DeleteUser to DataAdmin;
GRANT EXEC ON DeleteBooking to DataAdmin;
GRANT EXEC ON DeleteFacility to DataAdmin;

CREATE or ALTER PROCEDURE GrantORDenyPermission
	@Action NVARCHAR(50),
    @TableName NVARCHAR(128), -- Table to grant permission on
    @RoleName NVARCHAR(128),  -- Role to grant permission to
    @Permission NVARCHAR(50)  -- Permission to grant (e.g., INSERT, UPDATE, DELETE)
WITH EXECUTE AS OWNER -- Execute as the owner of the stored procedure (dbo)
AS
BEGIN
	-- Check if the role is DataAdmin or a role that DataAdmin is a member of
    IF @RoleName = 'DataAdmin' OR EXISTS (
        SELECT 1
        FROM sys.database_role_members rm
        JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
        JOIN sys.database_principals m ON rm.member_principal_id = m.principal_id
        WHERE r.name = @RoleName AND m.name = 'DataAdmin'
    )
    BEGIN
        -- Raise an error if the role is DataAdmin or a role that DataAdmin is a member of
        THROW 50001, 'DataAdmin cannot grant permissions to itself or its roles.', 1;
    END
	
	IF @Action NOT IN ('GRANT', 'DENY') 
    BEGIN
        -- Raise an error if the role is DataAdmin or a role that DataAdmin is a member of
        THROW 50001, 'Action can ONLY be GRANT or DENY.', 1;
    END

	-- Check if the table exists
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = @TableName)
    BEGIN
        -- Raise an error if the table does not exist
        THROW 50003, 'The specified table does not exist.', 1;
    END

	IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @RoleName AND type = 'R')
    BEGIN
        -- Raise an error if the role does not exist
        THROW 50004, 'The specified role does not exist.', 1;
    END;

	IF @Permission NOT IN ('SELECT', 'UPDATE', 'INSERT', 'DELETE') 
    BEGIN
        -- Raise an error if the role is DataAdmin or a role that DataAdmin is a member of
        THROW 50001, 'Permission is Invalid. Valid permissions: SELECT, INSERT, UPDATE, DELETE.', 1;
    END

	-- Construct and execute the dynamic SQL
    BEGIN TRY
        DECLARE @SQL NVARCHAR(MAX);
        IF @Action = 'GRANT'
        BEGIN
            SET @SQL = 'GRANT ' + @Permission + ' ON ' + QUOTENAME(@TableName) + ' TO ' + QUOTENAME(@RoleName) + ';';
        END
        ELSE IF @Action = 'DENY'
        BEGIN
            SET @SQL = 'DENY ' + @Permission + ' ON ' + QUOTENAME(@TableName) + ' TO ' + QUOTENAME(@RoleName) + ';';
        END;

        EXEC sp_executesql @SQL;

        -- Log the action in AuditLog
        INSERT INTO AuditLog (UserID, Action, TableName, Timestamp, Details, SessionID)
        VALUES (
            NULL, -- UserID is NULL because the action is performed by the stored procedure
            @Action,
            @TableName,
            GETDATE(),
            CONCAT(@Action,' ', @Permission, ' ON ', @TableName, ' TO ', @RoleName),
            NEWID()
        );
    END TRY
    BEGIN CATCH
        -- Handle any unexpected errors
        THROW;
    END CATCH;
END;
GO
GRANT EXECUTE ON GrantORDenyPermission TO DataAdmin;


-----test---

-- Insert a test Complex Manager
INSERT INTO Users (UserType, Username, Password, Email, PhoneNumber)
VALUES ('Complex Manager', 'COMMAN', HASHBYTES('SHA2_256', 'SecurePassword123'), 'test@aparena.com', '0123456789');
GRANT SELECT ON vw_ComplexManagerDetails TO ComplexManager;



-- Deny DELETE permission on the Users table
DENY DELETE ON Users TO ComplexManager;
-------- Procedure: Create User -----------
CREATE OR ALTER PROCEDURE CreateUser
    @UserType NVARCHAR(50),
    @Username NVARCHAR(50),
    @Password NVARCHAR(50),
    @Email NVARCHAR(100),
    @PhoneNumber NVARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Check if the username already exists
        IF EXISTS (SELECT 1 FROM Users WHERE Username = @Username)
        BEGIN
            THROW 50001, 'Error: Username already exists.', 1;
        END

        -- Insert the new user
        INSERT INTO Users (UserType, Username, Password, Email, PhoneNumber, IsDeleted, CreatedAt)
        VALUES (@UserType, @Username, HASHBYTES('SHA2_256', CONCAT(@Password, 'SaltValue')), @Email, @PhoneNumber, 0, GETDATE());

        -- Log action in AuditLog
        DECLARE @UserID INT = SCOPE_IDENTITY();
        INSERT INTO AuditLog (UserID, Action, TableName, Timestamp, Details, SessionID)
        VALUES (@UserID, 'Insert', 'Users', GETDATE(), CONCAT('New user created: ', @Username), NEWID());

        COMMIT TRANSACTION;
        PRINT 'User created successfully.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT ERROR_MESSAGE();
    END CATCH
END;
GO
SELECT * FROM Users

EXEC CreateUser 
    @UserType = 'Individual Customer', @Username = 'xiaoxinjie', @Password = 'SecurePass123', @Email = 'xinjie@aparena.com', @PhoneNumber = '0123456789';

EXEC CreateUser 
    @UserType = 'IndividualCustomer', @Username = 'xiaojiahao', @Password = 'SecurePass123', @Email = 'jiahao@aparena.com', @PhoneNumber = '0123456789';

EXEC CreateUser 
    @UserType = 'Tournament Organizer', @Username = 'jackin', @Password = 'SecurePass123', @Email = 'jackin@aparena.com', @PhoneNumber = '0123456789';

EXEC CreateUser 
    @UserType = 'Tournament Organizer', @Username = 'qiwiie', @Password = 'SecurePass123', @Email = 'qiwiie@aparena.com', @PhoneNumber = '0123456789';

EXEC CreateUser 
    @UserType = 'Complex Manager', @Username = 'louis', @Password = 'SecurePass123', @Email = 'louis@aparena.com', @PhoneNumber = '0123456789';

EXEC CreateUser 
    @UserType = 'Complex Manager', @Username = 'Joe', @Password = 'SecurePass123', @Email = 'joe@aparena.com', @PhoneNumber = '0123456789';

EXEC CreateUser 
    @UserType = 'Data Admin', @Username = 'xiaohui', @Password = 'SecurePass123', @Email = 'xiaohui@aparena.com', @PhoneNumber = '0123456789';

EXEC CreateUser 
    @UserType = 'Data Admin', @Username = 'xiaoai', @Password = 'SecurePass123', @Email = 'xiaoai@aparena.com', @PhoneNumber = '0123456789';

GRANT EXECUTE ON CreateUser TO DataAdmin;



--------- Procedure: Create Complex Manager --------------
CREATE OR ALTER PROCEDURE CreateComplexManager
    @UserID INT,
    @AssignedFacility NVARCHAR(100) -- Specific courts or areas
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Validate if the user is already a ComplexManager
        IF NOT EXISTS (SELECT 1 FROM Users WHERE UserID = @UserID AND UserType = 'Complex Manager')
        BEGIN
            THROW 70001, 'Error: User is not eligible to be a ComplexManager.', 1;
        END

        -- Insert the ComplexManager
        INSERT INTO ComplexManager (UserID, AssignedFacility, CreatedAt)
        VALUES (@UserID, @AssignedFacility, GETDATE());

        -- Log the action
        INSERT INTO AuditLog (UserID, Action, TableName, Timestamp, Details, SessionID)
        VALUES (@UserID, 'Insert', 'ComplexManager', GETDATE(), 'ComplexManager created.', NEWID());

        COMMIT TRANSACTION;
        PRINT 'ComplexManager created successfully.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT ERROR_MESSAGE();
    END CATCH
END;
GO
select * from Users

GRANT EXECUTE ON CreateComplexManager TO DataAdmin;
SELECT * FROM AuditLog WHERE TableName = 'Booking';

EXEC CreateComplexManager @UserID = 13, @AssignedFacility = 'Basketball Court';
EXEC CreateComplexManager @UserID = 14, @AssignedFacility = 'Badminton Court';

SELECT * FROM ComplexManager;


-------- Procudure: Update Completed Manager ---------
CREATE OR ALTER PROCEDURE UpdateComplexManager
    @ManagerID INT,
    @AssignedFacility NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Validate if the ComplexManager exists
        IF NOT EXISTS (SELECT 1 FROM ComplexManager WHERE ManagerID = @ManagerID)
        BEGIN
            THROW 70002, 'ComplexManagerNotFound: Complex Manager not found.', 1;
        END

        -- Update assigned facilities
        UPDATE ComplexManager
        SET AssignedFacility = @AssignedFacility
        WHERE ManagerID = @ManagerID;

        -- Log the update
        INSERT INTO AuditLog (UserID, Action, TableName, Timestamp, Details, SessionID)
        VALUES (NULL, 'Update', 'ComplexManager', GETDATE(), CONCAT('ManagerID: ', @ManagerID, ' facilities updated.'), NEWID());

        COMMIT TRANSACTION;
        PRINT 'ComplexManager details updated successfully.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT ERROR_MESSAGE();
    END CATCH
END;
GO

select * from ComplexManager

GRANT EXECUTE ON UpdateComplexManager TO DataAdmin;


-------- Procedure: Add Facility -----------
CREATE OR ALTER PROCEDURE AddFacility
    @FacilityType NVARCHAR(50),
    @Capacity INT,
    @Rate DECIMAL(10, 2)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Insert new facility
        INSERT INTO Facility (FacilityType, Availability, Capacity, Rate, CreatedAt, IsDeleted)
        VALUES (@FacilityType, 1, @Capacity, @Rate, GETDATE(), 0);

        -- Log the action
        INSERT INTO AuditLog (UserID, Action, TableName, Timestamp, Details, SessionID)
        VALUES (NULL, 'Insert', 'Facility', GETDATE(), CONCAT('Facility created: ', @FacilityType), NEWID());

        COMMIT TRANSACTION;
        PRINT 'Facility added successfully.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT ERROR_MESSAGE();
    END CATCH
END;
GO

GRANT EXECUTE ON AddFacility TO DataAdmin;

EXEC AddFacility @FacilityType = 'Indoor Volleyball Court', @Capacity = 48, @Rate = 180.00;
EXEC AddFacility @FacilityType = 'Badminton Court', @Capacity = 60, @Rate = 250.00;
EXEC AddFacility @FacilityType = 'Basketball Court', @Capacity = 40, @Rate = 150.00;
EXEC AddFacility @FacilityType = 'Squash Court', @Capacity = 10, @Rate = 120.00;
EXEC AddFacility @FacilityType = 'Olympic-sized Swimming Pool', @Capacity = 30, @Rate = 200.00;

SELECT * FROM Facility;

------- Procudure: Update Facility ----------
CREATE OR ALTER PROCEDURE UpdateFacility
    @FacilityID INT,
    @Rate DECIMAL(10, 2),
    @Availability BIT,
	@UserID INT = NULL -- Add UserID parameter with default NULL value
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Validate if the facility exists
        IF NOT EXISTS (SELECT 1 FROM Facility WHERE FacilityID = @FacilityID AND IsDeleted = 0)
        BEGIN
            THROW 70003, 'Error: Facility not found or deleted.', 1;
        END

        -- Update facility details
        UPDATE Facility
        SET Rate = @Rate, Availability = @Availability, UpdatedAt = GETDATE()
        WHERE FacilityID = @FacilityID;

		-- Provide a default UserID for logging if NULL
        IF @UserID IS NULL
        BEGIN
            SET @UserID = (SELECT TOP 1 UserID FROM Users WHERE Username = SYSTEM_USER);
        END

        -- Log the update
        INSERT INTO AuditLog (UserID, Action, TableName, Timestamp, Details, SessionID)
        VALUES (@UserID, 'Update', 'Facility', GETDATE(), CONCAT('FacilityID: ', @FacilityID, ' updated to Rate: ', @Rate, ', Availability: ', @Availability), NEWID());

        COMMIT TRANSACTION;
        PRINT 'Facility updated successfully.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT ERROR_MESSAGE();
    END CATCH
END;
GO

GRANT EXECUTE ON UpdateFacility TO DataAdmin;

EXEC UpdateFacility 
    @FacilityID = 7,
    @Rate = 260.00,
    @Availability = 20;

SELECT * FROM Facility
select * from Booking

-------- Procudure: Add Facility Schedule --------------
CREATE OR ALTER PROCEDURE AddFacilitySchedule
    @FacilityID INT,
    @Date DATE,
    @StartTime TIME,
    @EndTime TIME,
    @Status NVARCHAR(20) -- Available, Booked, Maintenance
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Validate overlapping schedules: Ensure no time overlap on the same facility and date
        IF EXISTS (
            SELECT 1
            FROM FacilitySchedule
            WHERE FacilityID = @FacilityID
              AND Date = @Date
              AND NOT (@StartTime >= EndTime OR @EndTime <= StartTime)
        )
        BEGIN
            THROW 70004, 'Error: Overlapping schedule for the specified facility.', 1;
        END

        -- Insert facility schedule
        INSERT INTO FacilitySchedule (FacilityID, Date, StartTime, EndTime, Status)
        VALUES (@FacilityID, @Date, @StartTime, @EndTime, @Status);

        -- Log the action
        DECLARE @UserID INT = (SELECT TOP 1 UserID FROM Users WHERE Username = SYSTEM_USER);
        INSERT INTO AuditLog (UserID, Action, TableName, Timestamp, Details, SessionID)
        VALUES (
            @UserID,
            'Insert',
            'FacilitySchedule',
            GETDATE(),
            CONCAT('Schedule added for FacilityID: ', @FacilityID, ', Date: ', @Date, ', Time: ', @StartTime, ' - ', @EndTime, ', Status: ', @Status),
            NEWID()
        );

        COMMIT TRANSACTION;
        PRINT 'Facility schedule added successfully.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT ERROR_MESSAGE();
    END CATCH
END;
GO

-- Grant Execute Permissions
GRANT EXECUTE ON AddFacilitySchedule TO DataAdmin;

EXEC AddFacilitySchedule @FacilityID = 1, @Date = '2025-01-25', @StartTime = '09:00', @EndTime = '11:00', @Status = 'Maintenance';
EXEC AddFacilitySchedule @FacilityID = 2, @Date = '2025-01-22', @StartTime = '09:00', @EndTime = '11:00', @Status = 'Available';
EXEC AddFacilitySchedule @FacilityID = 2, @Date = '2025-01-22', @StartTime = '11:00', @EndTime = '13:00', @Status = 'Booked';
SELECT * FROM FacilitySchedule;


-------- Procedure: Update Facility Schedule ------------
CREATE OR ALTER PROCEDURE UpdateFacilitySchedule
    @ScheduleID INT,
    @Status NVARCHAR(20), -- Available, Booked, Maintenance
	@UserID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Validate if the schedule exists
        IF NOT EXISTS (SELECT 1 FROM FacilitySchedule WHERE ScheduleID = @ScheduleID)
        BEGIN
            THROW 70005, 'Error: Facility schedule not found.', 1;
        END

        -- Update schedule status
        UPDATE FacilitySchedule
        SET Status = @Status, UpdatedAt = GETDATE()
        WHERE ScheduleID = @ScheduleID;

		-- Provide a default UserID for logging if NULL
        IF @UserID IS NULL
        BEGIN
            SET @UserID = (SELECT TOP 1 UserID FROM Users WHERE Username = SYSTEM_USER);
        END

        -- Log the update
        INSERT INTO AuditLog (UserID, Action, TableName, Timestamp, Details, SessionID)
        VALUES (@UserID, 'Update', 'FacilitySchedule', GETDATE(), CONCAT('ScheduleID: ', @ScheduleID, ' updated to Status: ', @Status), NEWID());

        COMMIT TRANSACTION;
        PRINT 'Facility schedule updated successfully.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT ERROR_MESSAGE();
    END CATCH
END;
GO

GRANT EXECUTE ON UpdateFacilitySchedule TO DataAdmin;

EXEC UpdateFacilitySchedule 
    @ScheduleID = 2, 
    @Status = 'Booked';

	SELECT * FROM  FacilitySchedule

	GRANT SELECT ON dbo.FacilitySchedule TO DataAdmin;

---------- Procedure: Register Business Entity ---------------
---------- Procedure: Register Business Entity ---------------
CREATE OR ALTER PROCEDURE InsertBusinessEntity
    @OrganizerID INT,
    @Name NVARCHAR(100),
    @Contact NVARCHAR(15),
    @Email NVARCHAR(100),
    @Address NVARCHAR(255),
    @Status NVARCHAR(20) = 'Pending' -- Default value is 'Pending'
AS
BEGIN
    SET NOCOUNT ON;
 
    -- Check if the OrganizerID already has a registered business entity
    IF EXISTS (
        SELECT 1 
        FROM BusinessEntity 
        WHERE OrganizerID = @OrganizerID
    )
    BEGIN
        PRINT 'Error: A business entity is already registered for this organizer.';
        RETURN;
    END
 
    -- Insert the business entity data
    INSERT INTO BusinessEntity (OrganizerID, Name, Contact, Email, Address, Status)
    VALUES (@OrganizerID, @Name, @Contact, @Email, @Address, @Status);
 
	-- Log the action
    DECLARE @UserID INT = (SELECT TOP 1 UserID FROM Users WHERE Username = SYSTEM_USER);
	INSERT INTO AuditLog (UserID, Action, TableName, Timestamp, Details, SessionID)
        VALUES (
            @UserID,
            'Insert',
            'BusinessEntity',
            GETDATE(),
            CONCAT('Registered Business Entity added for OrganizerID: ', @OrganizerID, ', Name: ', @Name, ', Contact: ', @Contact, ', Email: ', @Email, ', Address: ', @Address, ', Status: ', @Status),
            NEWID()
        );
        COMMIT TRANSACTION;
 
    PRINT 'Business entity successfully registered.';
END;
GO


EXEC InsertBusinessEntity
    @OrganizerID = 9,
    @Name = 'Organizer A',
    @Contact = '0123456789',
    @Email = 'organizerA@aparena.com',
    @Address = '123 Arena Street',
    @Status = 'Approved';
GO

EXEC InsertBusinessEntity
    @OrganizerID = 10,
    @Name = 'Organizer B',
    @Contact = '0119876543',
    @Email = 'organizerB@aparena.com',
    @Address = '456 Arena Street',
    @Status = 'Pending';
GO

SELECT * FROM BusinessEntity;
-- Allow Tournament Organizers to register their business entity
GRANT EXECUTE ON InsertBusinessEntity TO TournamentOrganizer;


--------------- Procedure: Approve or Reject Business Entity ----------------

CREATE OR ALTER PROCEDURE ApproveOrRejectBusinessEntity
    @BusinessID INT,
    @Status NVARCHAR(20) -- 'Approved' or 'Rejected'
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Validate the input status
        IF @Status NOT IN ('Approved', 'Rejected')
        BEGIN
            THROW 50001, 'Error: Invalid status. Use ''Approved'' or ''Rejected''.', 1;
        END

        -- Check if the BusinessID exists
        IF NOT EXISTS (
            SELECT 1
            FROM BusinessEntity
            WHERE BusinessID = @BusinessID
        )
        BEGIN
            THROW 50002, 'Error: Business entity not found.', 1;
        END

        -- Update the status of the business entity
        UPDATE BusinessEntity
        SET Status = @Status
        WHERE BusinessID = @BusinessID;

        -- Log the action in AuditLog
        INSERT INTO AuditLog (UserID, Action, TableName, Timestamp, Details, SessionID)
        VALUES (
            NULL, -- Admin or system action
            'Update',
            'BusinessEntity',
            GETDATE(),
            CONCAT('BusinessEntityID: ', @BusinessID, ' status updated to ', @Status),
            NEWID()
        );

        COMMIT TRANSACTION;
        PRINT CONCAT('Business entity status updated to ', @Status, '.');
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT ERROR_MESSAGE();
    END CATCH
END;
GO
SELECT * FROM BusinessEntity

GRANT SELECT ON BusinessEntity TO ComplexManager;


EXEC ApproveOrRejectBusinessEntity
    @BusinessID = 2,
    @Status = 'Approved';

GRANT EXECUTE ON ApproveOrRejectBusinessEntity TO ComplexManager;

SELECT * FROM BusinessEntity WHERE BusinessID = 2;

-- Can insert and update BusinessEntity data but cannot view sensitive fields
DENY SELECT ON BusinessEntity(Contact, Email) TO DataAdmin;
GRANT INSERT, UPDATE ON BusinessEntity TO DataAdmin;

-- Can view and update all data, including unmasked fields.
GRANT SELECT, UPDATE ON BusinessEntity TO ComplexManager;
GRANT UNMASK TO ComplexManager;

-- Can view their own BusinessEntity records but cannot modify them.
GRANT SELECT ON BusinessEntity TO TournamentOrganizer;
DENY UPDATE ON BusinessEntity TO TournamentOrganizer;


------- Procedure: Book Facility for Individual Customer ----------
CREATE OR ALTER PROCEDURE BookFacilityForIndividual
    @UserID INT,
    @FacilityID INT,
    @BookingDate DATE,
    @StartTime TIME,
    @EndTime TIME,
    @ParticipantName NVARCHAR(50),
    @ParticipantEmail NVARCHAR(100),
    @ParticipantPhone NVARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Check for overlapping bookings
        IF EXISTS (
            SELECT 1 
            FROM Booking
            WHERE FacilityID = @FacilityID 
              AND BookingDate = @BookingDate
              AND ((@StartTime BETWEEN StartTime AND EndTime) OR (@EndTime BETWEEN StartTime AND EndTime))
			  AND Status NOT IN ('Canceled', 'Deleted')
              AND IsDeleted = 0
        )
        BEGIN
            THROW 50001, 'Error: Facility is already booked for the specified time.', 1;
        END

        -- Insert booking
        INSERT INTO Booking (UserID, FacilityID, BookingDate, StartTime, EndTime, Status, CreatedAt)
        VALUES (@UserID, @FacilityID, @BookingDate, @StartTime, @EndTime, 'Pending', GETDATE());

        DECLARE @BookingID INT = SCOPE_IDENTITY();

        -- Add participant details
        INSERT INTO Participant (BookingID, Name, Email, PhoneNumber)
        VALUES (@BookingID, @ParticipantName, @ParticipantEmail, @ParticipantPhone);

        -- Log action
        INSERT INTO AuditLog (UserID, Action, TableName, Timestamp, Details, SessionID)
        VALUES (@UserID, 'Insert', 'Booking', GETDATE(), CONCAT('Booking created for FacilityID: ', @FacilityID, ', Date: ', @BookingDate, 
                   ', Time: ', @StartTime, ' - ', @EndTime, ', Participant: ', @ParticipantName), NEWID());

        COMMIT TRANSACTION;
        PRINT 'Booking successful!';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT ERROR_MESSAGE();
    END CATCH
END;
GO

-- Grant Execute Permissions
GRANT EXECUTE ON BookFacilityForIndividual TO IndividualCustomer;

select* from Booking
EXEC BookFacilityForIndividual
    @UserID = 9,
    @FacilityID = 7,
    @BookingDate = '2025-02-23',
    @StartTime = '12:00',
    @EndTime = '14:00',
    @ParticipantName = 'xiaoxinjie',
    @ParticipantEmail = 'xiaoxinjie@aparena.com',
    @ParticipantPhone = '0123456789';


----------  Procedure: Book Facility for Tournament -----------------
CREATE OR ALTER PROCEDURE BookFacilityForTournament
    @OrganizerID INT,
    @FacilityIDs NVARCHAR(MAX), -- Comma-separated list of FacilityIDs
    @BookingDate DATE,
    @StartTime TIME,
    @EndTime TIME,
    @EventName NVARCHAR(100),
    @ParticipantDetails NVARCHAR(MAX) -- JSON string containing participant details
AS
BEGIN
    SET NOCOUNT ON;

    -- Start Transaction
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Validate if the organizer is approved
        IF NOT EXISTS (
            SELECT 1 
            FROM BusinessEntity 
            WHERE OrganizerID = @OrganizerID AND Status = 'Approved'
        )
        BEGIN
            THROW 50001, 'Error: Your business entity is not approved.', 1;
        END

        -- Parse FacilityIDs into a table
        DECLARE @FacilityIDTable TABLE (FacilityID INT);
        INSERT INTO @FacilityIDTable (FacilityID)
        SELECT TRY_CAST(value AS INT) FROM STRING_SPLIT(@FacilityIDs, ',')
        WHERE ISNUMERIC(value) = 1;

        -- Validate facility availability and overlapping schedules
        IF EXISTS (
            SELECT 1
            FROM Facility f
            JOIN @FacilityIDTable ft ON f.FacilityID = ft.FacilityID
            WHERE f.Availability = 0 OR f.IsDeleted = 1
              OR EXISTS (
                  SELECT 1
                  FROM FacilitySchedule fs
                  WHERE fs.FacilityID = f.FacilityID
                    AND fs.Date = @BookingDate
                    AND NOT (@StartTime >= fs.EndTime OR @EndTime <= fs.StartTime)
              )
        )
        BEGIN
            THROW 50002, 'Error: One or more facilities are not available or have overlapping schedules.', 1;
        END

        -- Insert tournament details into the Tournament table
        DECLARE @TournamentID INT;
        INSERT INTO Tournament (OrganizerID, Name, StartDate, EndDate, Status, CreatedAt)
        VALUES (@OrganizerID, @EventName, @BookingDate, @BookingDate, 'Scheduled', GETDATE());

        SET @TournamentID = SCOPE_IDENTITY();

        -- Create bookings for each facility and link them to the tournament
        DECLARE @BookingID INT;
        INSERT INTO Booking (UserID, FacilityID, BookingDate, StartTime, EndTime, Status, TournamentID)
        SELECT @OrganizerID, FacilityID, @BookingDate, @StartTime, @EndTime, 'Pending', @TournamentID
        FROM @FacilityIDTable;

        -- Parse ParticipantDetails JSON and insert participants
        IF @ParticipantDetails IS NOT NULL AND LEN(@ParticipantDetails) > 0
        BEGIN
            INSERT INTO Participant (BookingID, Name, Email, PhoneNumber)
            SELECT b.BookingID, p.[Name], p.[Email], p.[Phone]
            FROM OPENJSON(@ParticipantDetails)
            WITH (
                [Name] NVARCHAR(50) '$.Name',
                [Email] NVARCHAR(100) '$.Email',
                [Phone] NVARCHAR(15) '$.Phone'
            ) p
            JOIN Booking b ON b.FacilityID IN (SELECT FacilityID FROM @FacilityIDTable)
            WHERE b.TournamentID = @TournamentID;
        END

        -- Log the action
        INSERT INTO AuditLog (UserID, Action, TableName, Timestamp, Details, SessionID)
        VALUES (
            @OrganizerID, 
            'Insert', 
            'Tournament/Booking', 
            GETDATE(), 
            CONCAT('Tournament created with ID: ', @TournamentID, ' and facilities booked.'), 
            NEWID()
        );

        COMMIT TRANSACTION;
        PRINT 'Tournament booking successful. Pending approval.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT ERROR_MESSAGE();
    END CATCH
END;
GO


--UpdateTournamentOrganizer
CREATE OR ALTER PROCEDURE UpdateTournamentOrganizerDetails
    @NewPhoneNumber NVARCHAR(15),
    @NewEmail NVARCHAR(100)
AS
BEGIN
    -- Enable error handling
    BEGIN TRY
        -- Update the PhoneNumber and Email for the currently logged-in Tournament Organizer
        UPDATE dbo.Users
        SET
            PhoneNumber = @NewPhoneNumber,
            Email = @NewEmail
        WHERE
            Username = USER_NAME()
            AND UserType = 'Tournament Organizer'; -- Ensure the user is a Tournament Organizer
 
        -- Check if any rows were updated
        IF @@ROWCOUNT = 0
        BEGIN
            THROW 50001, 'No rows were updated. Ensure you are a Tournament Organizer and have permission to update your details.', 1;
        END
 
        PRINT 'Tournament Organizer details updated successfully.';
    END TRY
    BEGIN CATCH
        -- Handle errors
        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO
 
-- Grant execute permission to Tournament Organizer role
GRANT EXECUTE ON OBJECT::UpdateTournamentOrganizerDetails TO [TournamentOrganizer];
GO
 
--UpdateIndividualCustomerDetails
CREATE OR ALTER PROCEDURE UpdateIndividualCustomerDetails
    @NewPhoneNumber NVARCHAR(15),
    @NewEmail NVARCHAR(100)
AS
BEGIN
    -- Enable error handling
    BEGIN TRY
        -- Update the PhoneNumber and Email for the currently logged-in Individual Customer
        UPDATE dbo.Users
        SET
            PhoneNumber = @NewPhoneNumber,
            Email = @NewEmail
        WHERE
            Username = USER_NAME()
            AND UserType = 'Individual Customer'; -- Ensure the user is an Individual Customer
 
        -- Check if any rows were updated
        IF @@ROWCOUNT = 0
        BEGIN
            THROW 50001, 'No rows were updated. Ensure you are an Individual Customer and have permission to update your details.', 1;
        END
 
        PRINT 'Individual Customer details updated successfully.';
    END TRY
    BEGIN CATCH
        -- Handle errors
        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO
 
-- Grant execute permission to Individual Customer role
GRANT EXECUTE ON OBJECT::UpdateIndividualCustomerDetails TO [IndividualCustomer];
GO

GRANT EXECUTE ON BookFacilityForTournament TO TournamentOrganizer;


GRANT UNMASK TO ComplexManager; -- Allows Complex Manager to view unmasked data
DENY UNMASK TO DataAdmin; -- Ensures Data Admin cannot access sensitive data
DENY UNMASK TO IndividualCustomer; -- Ensures Individual Customers cannot unmask data

select * from BusinessEntity

select * from Facility

EXEC BookFacilityForTournament
    @OrganizerID = 9,
    @FacilityIDs = '6,7,8',
    @BookingDate = '2025-02-01',
    @StartTime = '09:00',
    @EndTime = '17:00',
    @EventName = 'Regional Championship',
    @ParticipantDetails = '[{"Name": "yh", "Email": "yh@aparena.com", "Phone": "1234567890"}]';

	

SELECT * FROM Booking
--------------Procedure: Individual Booking Approval--------------
CREATE OR ALTER PROCEDURE ApproveOrRejectBooking
    @BookingID INT,
    @Status NVARCHAR(20) -- 'Approved' or 'Rejected'
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Validate status
        IF @Status NOT IN ('Approved', 'Rejected')
        BEGIN
            THROW 50002, 'Error: Invalid status. Use Approved or Rejected.', 1;
        END

        -- Check if the booking exists and is in 'Pending' status
        IF NOT EXISTS (
            SELECT 1 FROM Booking WHERE BookingID = @BookingID AND Status = 'Pending'
        )
        BEGIN
            THROW 50003, 'Error: Booking not found or already processed.', 1;
        END

        -- Update the booking status
        UPDATE Booking
        SET Status = @Status, UpdatedAt = GETDATE()
        WHERE BookingID = @BookingID;

        -- If the booking is approved, decrement the facility's availability
        IF @Status = 'Approved'
        BEGIN
            DECLARE @FacilityID INT;

            -- Get the FacilityID associated with the booking
            SELECT @FacilityID = FacilityID FROM Booking WHERE BookingID = @BookingID;

            -- Decrement the availability of the facility
            UPDATE Facility
            SET Availability = Availability - 1
            WHERE FacilityID = @FacilityID AND Availability > 0; -- Ensure availability does not go below 0

            -- Log the action
            INSERT INTO AuditLog (UserID, Action, TableName, Timestamp, Details, SessionID)
            VALUES (
                (SELECT UserID FROM Booking WHERE BookingID = @BookingID),
                'Update',
                'Facility',
                GETDATE(),
                CONCAT('FacilityID: ', @FacilityID, ' availability decremented.'),
                NEWID()
            );
        END

        -- Log the action for booking approval/rejection
        INSERT INTO AuditLog (UserID, Action, TableName, Timestamp, Details, SessionID)
        VALUES (
            (SELECT UserID FROM Booking WHERE BookingID = @BookingID),
            'Update',
            'Booking',
            GETDATE(),
            CONCAT('BookingID: ', @BookingID, ' updated to ', @Status),
            NEWID()
        );

        COMMIT TRANSACTION;
        PRINT CONCAT('Booking status updated to ', @Status, '.');
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT ERROR_MESSAGE();
    END CATCH
END;
GO






select * from  BookingHistory

GRANT SELECT ON Booking TO ComplexManager;

-- Grant Execute Permissions
GRANT EXECUTE ON ApproveOrRejectBooking TO ComplexManager;

EXEC ApproveOrRejectBooking
    @BookingID = 2,
    @Status = 'Approved';

SELECT * FROM Booking WHERE BookingID = 2;



-------- Procedure: Tournament Booking Approval ------------
CREATE OR ALTER PROCEDURE ApproveOrRejectTournament
    @TournamentID INT,
    @Status NVARCHAR(20) -- 'Approved' or 'Rejected'
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Validate status
        IF @Status NOT IN ('Approved', 'Rejected')
        BEGIN
            THROW 50004, 'Error: Invalid status. Use Approved or Rejected.', 1;
        END

        -- Check if the tournament exists and is in 'Scheduled' status
        IF NOT EXISTS (
            SELECT 1 FROM Tournament WHERE TournamentID = @TournamentID AND Status = 'Scheduled'
        )
        BEGIN
            THROW 50005, 'Error: Tournament not found or already processed.', 1;
        END

        -- Update the tournament status
        UPDATE Tournament
        SET Status = @Status
        WHERE TournamentID = @TournamentID;

        -- Update the status of all related bookings
        UPDATE Booking
        SET Status = @Status
        WHERE BookingID IN (
            SELECT BookingID FROM Booking WHERE TournamentID = @TournamentID
        );

        -- Log the action
        INSERT INTO AuditLog (UserID, Action, TableName, Timestamp, Details, SessionID)
        VALUES (
            NULL, -- Admin or system action
            'Update',
            'Tournament/Booking',
            GETDATE(),
            CONCAT('TournamentID: ', @TournamentID, ' and related bookings updated to ', @Status),
            NEWID()
        );

        COMMIT TRANSACTION;
        PRINT CONCAT('Tournament and related bookings updated to ', @Status, '.');
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT ERROR_MESSAGE();
    END CATCH
END;
GO

GRANT SELECT ON Tournament TO ComplexManager;

GRANT EXECUTE ON ApproveOrRejectTournament TO ComplexManager;

EXEC ApproveOrRejectTournament
    @TournamentID = 1,
    @Status = 'Approved';

	SELECT * FROM Booking
-------- Procedure: Payment Proceed ---------
CREATE OR ALTER PROCEDURE ProcessPayment
    @BookingID INT,
    @Amount DECIMAL(10, 2),
    @PaymentMethod NVARCHAR(50),
    @CardDetails NVARCHAR(50) = NULL -- Optional for non-card payments
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Validate booking status
        IF NOT EXISTS (
            SELECT 1 FROM Booking WHERE BookingID = @BookingID AND Status = 'Approved'
        )
        BEGIN
            THROW 60001, 'Error: Booking not found or not approved for payment.', 1;
        END

        -- Prevent duplicate payments for the same booking
        IF EXISTS (
            SELECT 1 FROM Payment WHERE BookingID = @BookingID AND Status = 'Completed'
        )
        BEGIN
            THROW 60002, 'Error: Payment already completed for this booking.', 1;
        END

		-- Validate payment amount matches the facility rate
        IF @Amount <> (
            SELECT f.Rate 
            FROM Booking b
            JOIN Facility f ON b.FacilityID = f.FacilityID
            WHERE b.BookingID = @BookingID
        )
		BEGIN
			THROW 60004, 'Error: Payment amount mismatch.', 1;
		END


        -- Encrypt card details if provided
        DECLARE @EncryptedCardDetails VARBINARY(MAX) = NULL;
        DECLARE @MaskedCardDetails NVARCHAR(20) = NULL;

        IF @CardDetails IS NOT NULL
        BEGIN
            OPEN SYMMETRIC KEY DataKey DECRYPTION BY CERTIFICATE ApArenaCert;
            SET @EncryptedCardDetails = ENCRYPTBYKEY(KEY_GUID('DataKey'), @CardDetails);
            SET @MaskedCardDetails = CONCAT('**** **** **** ', RIGHT(@CardDetails, 4));
            CLOSE SYMMETRIC KEY DataKey;
        END

        -- Insert payment record
        INSERT INTO Payment (BookingID, Amount, PaymentMethod, EncryptedCardDetails, MaskedCardDetails, Status)
        VALUES (@BookingID, @Amount, @PaymentMethod, @EncryptedCardDetails, @MaskedCardDetails, 'Completed');

        -- Log the payment action
        INSERT INTO AuditLog (UserID, Action, TableName, Timestamp, Details, SessionID)
        VALUES (
            (SELECT UserID FROM Booking WHERE BookingID = @BookingID),
            'Insert',
            'Payment',
            GETDATE(),
            CONCAT('Payment processed: ', @Amount, ' using ', @PaymentMethod),
            NEWID()
        );

        COMMIT TRANSACTION;
        PRINT 'Payment processed successfully.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT ERROR_MESSAGE();
    END CATCH
END;
GO

GRANT EXECUTE ON ProcessPayment TO ComplexManager;

select * from Facility
SELECT name 
FROM sys.symmetric_keys;

SELECT name 
FROM sys.certificates;


GRANT CONTROL ON SYMMETRIC KEY::DataKey TO [ComplexManager];
GRANT CONTROL ON CERTIFICATE::ApArenaCert TO [ComplexManager];


select * from Payment

EXEC ProcessPayment
    @BookingID = 8,
    @Amount = 150.00,
    @PaymentMethod = 'Credit Card',
    @CardDetails = '1234567890123456';

	SELECT * FROM Booking, Facility
	SELECT * FROM Payment

-------- Procedure: Payment Refund ------------
CREATE OR ALTER PROCEDURE RefundPayment
    @PaymentID INT,
    @RefundReason NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Validate payment
        IF NOT EXISTS (
            SELECT 1 FROM Payment WHERE PaymentID = @PaymentID AND Status = 'Completed'
        )
        BEGIN
            THROW 60003, 'Error: Payment not found or already refunded.', 1;
        END

        -- Update payment status
        UPDATE Payment
        SET Status = 'Refunded'
        WHERE PaymentID = @PaymentID;

        -- Log refund action
        INSERT INTO AuditLog (UserID, Action, TableName, Timestamp, Details, SessionID)
        VALUES (
            NULL, -- System or admin action
            'Update',
            'Payment',
            GETDATE(),
            CONCAT('PaymentID: ', @PaymentID, ' refunded. Reason: ', @RefundReason),
            NEWID()
        );

        COMMIT TRANSACTION;
        PRINT 'Payment refunded successfully.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT ERROR_MESSAGE();
    END CATCH
END;
GO

SELECT *
FROM AuditLog


GRANT EXECUTE ON RefundPayment TO ComplexManager;

EXEC RefundPayment
    @PaymentID = 1,
    @RefundReason = 'Customer cancellation';

