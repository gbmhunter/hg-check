
function Recurse([string]$path) {

	$fc = new-object -com scripting.filesystemobject
	$folder = $fc.getfolder($path)

	foreach ($i in $folder.subfolders) {
		$a = hg id $i.path
		#$a
		#$a -match [regex]::Escape("`+")
		if($a -match [regex]::Escape("`+"))
		{
			$i.path + " has uncommited changes"
		}
	}
  
	foreach ($i in $folder.subfolders) {
		cd $i.path
		$a = hg outgoing -v
		#"Text is " + $a
		#$a -match [regex]::Escape("`+")
		if($a -match [regex]::Escape("no changes found"))
		{
			# Do nothing
		}
		else
		{
			$i.path + " has unpushed commits."
		}
		cd ..
	}
}

"Checking for uncommitted/unpushed repo changes in 3s"
Start-Sleep -s 3
Recurse("C:")