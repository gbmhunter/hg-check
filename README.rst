==============================================================
hg-check
==============================================================

- Author: gbmhunter <gbmhunter@gmail.com> (http://www.cladlab.com)
- Created: 2013/12/09
- Last Modified: 2014/03/31
- Version: v2.2.1.0
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

The PowerShell script is the most up-to-date and bug-free script. Remember that you must run (if you haven't already) `Set-ExecutionLevel Unrestricted` from PowerShell with admin privileges before the PowerShell script can be run.

The PowerShell script will commit for you with the description "Merge", if it performs a simple merge with no conflicts.

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
v2.2.1.0 2014/03/31 PowerShell script now outputs warning messages at the end of program, closes #7. Warning messages are now red, closes #10. Added info to README about running `Set-ExecutionLevel Unrestricted` before PowerShell script can run, closes #9. PowerShell script now checks if merges are needed, and performs them, along with a commit, closes #13.
v2.2.0.0 2014/03/25 PowerShell script now automatically pushes and pulls changes, closes #6. Also checks and runs hg update if needed.
v2.1.1.0 2014/03/25 PowerShell script now checks sub-subfolders for repos if none found in subfolder, closes #5.
v2.1.0.0 2014/03/25 PowerShell script now ignores folders which are not Mercurial repos, closes #4. Script also reports back how many repos where discovered.
v2.0.0.0 2014/03/25 PowerShell program now checks for repos which need pulling, closes #1. Added a progress bar to provide feedback to the user, closes #3. Fixed path finding code, correct path (the script path) is now found no matter how the script is run, closes #2.
v1.0.0.1 2013/12/10 Added info to the README about individual script files.
v1.0.0.0 2013/12/09 Initial commit. Three script files (batch, Powershell, and bash scripts) added to './src/'.
======== ========== ============================================================================================================