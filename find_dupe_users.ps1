#Install-Modile -Name ADEssentials
#Install-Module -Name ImportExcel 

$ArrList = [System.Collections.ArrayList]@()

#Get all ad groups
Get-AdGroup -filter '*' | 
	ForEach-Object{

		#get the groupname and assign to variable
		$groupname = $_.Name
		
		#get the count of objects in the group where the count of members that exist more than once in the group exceeds 1
		$count = (Get-WinADGroupMember -Group $groupname -all | select name, parentgroup, samAccountName, Nesting | Group-Object -Property Name, Nesting | Where-Object -FilterScript {$_.Count -gt 1}).count
		
		#if the count of duplicate users in the group is equal to 0 (no dupes), return to the top of the loop
		if ($count -eq 0){
			return
		}
		#else if there are duplicate users in the group write to the excel sheet and name the sheet the groupname
		else
		{	
			#add the groupname to the array and HTML break to format the email body
			$ArrList.Add($groupname+"<br />")
			
			#get the users who are listed in the group more than once, and send it out to excel file.
			Get-WinADGroupMember -Group $groupname -all | select name, parentgroup, samAccountName, Nesting | Group-Object -Property Name, Nesting | Where-Object -FilterScript {$_.Count -gt 1} | Select-Object -ExpandProperty Group | Export-Excel -Path "C:\Temp\dupe_user.xlsx" -WorksheetName $groupname	
		}
} 

#count groups containing dupes
$countDupe = ($ArrList).count

#Mail Parameters
$ToAddress = '<recipient address here>'
$FromAddress = '<sender address here>'
$SmtpServer = '<mail relay/server address here>'
$SmtpPort = '25'
$Attachments = "C:\Temp\dupe_user.xlsx"
$Date = Get-Date
$EmailSubject = 'SKCLOUD Dupe Users ' + $Date
 
#HTML Body to display in the e-mail the number of users that contain duplicates and the group names
$EmailBody = @"
<table style="width: 75%" style="border-collapse: collapse; border: 1px solid #008080;">
 <tr>
    <td colspan="2" bgcolor="#008080" style="color: #FFFFFF; font-size: large; height: 35px;"> 
        Dupe User Report Script - Weekly Report on $Date  
    </td>
 </tr>
 <tr style="border-bottom-style: solid; border-bottom-width: 1px; padding-bottom: 1px">
    <td style="width: 201px; height: 35px">&nbsp; Groups Containing Duplicates</td>
    <td style="text-align: center; height: 35px; width: 233px;">
    <b>$countDupe</b></td>
 </tr>
</table>
<table style="width: 75%" style="border-collapse: collapse; border: 1px solid #008080;">
 <tr>
    <td colspan="2" bgcolor="#008080" style="color: #FFFFFF; font-size: large; height: 35px;"> 
        List of Groups that contain duplicate users   
    </td>
 </tr>
 <tr style="border-bottom-style: solid; border-bottom-width: 1px; padding-bottom: 1px">
    <td style="text-align: center; height: 35px; width: 233px;">
    <b>$ArrList</b></td>
 </tr>
</table>
"@

#Send the e-mail with the parameters
Send-MailMessage -To $ToAddress -From $FromAddress -Subject $EmailSubject -Body $EmailBody -BodyAsHtml -SmtpServer $SmtpServer -Port $SmtpPort -Attachments $Attachments

#File cleanup
Remove-Item -Path 'C:\Temp\dupe_user.xlsx'