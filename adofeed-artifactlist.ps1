function GetUrl() {
    param(
        [string]$orgUrl, 
        [hashtable]$header, 
        [string]$AreaId
    )

    # Area ids
    # https://docs.microsoft.com/en-us/azure/devops/extend/develop/work-with-urls?view=azure-devops&tabs=http&viewFallbackFrom=vsts#resource-area-ids-reference
    # Build the URL for calling the org-level Resource Areas REST API for the RM APIs
    $orgResourceAreasUrl = [string]::Format("{0}/_apis/resourceAreas/{1}?api-preview=5.0-preview.1", $orgUrl, $AreaId)

    # Do a GET on this URL (this returns an object with a "locationUrl" field)
    $results = Invoke-RestMethod -Uri $orgResourceAreasUrl -Headers $header

    # The "locationUrl" field reflects the correct base URL for RM REST API calls
    if ("null" -eq $results) {
        $areaUrl = $orgUrl
    }
    else {
        $areaUrl = $results.locationUrl
    }

    return $areaUrl
}

$orgUrl = "https://dev.azure.com/myorg"
$personalToken = "mytoken"

Write-Host "Initialize authentication context" -ForegroundColor Yellow
$token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($personalToken)"))
$header = @{authorization = "Basic $token"}


# DEMO 1 List of projects
Write-Host "Project List"
#packaging ID refer https://docs.microsoft.com/en-us/azure/devops/extend/develop/work-with-urls?view=azure-devops&tabs=http&viewFallbackFrom=vsts
$coreAreaId = "7ab4e64e-c4d8-4f50-ae73-5ef2e21642a5"
$tfsBaseUrl = GetUrl -orgUrl $orgUrl -header $header -AreaId $coreAreaId

# https://docs.microsoft.com/en-us/rest/api/azure/devops/core/projects/list?view=azure-devops-rest-5.1
# project name should be specified for project based feed
#$projectsUrl = "$($tfsBaseUrl)Project/_apis/packaging/Feeds/{FeedName}/packages?api-version=6.0-preview.1"
#$projectsUrl = "$($tfsBaseUrl)/_apis/packaging/Feeds/platform-template/packages?includeAllVersions=True&api-version=6.0-preview.1"
# No project name should be specified for Organization based feed
$projectsUrl = "$($tfsBaseUrl)/_apis/packaging/Feeds/{FeedName}/packages?api-version=6.0-preview.1"
$projects = Invoke-RestMethod -Uri $projectsUrl -Method Get -ContentType "application/json" -Headers $header

$projects.value | ForEach-Object {
    write-output "Package Name:" $_.name  | Out-File "D:\File.txt" -Append
    $projects2Url = "https://feeds.dev.azure.com/pdidev/_apis/packaging/Feeds/{FeedName}/Packages/$($_.id)/versions?api-version=6.0-preview.1"
    $project2s = Invoke-RestMethod -Uri $projects2Url -Method Get -ContentType "application/json" -Headers $header
    $project2s.value | ForEach-Object {
        write-output $_.version `n| Out-File "D:\file.txt" -Append
    }
}
