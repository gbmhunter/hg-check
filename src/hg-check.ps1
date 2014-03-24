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

function Go() {

	$path = GetScriptDirectory

	$fc = new-object -com scripting.filesystemobject
	$folder = $fc.getfolder($path)
	
	$progress = 0.0
	write-progress -activity "Searching for uncomitted changes." -status "$progress% Complete:" -percentcomplete $progress;
	
	# The number of different operations that are performed on the repo
	$numberOfSections = 3
	
	$numberOfRepos = 0
	# Count the number of repos (used for progress bar)
	foreach ($i in $folder.subfolders) {
		$numberOfRepos++
	}
	
	# Calculate the amount of progress that is done per single operation
	$progressPerOperation = 100.0 / $numberOfRepos / $numberOfSections

	# Check to see if repos have uncommited changes
	foreach ($i in $folder.subfolders) {
		$a = hg id $i.path
		if($a -match [regex]::Escape("`+"))
		{
			$i.path + " has uncommited changes"
		}
		
		$progress = $progress + $progressPerOperation
		$roundedProgress = [Math]::Round($progress, 0)
		write-progress -activity "Searching for uncomitted changes." -status "$roundedProgress% Complete:" -percentcomplete $roundedProgress;
	}
	
	# Check to see if repos have unpushed commits
	foreach ($i in $folder.subfolders) {
		cd $i.path
		$a = hg outgoing -v
		#"Text is " + $a
		if($a -match [regex]::Escape("no changes found"))
		{
			# Do nothing, no changes were found
		}
		else
		{
			$i.path + " has unpushed commits."
		}
		cd ..
		
		$progress = $progress + $progressPerOperation
		$roundedProgress = [Math]::Round($progress, 0)
		write-progress -activity "Searching for uncomitted changes." -status "$roundedProgress% Complete:" -percentcomplete $roundedProgress;
	}
	
	# Check to see if repos have unpulled commits
	foreach ($i in $folder.subfolders) {
		cd $i.path
		$a = hg incoming
		#"Text is " + $a
		if($a -match [regex]::Escape("no changes found"))
		{
			# Do nothing, no changes were found
		}
		else
		{
			$i.path + " has unpulled commits."
		}
		cd ..
		$progress = $progress + $progressPerOperation
		$roundedProgress = [Math]::Round($progress, 0)
		write-progress -activity "Searching for uncomitted changes." -status "$roundedProgress% Complete:" -percentcomplete $roundedProgress;
	}
}

"Checking for uncommitted/unpushed repo changes in 1s"
""
Start-Sleep -s 1
Go
""