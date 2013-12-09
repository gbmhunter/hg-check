==============================================================
hg-check
==============================================================

- Author: gbmhunter <gbmhunter@gmail.com> (http://www.cladlab.com)
- Created: 2013/12/09
- Last Modified: 2013/12/10
- Version: v1.0.0.1
- Company: CladLabs
- Project: Free Code Libraries	.
- Language: Batch/PowerScript/Bash
- Compiler: n/a
- uC Model: n/a
- Computer Architecture: n/a
- Operating System: n/a
- Documentation Format: n/a
- License: GPLv3

Description
===========

Script files for automatically checking for uncommitted changes and unpushed commits in a folder full of Mercurial repositories (which themselves are in subfolders).

This repo has the following script files, each is an attempt to perform the same action:

- *hg-check.bat:* Batch file, can be run from Windows using *COMMAND.COM* or *cmd.exe* (standard command-line). Note that the PowerShell script is recommended over this script.
- *hg-check.ps1:* PowerShell script, can be run from Windows as long as you have `PowerShell installed<http://www.microsoft.com/powershell>`_. 
- *hg-check.sh:* Bash script, can be run from Linux systems

The PowerShell script is the most up-to-date and bug-free script.

Internal Dependencies
=====================

None.

External Dependencies
=====================

- Mercurial
- Windows COMMAND.COM or cmd.exe (if using batch script)
- Windows PowerShell (if using the PowerShell script)
- Linux Bash Terminal (if using bash script)

Issues
======

See GitHub Issues.

Usage
=====

Run desired script in either Windows or Linux.
	
Changelog
=========

======== ========== ============================================================================================================
Version  Date       Comment
======== ========== ============================================================================================================
v1.0.0.1 2013/12/10 Added info to the README about individual script files.
v1.0.0.0 2013/12/09 Initial commit. Three script files (batch, Powershell, and bash scripts) added to './src/'.
======== ========== ============================================================================================================