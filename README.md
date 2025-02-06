Database Security - Group Project

This project implements a secure database management system for the AP Arena sports complex. It is designed to meet rigorous security requirements including data integrity, availability, confidentiality, and non-repudiation. The solution leverages role-based access control (RBAC), detailed auditing, and data protection techniques to ensure a robust and secure environment.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [File Structure](#file-structure)
- [Setup Instructions](#setup-instructions)
- [Auditing and Security](#auditing-and-security)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

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
