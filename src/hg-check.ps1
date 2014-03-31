#
# @file 				hg-check.ps1
# @author 			Geoffrey Hunter <gbmhunter@gmail.com> (www.cladlab.com)
# @created			2013/12/09
# @last-modified 	2014/04/01
# @brief 			Powershell script for keeping local hg repos in sync with remote copies.
# @details
#						See README.rst in root dir for more info.

function GetScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value;
    if($Invocation.PSScriptRoot)
    {
        $Invocation.PSScriptRoot;
    }
    Elseif($Invocation.MyCommand.Path)
    {
        Split-Path $Invocation.MyCommand.Path
    }
    else
    {
        $Invocation.InvocationName.Substring(0,$Invocation.InvocationName.LastIndexOf("\"));
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

function Go() {

	$path = GetScriptDirectory

	$fc = new-object -com scripting.filesystemobject
	$folder = $fc.getfolder($path)
	
	$progress = 0.0
	write-progress -activity "Searching for repos." -status "Folders Checked = 0" -percentcomplete $progress;
	
	# The number of different operations that are performed on the repo
	$numberOfSections = 4
	
	$numberOfRepos = 0
	
	$repoPathA = @()
	
	$numFoldersChecked = 0
	$numOfMergeCommits = 0;
	
	# Count the number of repos (used for progress bar)
	foreach ($subFolder in $folder.subfolders) {
		
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
		write-progress -activity "Searching for repos..." -status "Folders Checked = $numFoldersChecked" -percentcomplete $progress;
	}
	
	"Number of repos found = " + $numberOfRepos
	
	"Reading repo-ignore.txt"
	$repoToIgnoreA = Get-Content .\repo-ignore.txt
	
	# Calculate the amount of progress that is done per single operation
	$progressPerOperation = (100.0 - $progress) / $numberOfRepos / $numberOfSections

	# Used to build up warning string that will displayed at the end of the function
	# Create some initial space from preceding text
	$warningString = "`r`n"
	
	# Iterate through every found repo
	foreach ($i in $repoPathA) {
	
		$shouldQuit = $false
		
		# First check if we should ignore it
		foreach ($repoToIgnore in $repoToIgnoreA)
		{
			if($i.Equals($path + "\" + $repoToIgnore))
			{
				$shouldQuit = $true;
			}
		}
		
		if($shouldQuit -eq $true)
		{
			# We should ignore this repo, so skip to the next one
			"Ignoring " + $i
			continue
		}
		
		# Go into the repos directory (useful for when calling hg commands)
		cd $i
	
		$uncommitedChanges = $false	
	
		# Check to see if repos have uncommited changes
		$a = hg id
		if($a -match [regex]::Escape("`+"))
		{
			$warningString += $i + " has uncommited changes.`r`n"
			$uncommitedChanges = $true
		}
		
		$progress = $progress + $progressPerOperation
		$roundedProgress = [Math]::Round($progress, 0)
		write-progress -activity "Searching for uncomitted, unpushed, unpulled, and unupdated changes." -status "$roundedProgress% Complete:" -percentcomplete $roundedProgress;			
	
		# Check to see if repos have unpulled commits
		$a = hg incoming
		#"Text is " + $a
		if($a -match [regex]::Escape("no changes found"))
		{
			# Do nothing, no changes were found
		}
		else
		{
			$i + " has unpulled commits, pulling now..."
			hg pull
		}
		
		$progress = $progress + $progressPerOperation
		$roundedProgress = [Math]::Round($progress, 0)
		write-progress -activity "Searching for uncomitted, unpushed, unpulled, and unupdated changes." -status "$roundedProgress% Complete:" -percentcomplete $roundedProgress;	
		
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
				$i + " has unupdated changes, updating now..."
				# The working directory rev and head revision are different, so update
				hg update
			}
			
			# We need to check here whether merge on default branch is required
			# Note that this only lists heads for the default branch
			$hgHeadsResult = hg heads default --template "1"
			if($hgHeadsResult.Length -eq 1)
			{
				
			}
			else
			{
				$i + " needs to be merged, has " + $hgHeadsResult.Length + " heads on default branch! Merging now..."
				hg merge
				if($LastExitCode -eq 0)
				{
					# Perform a simple merge-caused commit after merging
					"Commiting..."
					hg commit -m "Merge."
					$numOfMergeCommits++
				}
				else
				{
					"Merge failed!"
				}
			}
		}
		
		$progress = $progress + $progressPerOperation
		$roundedProgress = [Math]::Round($progress, 0)
		write-progress -activity "Searching for uncomitted, unpushed, unpulled, and unupdated changes." -status "$roundedProgress% Complete:" -percentcomplete $roundedProgress;
		
		# Finally, check to see if repos have unpushed commits
		$a = hg outgoing -v
		#"Text is " + $a
		if($a -match [regex]::Escape("no changes found"))
		{
			# Do nothing, no changes were found
		}
		else
		{
			$i + " has unpushed commits, pushing now..."
			hg push
		}
		
		$progress = $progress + $progressPerOperation
		$roundedProgress = [Math]::Round($progress, 0)
		write-progress -activity "Searching for uncomitted, unpushed, unpulled, and unupdated changes." -status "$roundedProgress% Complete:" -percentcomplete $roundedProgress;
		
		cd ..
		
	}
	
	# Print warnings
	write-host $warningString -foreground "red" -background "black"
}

"Checking for uncommitted/unpushed repo changes in 1s"
Start-Sleep -s 1
Go
""