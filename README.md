## Database Security - Group Project

This project implements a secure database management system for the AP Arena sports complex. It is designed to meet rigorous security requirements including data integrity, availability, confidentiality, and non-repudiation. The solution leverages role-based access control (RBAC), detailed auditing, and data protection techniques to ensure a robust and secure environment.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [File Structure](#file-structure)
- [Setup Instructions](#setup-instructions)
- [Auditing and Security](#auditing-and-security)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Role-Based Access Control (RBAC):**
  - Supports Data Admin, Complex Manager, Tournament Organizer, and Individual Customer roles.
  - Implements permissions management and user mapping between server logins and database users.
  
- **Secure Database Schema:**
  - Contains tables for users, roles, facilities, bookings, participants, and auditing.
  - Utilizes data masking and encryption for sensitive data.
  - Incorporates system-versioned tables for historical data tracking.

- **Auditing and Logging:**
  - Uses SQL Server auditing features to track server and database actions.
  - Implements triggers to log `INSERT`, `UPDATE`, and `DELETE` operations in real time.
  - Stores audit logs in a designated file path (e.g., `C:\Audits\`).

- **Modular SQL Scripts:**
  - Organized into separate files for schemas, triggers, procedures, and data population.
  - A master script (`MasterScript.sql`) orchestrates the execution order, ensuring all dependencies are met.

- **Automated Backups and Recovery:**
  - Scripts and procedures are provided to automate backup processes with a defined Recovery Point Objective (RPO).

## Prerequisites

- **Microsoft SQL Server:** Ensure that SQL Server is installed and configured.
- **SQL Server Management Studio (SSMS):** Recommended for executing the scripts and managing the database.
- **Git:** To clone and manage the repository.

## File Structure

Database_Security_Project/
├── Auditing.sql

├── Backups.sql

├── CreateFacilities.sql

├── Data_Security.sql

├── Database_Setup.sql

├── Master_Configuration.sql

├── Procedure.sql

├── Schema_Creation.sql

├── Trigger.sql

├── User_and_Role_Setup.sql

├── README.md

## Setup Instructions
1. **Clone the repository:**
   ```bash
   git clone https://github.com/YongHui0908/Database-Security-Project.git
   cd Database-Security-Project

**2. Configure SQL Server:**

Ensure your SQL Server service account has the necessary permissions (e.g., write access to audit directories).

**3. Run the MasterScript.sql:**

Open it in SSMS (with SQLCMD mode if needed) and execute.

**4. Verify and Test:**

Check that all objects, triggers, and data are correctly set up.

## Auditing and Security

**Audit Logs:**

Uses SQL Server auditing to track user and database actions.

**Triggers:**

A trigger (trg_LogChanges) logs any INSERT, UPDATE, or DELETE operations.

**Data Protection:**

Data masking is applied on sensitive columns.

## Contributing
Feel free to fork the repository, submit pull requests, or open issues if you have suggestions or improvements.

## License
This project is licensed under the MIT License.


