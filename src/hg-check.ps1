#
# @file 				hg-check.ps1
# @author 			Geoffrey Hunter <gbmhunter@gmail.com> (www.cladlab.com)
# @created			2013/12/09
# @last-modified 	2014/03/25
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
	write-progress -activity "Searching for repos." -status "$progress% Complete:" -percentcomplete $progress;
	
	# The number of different operations that are performed on the repo
	$numberOfSections = 3
	
	$numberOfRepos = 0
	
	$repoPathA = @()
	
	# Count the number of repos (used for progress bar)
	foreach ($subFolder in $folder.subfolders) {
		
		if(CheckIfFolderIsRepoRoot $subFolder.path -eq $true)
		{
			$repoPathA += $subFolder.path
			$numberOfRepos++
		}
	}
	
	"Number of repos found = " + $numberOfRepos
	""
	$progress += 10
	
	# Calculate the amount of progress that is done per single operation
	$progressPerOperation = (100.0 - $progress) / $numberOfRepos / $numberOfSections

	foreach ($i in $repoPathA) {
		
		cd $i
	
		# Check to see if repos have uncommited changes
		$a = hg id
		if($a -match [regex]::Escape("`+"))
		{
			$i + " has uncommited changes"
		}
		
		$progress = $progress + $progressPerOperation
		$roundedProgress = [Math]::Round($progress, 0)
		write-progress -activity "Searching for uncomitted changes." -status "$roundedProgress% Complete:" -percentcomplete $roundedProgress;
	
		# Check to see if repos have unpushed commits
		$a = hg outgoing -v
		#"Text is " + $a
		if($a -match [regex]::Escape("no changes found"))
		{
			# Do nothing, no changes were found
		}
		else
		{
			$i + " has unpushed commits."
		}
		
		$progress = $progress + $progressPerOperation
		$roundedProgress = [Math]::Round($progress, 0)
		write-progress -activity "Searching for uncomitted changes." -status "$roundedProgress% Complete:" -percentcomplete $roundedProgress;
	
		# Check to see if repos have unpulled commits
		$a = hg incoming
		#"Text is " + $a
		if($a -match [regex]::Escape("no changes found"))
		{
			# Do nothing, no changes were found
		}
		else
		{
			$i + " has unpulled commits."
		}
		cd ..
		$progress = $progress + $progressPerOperation
		$roundedProgress = [Math]::Round($progress, 0)
		write-progress -activity "Searching for uncomitted changes." -status "$roundedProgress% Complete:" -percentcomplete $roundedProgress;
	}
}

"Checking for uncommitted/unpushed repo changes in 1s"
Start-Sleep -s 1
Go
""