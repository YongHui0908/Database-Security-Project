-- Switch to the database
USE ApArenaManagementSystemDB;
GO

select * from Facility






ALTER TABLE Users
ALTER COLUMN Email NVARCHAR(100) MASKED WITH (FUNCTION = 'email()') NOT NULL;

-- Add masking to PhoneNumber column
ALTER TABLE Users
ALTER COLUMN PhoneNumber NVARCHAR(15) MASKED WITH (FUNCTION = 'partial(0, "XXX-XXXX-", 4)') NOT NULL;

INSERT INTO Users (UserType, Username, Password, Email, PhoneNumber)
VALUES 
('Individual Customer', 'INDICUS', CONVERT(VARBINARY(MAX), 'Password123'), 'indi@example.com', '123-456-7890');
('Individual Customer', 'CustomerUser', CONVERT(VARBINARY(MAX), 'Password456'), 'customer@example.com', '987-654-3210');





select * from  Users
-- Create Users table
CREATE TABLE Users (
    UserID INT PRIMARY KEY IDENTITY,
    UserType NVARCHAR(50) NOT NULL, -- Data Admin, Complex Manager, Tournament Organizer, Individual Customer
    Username NVARCHAR(50) UNIQUE NOT NULL,
    Password VARBINARY(MAX) NOT NULL, -- Encrypted binary password
    Email NVARCHAR(100) MASKED WITH (FUNCTION = 'email()') NOT NULL,
    PhoneNumber NVARCHAR(15) MASKED WITH (FUNCTION = 'partial(0,"XXX-XXXX-",4)') NOT NULL,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME,
    IsDeleted BIT DEFAULT 0,
    DeletedAt DATETIME NULL
);
SELECT * FROM Facility;
SELECT * FROM FacilitySchedule;
-- Create ComplexManager table
CREATE TABLE ComplexManager (
    ManagerID INT PRIMARY KEY IDENTITY,
    UserID INT NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    AssignedFacility NVARCHAR(100) NOT NULL, -- E.g., specific courts or areas
    CreatedAt DATETIME DEFAULT GETDATE()
);

-- Create BusinessEntity table
CREATE TABLE BusinessEntity (
    BusinessID INT PRIMARY KEY IDENTITY,
    OrganizerID INT NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    Name NVARCHAR(100) NOT NULL,
    Contact NVARCHAR(15) MASKED WITH (FUNCTION = 'partial(0,"XXX-XXXX-",4)') NOT NULL,
    Email NVARCHAR(100) MASKED WITH (FUNCTION = 'email()') NOT NULL,
    Address NVARCHAR(255),
    Status NVARCHAR(20) DEFAULT 'Pending', -- Pending, Approved, Rejected
    CreatedAt DATETIME DEFAULT GETDATE()
);

-- Create Facility table
CREATE TABLE Facility (
    FacilityID INT PRIMARY KEY IDENTITY,
    FacilityType NVARCHAR(50),
    Availability BIT DEFAULT 1,
    Capacity INT,
    Rate DECIMAL(10, 2),
	CreatedAt DATETIME DEFAULT GETDATE(),
	UpdatedAt DATETIME,
    IsDeleted BIT DEFAULT 0,
    DeletedAt DATETIME NULL
);

-- Create FacilitySchedule table
CREATE TABLE FacilitySchedule (
    ScheduleID INT PRIMARY KEY IDENTITY,
    FacilityID INT NOT NULL FOREIGN KEY REFERENCES Facility(FacilityID),
    Date DATE NOT NULL,
    StartTime TIME NOT NULL,
    EndTime TIME NOT NULL,
    Status NVARCHAR(20) DEFAULT 'Available', -- Available, Booked, Maintenance
	UpdatedAt DATETIME
);

-- Create Booking table
CREATE TABLE Booking (
    BookingID INT PRIMARY KEY IDENTITY,
    UserID INT NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    FacilityID INT NOT NULL FOREIGN KEY REFERENCES Facility(FacilityID),
    BookingDate DATE NOT NULL,
    StartTime TIME NOT NULL,
    EndTime TIME NOT NULL,
    Status NVARCHAR(20) DEFAULT 'Pending',
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME,
    IsDeleted BIT DEFAULT 0,
    DeletedAt DATETIME NULL,
     TournamentID INT FOREIGN KEY REFERENCES Tournament(TournamentID)
);

-- Create Tournament table
CREATE TABLE Tournament (
    TournamentID INT PRIMARY KEY IDENTITY,
    OrganizerID INT NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    Name NVARCHAR(100) NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    Location NVARCHAR(255),
    Status NVARCHAR(20) DEFAULT 'Scheduled', -- Scheduled, Completed, Cancelled
    CreatedAt DATETIME DEFAULT GETDATE()
);

-- Create Participant table
CREATE TABLE Participant (
    ParticipantID INT PRIMARY KEY IDENTITY,
    BookingID INT NOT NULL FOREIGN KEY REFERENCES Booking(BookingID),
    Name NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) MASKED WITH (FUNCTION = 'email()') NOT NULL,
    PhoneNumber NVARCHAR(15) MASKED WITH (FUNCTION = 'default()') NOT NULL
);

-- Create Payment table
CREATE TABLE Payment (
    PaymentID INT PRIMARY KEY IDENTITY,
    BookingID INT NOT NULL FOREIGN KEY REFERENCES Booking(BookingID),
    Amount DECIMAL(10, 2) NOT NULL,
    PaymentMethod NVARCHAR(50) NOT NULL, -- E.g., Credit Card, PayPal
    TransactionDate DATETIME DEFAULT GETDATE(),
    Status NVARCHAR(20) DEFAULT 'Pending', -- Pending, Completed, Failed
    EncryptedCardDetails VARBINARY(MAX) NULL, -- Encrypted card info
    MaskedCardDetails NVARCHAR(20) NULL, -- Masked version (e.g., **** **** **** 1234)
    SessionID UNIQUEIDENTIFIER DEFAULT NEWID() -- Unique identifier for auditing
);

-- Create AuditLog table
CREATE TABLE AuditLog (
    LogID INT PRIMARY KEY IDENTITY,
    UserID INT FOREIGN KEY REFERENCES Users(UserID),
    Action NVARCHAR(100),
    TableName NVARCHAR(50),
    Timestamp DATETIME DEFAULT GETDATE(),
    Details NVARCHAR(MAX),
    SessionID UNIQUEIDENTIFIER DEFAULT NEWID()
);


-- Create UserRoles table for RBAC
CREATE TABLE UserRoles (
    RoleID INT PRIMARY KEY IDENTITY,
    RoleName NVARCHAR(50) UNIQUE NOT NULL,
    Description NVARCHAR(255)
);




CREATE TABLE BookingHistory (
    BookingHistoryID INT IDENTITY PRIMARY KEY, -- Unique identifier for history entries
    BookingID INT NOT NULL,                   -- References the Booking table
    UserID INT NOT NULL,                      -- References the user associated with the booking
    FacilityID INT NOT NULL,                  -- References the facility
    BookingDate DATE NOT NULL,                -- Date of the booking
    StartTime TIME NOT NULL,                  -- Start time of the booking
    EndTime TIME NOT NULL,                    -- End time of the booking
    Status NVARCHAR(20) NOT NULL,             -- Status of the booking (e.g., Pending, Approved, Rejected)
    UpdatedAt DATETIME NOT NULL               -- Timestamp of the update
);



-- Populate UserRoles table
INSERT INTO UserRoles (RoleName, Description)
VALUES ('Data Admin', 'Responsible for managing users and permissions'),
       ('Complex Manager', 'Manages facilities and approvals'),
       ('Tournament Organizer', 'Creates and manages tournaments'),
       ('Individual Customer', 'Books facilities for personal use');

SELECT * FROM Users;

SELECT * FROM ErrorLog;