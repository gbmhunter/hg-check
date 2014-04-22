#
# @file 				hg-check.ps1
# @author 			Geoffrey Hunter <gbmhunter@gmail.com> (www.clablab.com)
# @created			2013/12/09
# @last-modified 	2014/04/23
# @brief 			Powershell script for keeping local hg repos in sync with remote copies.
# @details
#	

# Config variable for holding root folders we want to look for repos in
$rootFolderPathA = @()
$rootFolderPathA += "C:\Work\Projects"
$rootFolderPathA += "C:\Work\Resources"

# Scans for Mercurial repos, given a root folder to start from, and a maximum scan depth of sub-folders
# to search in also. Uses recursion.
function ScanForRepos($rootFolderString, $scanDepth, [ref]$repoPathA, [ref]$numberOfRepos)
{
	Write-Host "Root folder = $rootFolderString"
	Write-Host "Scan depth = $scanDepth"
	
	# Check if scan depth is <=0, if so, user doesn't want to scan
	# anything, so return 0
	if($scanDepth -le 0)
	{
		return
	}
	
	$fc = New-Object -com scripting.filesystemobject
	$rootFolderObject = $fc.getfolder($rootFolderString)
	
	# Go up two levels, since this script is in it's own repo which has it's own folder and sub-folder
	#$projectFolder = $scriptFolder.ParentFolder.ParentFolder
	
	# Count the number of repos (used for progress bar)
	foreach ($subFolder in $rootFolderObject.subfolders) {
		
		if(CheckIfFolderIsRepoRoot $subFolder.path -eq $true)
		{
			$repoPathA.Value += $subFolder.path
			$numberOfRepos.Value++
		}
		else
		{
			if($scanDepth -ne 1)
			{
				# Recursively call this function with the sub-folder path
				ScanForRepos $subFolder.path ($scanDepth - 1) $repoPathA $numberOfRepos
			}
		}
		$numFoldersChecked += 1
		Write-Progress -activity "Searching for repos..." -status "Folders Checked = $numFoldersChecked" -percentcomplete $progress;
	}
	
}

# Looks for a repo-ignore.txt file at the specified path. If found,
# writes the lines of the text file (relative paths) to repoToIgnoreA, prefixing every entry
# with the provided $path (so the entire path is now absolute)
function GetRepoIgnore($path, [ref]$repoToIgnoreA)
{
	$repoIgnoreFilePath = $path + "\repo-ignore.txt"
	Write-Host -NoNewLine "Attempting to read '$repoIgnoreFilePath'..."
	$tempRepoToIgnoreA = @()
	try
	{
		$tempRepoToIgnoreA = Get-Content $repoIgnoreFilePath -ea "stop"
		Write-Host "repo-ignore.txt found."
	}
	catch
	{
		Write-Host "repo-ignore.txt not found."	
		return
	}
	
	# Write-Host "Prefixing current path"
	foreach($tempRepoToIgnore in $tempRepoToIgnoreA)
	{
		$repoToIgnoreA.Value += $path + "\" + $tempRepoToIgnore
		# Write-Host "PATH = $path\$tempRepoToIgnore"
	}
	
}

# Checks to see if there are tasks already scheduled.
function IsTasksScheduled
{
	Write-Host "Checking if tasks are in scheduler..."
	
	$stdout = SchTasks /query /tn HgCheckTask1 2>&1
	if($stdout -match 'ERROR: The system cannot find the file specified.')
	{
		return $false
	}
	
	$stdout = SchTasks /query /tn HgCheckTask2 2>&1
	if($stdout -match 'ERROR: The system cannot find the file specified.')
	{
		return $false
	}

	# None of the task queries returned and error, so both tasks
	# must be present, return true.
	return $true
}

# Schedules 2 tasks to run this script at different times during the day
function ScheduleTasks($scriptPath)
{
	$scriptFilePath = $scriptPath + "\hg-check.ps1"

	while($true)
	{
		$time1 = Read-Host 'Enter a time in the morning for the script to run (e.g. 09:00)'
		$userString = [Environment]::UserDomainName + "\" + [Environment]::UserName
		
		# Attempt to create task, diverting error output to stdout so we can see if was successful
		$stdout = Schtasks /create /tn "HgCheckTask1" /ru $userString /sc daily /st $time1 /F /tr "PowerShell -NoLogo -NoExit -NonInteractive -File '$scriptFilePath'" 2>&1
		
		if($stdout -match "ERROR")
		{
			Write-Host "ERROR: Time was not in the correct 24-hour 4-digit format XX:XX (e.g. 09:15)."
		}
		else
		{
			break
		}	
	}
	
	while($true)
	{
		$time2 = Read-Host 'Enter a time in the afternoon for the script to run (e.g. 17:00)'
		$userString = [Environment]::UserDomainName + "\" + [Environment]::UserName
		
		$stdout = Schtasks /create /tn "HgCheckTask2" /ru $userString /sc daily /st $time2 /F /tr "PowerShell -NoLogo -NoExit -NonInteractive -File '$scriptFilePath'" 2>&1
	
		if($stdout -match "ERROR")
		{
			Write-Host "ERROR: Time was not in the correct 24-hour 4-digit format XX:XX (e.g. 09:15)."
		}
		else
		{
			break
		}	
	
	}
	
	Write-Host "Tasks scheduled successfully."
}

function GetScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value;
    if($Invocation.PSScriptRoot)
    {
        return $Invocation.PSScriptRoot;
    }
    Elseif($Invocation.MyCommand.Path)
    {
        return Split-Path $Invocation.MyCommand.Path
    }
    else
    {
        return $Invocation.InvocationName.Substring(0, $Invocation.InvocationName.LastIndexOf("\"));
    }
}

function CheckIfFolderIsRepoRoot([string]$path)
{
	cd $path
	
	# Following command returns the path of the root repo folder, if current path is part of a repo
	# Also, suppress errors
	$a = hg --cwd . root 2>$null
	
	$compareResult = $path.CompareTo($a)
	if($compareResult -eq 0)
	{
		# Repo has been found
		cd ..
		return $true
	}
	else
	{
		# Not a repo folder
		cd ..
		return $false
	}
	
}

# The main function
function Go() {

	# Get the current script directory
	$scriptPath = GetScriptDirectory
	
	$isTaksScheduled = IsTasksScheduled
	
	# Check whether tasks are scheduled
	if($isTaksScheduled -eq $false)
	{
		Write-Host "Tasks not found in scheduler."
		# Tasks are not present in scheduler
		ScheduleTasks($scriptPath)
	}
	else
	{
		Write-Host "Tasks found in scheduler."
		$timeout = new-timespan -Seconds 3
		$sw = [diagnostics.stopwatch]::StartNew()
		# Tasks are present in scheduler
		"Press s in the next 3 seconds to re-configure scheduler tasks..."
		while ($sw.elapsed -lt $timeout){
			if ($Host.UI.RawUI.KeyAvailable -and ("s" -eq $Host.UI.RawUI.ReadKey("IncludeKeyUp,NoEcho").Character))
			{
				Write-Host "Key press detected, setting up tasks..."
				# Schedule the tasks
				ScheduleTasks($scriptPath)	
				break;
			}	
		}
	}
	
	$fc = New-Object -com scripting.filesystemobject
	$scriptFolder = $fc.getfolder($scriptPath)
	
	# Go up two levels, since this script is in it's own repo which has it's own folder and sub-folder
	$projectFolder = $scriptFolder.ParentFolder.ParentFolder
	
	$progress = 0.0
	Write-Progress -activity "Searching for repos." -status "Folders Checked = 0" -percentcomplete $progress;
	
	# The number of different operations that are performed on the repo
	$numberOfSections = 4
	
	$numberOfRepos = 0
	
	$repoPathA = @()
	$repoToIgnoreA = @()
	
	$numFoldersChecked = 0
	
	#============ STATISTICS VARIABLES ==============#
	
	# Keeps track of how many repos where skipped
	$numReposSkipped = 0
	
	# Keeps track of how many repos where pulled
	$numReposPulled = 0	
	
	# Keeps track of how many repos have uncomitted changes
	$numReposWithUncomittedChanges = 0
	
	# Keeps track of how many repos where merged
	$numReposMerged = 0
	
	# Keeps track of how many repos where updated
	$numReposUpdated = 0
	
	# Keeps track of how many repos where pushed
	$numReposPushed = 0
	
	Write-Host "Scanning for repos..."
	
	foreach ($rootFolderPath in $rootFolderPathA)
	{
		ScanForRepos $rootFolderPath 2 ([ref]$repoPathA) ([ref]$numberOfRepos)
		GetRepoIgnore $rootFolderPath ([ref]$repoToIgnoreA)
	}
	
	<#
	# Count the number of repos (used for progress bar)
	foreach ($subFolder in $projectFolder.subfolders) {
		
		if(CheckIfFolderIsRepoRoot $subFolder.path -eq $true)
		{
			$repoPathA += $subFolder.path
			$numberOfRepos++
		}
		else
		{
			# Check sub-folders
			foreach ($subSubFolder in $subFolder.subfolders) {
				if(CheckIfFolderIsRepoRoot $subSubFolder.path -eq $true)
				{
					$repoPathA += $subSubFolder.path
					$numberOfRepos++
				}
			}
		}
		$numFoldersChecked += 1
		Write-Progress -activity "Searching for repos..." -status "Folders Checked = $numFoldersChecked" -percentcomplete $progress;
	}#>
	

	
	<#
	$repoIgnoreFilePath = $projectFolder.path + "\repo-ignore.txt"
	Write-Host -NoNewLine "Reading $repoIgnoreFilePath..."
	try
	{
		$repoToIgnoreA = Get-Content $repoIgnoreFilePath -ea "stop"
		Write-Host "repo-ignore.txt found."
	}
	catch
	{
		Write-Host "repo-ignore.txt not found."	
	}#>
	
	
	# Calculate the amount of progress that is done per single operation
	$progressPerOperation = (100.0 - $progress) / $numberOfRepos / $numberOfSections

	# Used to build up warning string that will displayed at the end of the function
	# Create some initial space from preceding text
	$warningString = ""
	
	$remoteRepoPathNotFoundWarnings = ""
	
	# Iterate through every found repo
	foreach ($repoPath in $repoPathA) {
	
		$shouldQuit = $false
		$remoteRepoFound = $false
		
		# First check if we should ignore it	
		foreach ($repoToIgnore in $repoToIgnoreA)
		{
			#Write-Host "repoToIgnore = $repoToIgnore"
			#Write-Host "repdoToIgnore = $projectFolder.path + "\" + $repoToIgnore"
				
			# See if this repo path equals any of the paths in 
			# the array which holds paths to repos to ignore
			if($repoPath.Equals($repoToIgnore))
			{
				$shouldQuit = $true;
			}
			
		}
		
		if($shouldQuit -eq $true)
		{
			# We should ignore this repo, so skip to the next one
			$numReposSkipped++
			continue
		}
		
		# Go into the repos directory (useful for when calling hg commands)
		cd $repoPath
	
		$uncommitedChanges = $false	
	
		# Check to see if repos have uncommited changes
		#$a = hg id
		$a = hg status
		if(![string]::IsNullOrEmpty($a))
		{
			$warningString += $repoPath + " has uncommited changes.`r`n"
			$uncommitedChanges = $true
			$numReposWithUncomittedChanges++
		}
		
		$progress = $progress + $progressPerOperation
		$roundedProgress = [Math]::Round($progress, 0)
		Write-Progress -activity "Searching for uncomitted, unpushed, unpulled, and unupdated changes." -status "$roundedProgress% Complete:" -percentcomplete $roundedProgress;			
	
		# Check to see if repos have unpulled commits, 
		# redirect stderr to stdout so we can read it in $a
		$a = hg incoming 2>&1
		if($a -match [regex]::Escape("abort"))
		{
			$remoteRepoPathNotFoundWarnings += "$repoPath has an inaccessible remote repo path (or it is set up incorrectly in .hgrc, it must be under [path] and have the syntax 'default = url-to-remote-repo').`r`n"
		}
		elseif($a -match [regex]::Escape("no changes found"))
		{
			# Do nothing, no changes were found
			$remoteRepoFound = $true
		}
		else
		{
			$remoteRepoFound = $true
			$repoPath + " has unpulled commits, pulling now..."
			hg pull
			$numReposPulled++
		}
		
		$progress = $progress + $progressPerOperation
		$roundedProgress = [Math]::Round($progress, 0)
		Write-Progress -activity "Searching for uncomitted, unpushed, unpulled, and unupdated changes." -status "$roundedProgress% Complete:" -percentcomplete $roundedProgress;	
		
		# Only check for updates/update if there are no uncomitted changes
		if($uncommitedChanges -eq $false)
		{
			# Check to see if repo needs updating
			$currentRev = hg id -i
			$headRev = hg head --template "{node|short}\n"
			
			if($headRev -match [regex]::Escape($currentRev))
			{
				# Do nothing, working directory rev and head revision are the same
			}
			else
			{			
				$repoPath + " has unupdated changes, updating now..."
				# The working directory rev and head revision are different, so update
				hg update
				$numReposUpdated++
			}
			
			# We need to check here whether merge on default branch is required
			# Note that this only lists heads for the default branch
			$hgHeadsResult = hg heads default --template "1"
			if($hgHeadsResult.Length -eq 1)
			{
				
			}
			else
			{
				$repoPath + " needs to be merged, has " + $hgHeadsResult.Length + " heads on default branch! Merging now..."
				hg merge
				if($LastExitCode -eq 0)
				{
					# Perform a simple merge-caused commit after merging
					"Commiting..."
					hg commit -m "Merge."
					$numOfReposMerged++
				}
				else
				{
					"Merge failed!"
				}
			}
		}
		
		$progress = $progress + $progressPerOperation
		$roundedProgress = [Math]::Round($progress, 0)
		Write-Progress -activity "Searching for uncomitted, unpushed, unpulled, and unupdated changes." -status "$roundedProgress% Complete:" -percentcomplete $roundedProgress;
		
		# Finally, check to see if repos have unpushed commits,
		# only if remote repo was found previously when hg incoming was called
		if($remoteRepoFound -eq $true)
		{
		
			$a = hg outgoing -v
			#"Text is " + $a
			if($a -match [regex]::Escape("no changes found"))
			{
				# Do nothing, no changes were found
			}
			else
			{
				$repoPath + " has unpushed commits, pushing now..."
				hg push
				$numReposPushed++
			}
		}
		
		$progress = $progress + $progressPerOperation
		$roundedProgress = [Math]::Round($progress, 0)
		Write-Progress -activity "Searching for uncomitted, unpushed, unpulled, and unupdated changes." -status "$roundedProgress% Complete:" -percentcomplete $roundedProgress;
		
		# Exit the repo directory
		cd ..
		
		# New line to seperate out repo-related output
		#Write-Host ""
	}
	
	# Print statistics
	Write-Host ""
	Write-Host "STATISTICS:"
	Write-Host "Num. repos found:                   $numberOfRepos" 
	Write-Host "Num. repos skipped:                 $numReposSkipped"
	Write-Host "Num. repos pulled:                  $numReposPulled"
	Write-Host "Num. repos with uncomitted changes: $numReposWithUncomittedChanges"
	Write-Host "Num. repos updated:                 $numReposUpdated" 
	Write-Host "Num. repos merged:                  $numReposMerged" 
	Write-Host "Num. repos pushed:                  $numReposPushed"
	
	# Print warnings (if they exist)
	
	if([bool]$warningString -or [bool]$remoteRepoPathNotFoundWarnings)
	{
		Write-Host ""
		Write-Host "WARNINGS:" -foreground "red" -background "black"	
	}
	
	if([bool]$warningString)
	{			
		Write-Host ""
		Write-Host $warningString -foreground "red" -background "black"
	}
	
	if([bool]$remoteRepoPathNotFoundWarnings)
	{
		Write-Host ""
		Write-Host $remoteRepoPathNotFoundWarnings -foreground "red" -background "black"
	}
	
}

# Call main function
Go
""