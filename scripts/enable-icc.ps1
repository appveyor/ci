Try
{ 
	## INSTALL INTEL STACK WITH MPSS
	echo download-MPSS-k1om-lib
	$k1omPath = "$($env:USERPROFILE)\mpss-3.8.1-k1om.tar"
	(New-Object Net.WebClient).DownloadFile('http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/11193/mpss-3.8.1-k1om.tar', $k1omPath)
	echo extract-MPSS-k1om-tar
	7z x $k1omPath -y -ok1om | Out-Null
	echo extract-MPSS-k1om-rpm
	cmd /c 'FOR /R ".\k1om" %I IN (*.rpm) DO 7z x "%I" -ok1om -aou' | Out-Null
	echo extract-MPSS-k1om-cpio
	cmd /c 'FOR /R ".\k1om" %I IN (*.cpio) DO 7z x "%I" -ok1om -aou' | Out-Null
	echo download-IPS
	$ipsPath = "$($env:USERPROFILE)\parallel_studio_xe_2017_update1_composer_edition_for_cpp_setup.exe"
	(New-Object Net.WebClient).DownloadFile('http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/10965/parallel_studio_xe_2017_update1_composer_edition_for_cpp_setup.exe', $ipsPath)
	echo install-IPS
	cmd /c "$ipsPath --silent -a install --eval --eula=accept --output=install-IPS.log"
	echo download-MPSS
	$zipPath = "$($env:USERPROFILE)\mpss-3.8.1-windows.zip"
	(New-Object Net.WebClient).DownloadFile('http://registrationcenter-download.intel.com/akdlm/irc_nas/11193/mpss-3.8.1-windows.zip', $zipPath)
	7z x $zipPath -y -ompss | Out-Null
	echo install-MPSS
	& '.\mpss\mpss-3.8.1\Intel(R) Xeon Phi(TM) coprocessor essentials.exe' /S /v/qn
	# wait 60 seconds
	sleep 60
}
Catch
{
	$Error.Clear()
	echo INSTALL-Catch
}
finally
{
	echo INSTALL-Operator
	refreshenv
}