function Get-KPEntry
{
    <#
        .SYNOPSIS
            This function will lookup and Return KeePass one or more KeePass Entries.
        .DESCRIPTION
            This function will lookup Return KeePass Entry(ies). It supports basic lookup filtering.
        .EXAMPLE
            PS> Get-KPEntryBase -KeePassConnection $DB -UserName "MyUser"

            This Example will return all entries that have the UserName "MyUser"
        .EXAMPLE
            PS> Get-KPEntry -KeePassConnection $DB -KeePassGroup $KpGroup

            This Example will return all entries that are in the specified group.
        .EXAMPLE
            PS> Get-KPEntry -KeePassConnection $DB -UserName "AUserName"

            This Example will return all entries have the UserName "AUserName"
        .PARAMETER KeePassConnection
            This is the Open KeePass Database Connection

            See Get-KeePassConnection to Create the conneciton Object.
        .PARAMETER KeePassGroup
            This is the KeePass Group Object in which to search for entries.
        .PARAMETER Title
            This is a Title of one or more KeePass Entries.
        .PARAMETER UserName
            This is the UserName of one or more KeePass Entries.
        .PARAMETER KeePassUuid
            Specify the KeePass Entry Uuid for reverse lookup.
    #>
    [CmdletBinding(DefaultParameterSetName = 'None')]
    [OutputType('KeePassLib.PwEntry')]
    param
    (
        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'None')]
        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'UUID')]
        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'Group')]
        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'Title')]
        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'UserName')]
        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'Password')]
        [ValidateNotNullOrEmpty()]
        [KeePassLib.PwDatabase] $KeePassConnection,

        [Parameter(Position = 1, Mandatory = $true, ParameterSetName = 'Group')]
        [ValidateNotNullOrEmpty()]
        [KeePassLib.PwGroup[]] $KeePassGroup,

        [Parameter(Position = 1, Mandatory = $true, ParameterSetName = 'UUID', ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('Uuid')]
        [KeePassLib.PwUuid] $KeePassUuid,

        [Parameter(Position = 2, Mandatory = $false, ParameterSetName = 'Group')]
        [Parameter(Position = 1, Mandatory = $true, ParameterSetName = 'Title')]
        [ValidateNotNullOrEmpty()]
        [String] $Title,

        [Parameter(Position = 3, Mandatory = $false, ParameterSetName = 'Group')]
        [Parameter(Position = 2, Mandatory = $false, ParameterSetName = 'Title')]
        [Parameter(Position = 1, Mandatory = $true, ParameterSetName = 'UserName')]
        [ValidateNotNullOrEmpty()]
        [String] $UserName
    )
    begin
    {
        ## Check if database is open.
        if(-not $KeePassConnection.IsOpen)
        {
            Write-Warning -Message '[BEGIN] The KeePass Connection Sepcified is not open or does not exist.'
            Throw 'The KeePass Connection Sepcified is not open or does not exist.'
        }
    }
    process
    {
        ## Get Entries and Filter
        $KeePassItems = $KeePassConnection.RootGroup.GetEntries($true)

        if($PSCmdlet.ParameterSetName -eq 'UUID')
        {
            $KeePassItems  | Where-Object { $KeePassUuid.CompareTo($_.Uuid) -eq 0 }
        }
        else
        {
            ## This a lame way of filtering.
            if ($KeePassGroup)
            {
                $KeePassItems = foreach($_keepassItem in $KeePassItems)
                {
                    if($KeePassGroup.Contains($_keepassItem.ParentGroup))
                    {
                        $_keepassItem
                    }
                }
            }
            if ($Title)
            {
                $KeePassItems = foreach($_keepassItem in $KeePassItems)
                {
                    if($_keepassItem.Strings.ReadSafe('Title').ToLower().Equals($Title.ToLower()))
                    {
                        $_keepassItem
                    }
                }
            }
            if ($UserName)
            {
                $KeePassItems = foreach($_keepassItem in $KeePassItems)
                {
                    if($_keepassItem.Strings.ReadSafe('UserName').ToLower().Equals($UserName.ToLower()))
                    {
                        $_keepassItem
                    }
                }
            }

            ## Return results
            $KeePassItems
        }

    }
}
