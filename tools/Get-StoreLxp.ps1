# Lists (and optionally downloads) the offline package files of a Microsoft Store app straight from Microsoft's Store
# delivery service (fe3cr.delivery.mp.microsoft.com) - the same service the Store client uses. No third-party site.
param(
    [Parameter(Mandatory)] [string]$ProductId,
    [string]$OsVersion = '10.0.26100.1',
    [string]$Match = 'LanguageExperiencePack',
    [string]$OutDir
)
$ErrorActionPreference = 'Stop'
$fe3 = 'https://fe3cr.delivery.mp.microsoft.com/ClientWebService/client.asmx'
function Soap([string]$url, [string]$body) {
    $r = Invoke-WebRequest -UseBasicParsing -Uri $url -Method Post -Body ([Text.Encoding]::UTF8.GetBytes($body)) `
        -ContentType 'application/soap+xml; charset=utf-8' -Headers @{ 'User-Agent' = 'Windows-Update-Agent/10.0.10011.16384 Client-Protocol/2.50' }
    [xml]$r.Content
}
$now = [DateTime]::UtcNow
$created = $now.ToString('yyyy-MM-ddTHH:mm:ss.fffZ'); $expires = $now.AddMinutes(5).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
function Header([string]$action, [string]$to) {
@"
<s:Header>
 <a:Action s:mustUnderstand="1">http://www.microsoft.com/SoftwareDistribution/Server/ClientWebService/$action</a:Action>
 <a:MessageID>urn:uuid:$([guid]::NewGuid())</a:MessageID>
 <a:To s:mustUnderstand="1">$to</a:To>
 <o:Security s:mustUnderstand="1" xmlns:o="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
  <Timestamp xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"><Created>$created</Created><Expires>$expires</Expires></Timestamp>
  <wuws:WindowsUpdateTicketsToken wsu:id="ClientMSA" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" xmlns:wuws="http://schemas.microsoft.com/msus/2014/10/WindowsUpdateAuthorization">
   <TicketType Name="MSA" Version="1.0" Policy="MBI_SSL"><User/></TicketType>
  </wuws:WindowsUpdateTicketsToken>
 </o:Security>
</s:Header>
"@
}
$env1 = '<s:Envelope xmlns:a="http://www.w3.org/2005/08/addressing" xmlns:s="http://www.w3.org/2003/05/soap-envelope">'

# 1. WuCategoryId of the product (public Store catalog)
$cat = Invoke-RestMethod "https://displaycatalog.mp.microsoft.com/v7.0/products?bigIds=$ProductId&market=US&languages=en-us,neutral"
$ful = $cat.Products[0].DisplaySkuAvailabilities | % { $_.Sku.Properties.FulfillmentData } | ? { $_ } | Select-Object -First 1
$wuCat = if ($ful -is [string]) { ($ful | ConvertFrom-Json).WuCategoryId } else { $ful.WuCategoryId }
Write-Host "product $ProductId : $($cat.Products[0].LocalizedProperties[0].ProductTitle) | WuCategoryId $wuCat"

# 2. cookie
$x = Soap $fe3 ($env1 + (Header 'GetCookie' $fe3) + @"
<s:Body><GetCookie xmlns="http://www.microsoft.com/SoftwareDistribution/Server/ClientWebService">
<oldCookie></oldCookie><lastChange>2015-10-21T17:01:07.1472913Z</lastChange><currentTime>$created</currentTime><protocolVersion>1.40</protocolVersion>
</GetCookie></s:Body></s:Envelope>
"@)
$cookie = $x.Envelope.Body.GetCookieResponse.GetCookieResult.EncryptedData

# 3. SyncUpdates for the product category, as a Windows client of the given build
$ids = 1,2,3,11,19,544,549,2359974,2359977,5169044,8788830,23110993,23110994,54341900,54343656,59830006,59830007,59830008,60484010,62450018,62450019,62450020,66027979,66053150,97657898,98822896,98959022,98959023,98959024,98959025,98959026,104433538,104900364,105489019,117765322,129905029,130040031,132387090,132393049,133399034,138537048,140377312,143747671,158941041,158941042,158941043,158941044,159123858,159130928,164836897,164847386,164848327,164852241,164852246,164852252,164852253
$idXml = ($ids | % { "<int>$_</int>" }) -join ''
$dev = "E:BranchReadinessLevel=CB&amp;CurrentBranch=ge_release&amp;OEMModel=Virtual Machine&amp;FlightRing=Retail&amp;AttrDataVer=270&amp;InstallLanguage=en-US&amp;OSUILocale=en-US&amp;InstallationType=Client&amp;FlightingBranchName=&amp;OSSkuId=48&amp;App=WU_STORE&amp;ProcessorManufacturer=GenuineIntel&amp;OEMName_Uncleaned=Microsoft Corporation&amp;AppVer=1407.2503.28012.0&amp;OSArchitecture=AMD64&amp;IsFlightingEnabled=0&amp;TelemetryLevel=1&amp;DefaultUserRegion=244&amp;WuClientVer=1310.2503.26012.0&amp;OSVersion=$OsVersion&amp;DeviceFamily=Windows.Desktop"
$x = Soap $fe3 ($env1 + (Header 'SyncUpdates' $fe3) + @"
<s:Body><SyncUpdates xmlns="http://www.microsoft.com/SoftwareDistribution/Server/ClientWebService">
<cookie><Expiration>2045-03-11T02:02:48Z</Expiration><EncryptedData>$cookie</EncryptedData></cookie>
<parameters><ExpressQuery>false</ExpressQuery><InstalledNonLeafUpdateIDs>$idXml</InstalledNonLeafUpdateIDs><OtherCachedUpdateIDs/>
<SkipSoftwareSync>false</SkipSoftwareSync><NeedTwoGroupOutOfScopeUpdates>true</NeedTwoGroupOutOfScopeUpdates>
<FilterAppCategoryIds><CategoryIdentifier><Id>$wuCat</Id></CategoryIdentifier></FilterAppCategoryIds><TreatAppCategoryIdsAsInstalled>true</TreatAppCategoryIdsAsInstalled>
<AlsoPerformRegularSync>false</AlsoPerformRegularSync><ComputerSpec/>
<ExtendedUpdateInfoParameters><XmlUpdateFragmentTypes><XmlUpdateFragmentType>Extended</XmlUpdateFragmentType></XmlUpdateFragmentTypes><Locales><string>en-US</string><string>en</string></Locales></ExtendedUpdateInfoParameters>
<ClientPreferredLanguages><string>en-US</string></ClientPreferredLanguages>
<ProductsParameters><SyncCurrentVersionOnly>false</SyncCurrentVersionOnly><DeviceAttributes>$dev</DeviceAttributes>
<CallerAttributes>E:Interactive=1&amp;IsSeeker=1&amp;Acquisition=1&amp;SheddingAware=1&amp;Id=Acquisition%3BMicrosoft.WindowsStore_8wekyb3d8bbwe&amp;</CallerAttributes><Products/></ProductsParameters>
</parameters></SyncUpdates></s:Body></s:Envelope>
"@)
$res = $x.Envelope.Body.SyncUpdatesResponse.SyncUpdatesResult
# file names come from the extended fragments (by numeric ID), update identities from NewUpdates (same ID)
$names = @{}
foreach ($u in $res.ExtendedUpdateInfo.Updates.Update) {
    $frag = [xml]("<r>" + $u.Xml + "</r>")
    $f = $frag.r.Files.File | ? { $_.FileName -and $_.FileName -notmatch '\.(cab|xml)$' } | Select-Object -First 1
    $pm = $frag.r.ExtendedProperties.PackageIdentityName
    if ($f) { $names[$u.ID] = [pscustomobject]@{ File = $f.FileName; Moniker = $f.InstallerSpecificIdentifier; Size = $f.Size; Digest = $f.Digest } }
}
$found = foreach ($u in $res.NewUpdates.UpdateInfo) {
    $frag = [xml]("<r>" + $u.Xml + "</r>")
    $idn = $frag.r.UpdateIdentity
    if ($names.ContainsKey($u.ID) -and $frag.r.Properties.SecuredFragment -ne $null) {
        [pscustomobject]@{ UpdateID = $idn.UpdateID; Revision = $idn.RevisionNumber; Moniker = $names[$u.ID].Moniker; File = $names[$u.ID].File; Size = $names[$u.ID].Size; Digest = $names[$u.ID].Digest }
    }
}
$found = $found | ? { $_.Moniker -match $Match } | Sort-Object Moniker -Unique
Write-Host "packages offered for OS $OsVersion :"
$found | % { Write-Host ("  {0}  ({1:N1} MB)" -f $_.Moniker, ($_.Size / 1MB)) }

# 4. download URLs (secured endpoint)
foreach ($p in $found) {
    $sec = "$fe3/secured"
    $x = Soap $sec ($env1 + (Header 'GetExtendedUpdateInfo2' $sec) + @"
<s:Body><GetExtendedUpdateInfo2 xmlns="http://www.microsoft.com/SoftwareDistribution/Server/ClientWebService">
<updateIDs><UpdateIdentity><UpdateID>$($p.UpdateID)</UpdateID><RevisionNumber>$($p.Revision)</RevisionNumber></UpdateIdentity></updateIDs>
<infoTypes><XmlUpdateFragmentType>FileUrl</XmlUpdateFragmentType><XmlUpdateFragmentType>FileDecryption</XmlUpdateFragmentType></infoTypes>
<deviceAttributes>$dev</deviceAttributes>
</GetExtendedUpdateInfo2></s:Body></s:Envelope>
"@)
    # pick the location whose FileDigest is the package file (other locations are metadata .cab / blockmap)
    $locs = $x.Envelope.Body.GetExtendedUpdateInfo2Response.GetExtendedUpdateInfo2Result.FileLocations.FileLocation
    $url = $locs | ? { $_.FileDigest -eq $p.Digest -and $_.Url -match '^https?://[^/]*\.delivery\.mp\.microsoft\.com/' } | % Url | Select-Object -First 1
    $p | Add-Member Url $url
    Write-Host "  url host for $($p.Moniker): $(if ($url) { ([uri]$url).Host } else { 'none' })"
    if ($OutDir -and $url) {
        New-Item -ItemType Directory -Force $OutDir | Out-Null
        $ext = if ($p.File -match '\.(\w+)$') { $Matches[1] } else { 'appx' }
        $dest = Join-Path $OutDir "$($p.Moniker).$ext"
        Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $dest
        $sha1 = [Convert]::ToBase64String([Security.Cryptography.SHA1]::Create().ComputeHash([IO.File]::ReadAllBytes($dest)))
        if ($sha1 -ne $p.Digest) { Remove-Item $dest -Force; throw "digest mismatch for $($p.Moniker)" }
        Write-Host "  saved $dest (SHA1 digest matches Microsoft's metadata)"
    }
}
$found
