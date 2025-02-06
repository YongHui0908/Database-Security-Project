-- Switch to the Database
USE ApArenaManagementSystemDB;

select * from Users
-- Soft Delete Trigger for Users
DROP TRIGGER IF EXISTS trg_SoftDeleteUsers;
GO
CREATE TRIGGER trg_SoftDeleteUsers
ON Users
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Mark users as deleted
        UPDATE Users
        SET IsDeleted = 1, DeletedAt = GETDATE()
        WHERE UserID IN (SELECT UserID FROM DELETED);

        -- Log the soft delete action
        INSERT INTO AuditLog (UserID, Action, TableName, Timestamp, Details, SessionID)
        SELECT 
            UserID,
            'Soft Delete',
            'Users',
            GETDATE(),
            CONCAT('Soft deleted UserID: ', UserID),
            NEWID()
        FROM DELETED;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- Soft Delete Trigger for Booking
DROP TRIGGER IF EXISTS trg_SoftDeleteBooking;
GO
CREATE TRIGGER trg_SoftDeleteBooking
ON Booking
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
 
    BEGIN TRY
        BEGIN TRANSACTION;
 
        -- Mark the booking as deleted (soft delete)
        UPDATE Booking
        SET IsDeleted = 1, DeletedAt = GETDATE()
        WHERE BookingID IN (SELECT BookingID FROM DELETED);
 
        -- Log action if UserID is found;
        BEGIN
            INSERT INTO AuditLog (UserID, Action, TableName, Timestamp, Details, SessionID)
            SELECT 
                Null,
                'Soft Delete',
                'Booking',
                GETDATE(),
                CONCAT('Soft deleted BookingID = ', (SELECT BookingID FROM DELETED)),
                NEWID();
        END;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- Audit Trigger for Booking Table
DROP TRIGGER IF EXISTS trg_LogChanges;
GO
CREATE TRIGGER trg_LogChanges
ON Booking
AFTER INSERT, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @UserID INT;

        -- Retrieve the UserID based on SYSTEM_USER
        SELECT TOP 1 @UserID = UserID
        FROM Users
        WHERE Username = SYSTEM_USER;

        -- Log action if UserID is found
        IF @UserID IS NOT NULL
        BEGIN
            INSERT INTO AuditLog (UserID, Action, TableName, Timestamp, Details, SessionID)
            SELECT 
                @UserID,
                CASE 
                    WHEN EXISTS (SELECT * FROM INSERTED) THEN 'INSERT'
                    ELSE 'DELETE'
                END AS Action,
                'Booking',
                GETDATE(),
                CASE 
                    WHEN EXISTS (SELECT * FROM INSERTED) THEN CONCAT('New booking created: BookingID=', (SELECT BookingID FROM INSERTED))
                    ELSE CONCAT('Booking deleted: BookingID=', (SELECT BookingID FROM DELETED))
                END AS Details,
                NEWID();
        END;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO



-- Trigger for Logging Approval/Rejection of Booking
DROP TRIGGER IF EXISTS trg_AuditBookingApproval;
GO
CREATE TRIGGER trg_AuditBookingApproval
ON Booking
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO AuditLog (UserID, Action, TableName, Timestamp, Details, SessionID)
        SELECT 
            i.UserID,
            CASE 
                WHEN i.Status = 'Approved' THEN 'Approve Booking'
                WHEN i.Status = 'Rejected' THEN 'Reject Booking'
                ELSE NULL
            END AS Action,
            'Booking',
            GETDATE(),
            CONCAT('BookingID: ', i.BookingID, ' Status changed to ', i.Status),
            NEWID()
        FROM inserted i
        INNER JOIN deleted d ON i.BookingID = d.BookingID
        WHERE i.Status IN ('Approved', 'Rejected') AND i.Status <> d.Status;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO


-- Tracks version history for the Booking
DROP TRIGGER IF EXISTS trg_VersionBooking;
GO
CREATE TRIGGER trg_VersionBooking
ON Booking
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Insert versioned records into BookingHistory
        INSERT INTO BookingHistory (BookingID, UserID, FacilityID, BookingDate, StartTime, EndTime, Status, UpdatedAt)
        SELECT 
            BookingID, UserID, FacilityID, BookingDate, StartTime, EndTime, Status, GETDATE()
        FROM inserted;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

select * from AuditLog

-- Cascades soft deletes from Facility to related Booking records
DROP TRIGGER IF EXISTS trg_SoftDeleteFacility;
GO
CREATE TRIGGER trg_SoftDeleteFacility
ON Facility
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Mark facilities as deleted
        UPDATE Facility
        SET IsDeleted = 1, DeletedAt = GETDATE()
        WHERE FacilityID IN (SELECT FacilityID FROM DELETED);

        -- Cascade soft delete to related bookings
        UPDATE Booking
        SET IsDeleted = 1, DeletedAt = GETDATE()
        WHERE FacilityID IN (SELECT FacilityID FROM DELETED);

        -- Log the cascade delete action
        INSERT INTO AuditLog (UserID, Action, TableName, Timestamp, Details, SessionID)
        SELECT 
            NULL,
            'Cascade Soft Delete',
            'Facility/Booking',
            GETDATE(),
            CONCAT('FacilityID: ', FacilityID, ' and related bookings soft deleted.'),
            NEWID()
        FROM DELETED;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO


-- Logs errors during operations for debugging and analysis
-- Add this to the CATCH block of triggers
BEGIN CATCH
    INSERT INTO ErrorLog (UserID, TableName, Action, ErrorMessage, SessionID)
    VALUES (
        @UserID,
        'TableName',
        'Action',
        ERROR_MESSAGE(),
        NEWID()
    );
    ROLLBACK TRANSACTION;
    THROW;
END CATCH;