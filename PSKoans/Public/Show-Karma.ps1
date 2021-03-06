function Show-Karma {
    [CmdletBinding(DefaultParameterSetName = 'Default',
        HelpUri = 'https://github.com/vexx32/PSKoans/tree/master/docs/Show-Karma.md')]
    [OutputType([void])]
    [Alias('Invoke-PSKoans', 'Test-Koans', 'Get-Enlightenment', 'Meditate', 'Clear-Path', 'Measure-Karma')]
    param(
        [Parameter(ParameterSetName = 'ListKoans')]
        [Parameter(ParameterSetName = 'ModuleOnly')]
        [Parameter(ParameterSetName = 'IncludeModule')]
        [Parameter(ParameterSetName = 'Default')]
        [Alias('Koan', 'File')]
        [SupportsWildcards()]
        [string[]]
        $Topic,

        [Parameter(Mandatory, ParameterSetName = 'ModuleOnly')]
        [Parameter(ParameterSetName = 'ListKoans')]
        [SupportsWildcards()]
        [string[]]
        $Module,

        [Parameter(Mandatory, ParameterSetName = 'IncludeModule')]
        [SupportsWildcards()]
        [string[]]
        $IncludeModule,

        [Parameter(Mandatory, ParameterSetName = 'ListKoans')]
        [Alias('ListKoans', 'ListTopics')]
        [switch]
        $List,

        [Parameter(Mandatory, ParameterSetName = 'OpenFile')]
        [Alias('Meditate')]
        [switch]
        $Contemplate,

        [Parameter(Mandatory, ParameterSetName = 'OpenFolder')]
        [switch]
        $OpenFolder,

        [Parameter()]
        [Alias()]
        [switch]
        $ClearScreen,

        [Parameter(ParameterSetName = 'ModuleOnly')]
        [Parameter(ParameterSetName = 'IncludeModule')]
        [Parameter(ParameterSetName = 'Default')]
        [Alias()]
        [switch]
        $Detailed
    )

    $GetParams = @{ }
    switch ($PSCmdlet.ParameterSetName) {
        'IncludeModule' { $GetParams['IncludeModule'] = $IncludeModule }
        'ModuleOnly' { $GetParams['Module'] = $Module }
        { $PSBoundParameters.ContainsKey('Topic') } { $GetParams['Topic'] = $Topic }
    }

    switch ($PSCmdlet.ParameterSetName) {
        'ListKoans' {
            Get-PSKoan @GetParams
        }
        'OpenFolder' {
            $KoanLocation = Get-PSKoanLocation
            Write-Verbose "Checking existence of koans folder"
            if (-not (Test-Path $KoanLocation)) {
                Write-Verbose "Koans folder does not exist. Initiating full reset..."
                Update-PSKoan -Confirm:$false
            }

            Write-Verbose "Opening koans folder"
            $Editor = Get-PSKoanSetting -Name Editor
            if ($Editor -and (Get-Command -Name $Editor -ErrorAction SilentlyContinue)) {
                $EditorSplat = @{
                    FilePath     = $Editor
                    ArgumentList = '"{0}"' -f (Resolve-Path $KoanLocation)
                    NoNewWindow  = $true
                }
                Start-Process @EditorSplat
            }
            else {
                $KoanLocation | Invoke-Item
            }
        }
        'OpenFile' {
            try {
                $Results = Get-Karma @GetParams
            }
            catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
            $Editor = Get-PSKoanSetting -Name Editor
            $FilePath = Get-PSKoan -Topic $Results.CurrentTopic.Name -Scope User | Select-Object -ExpandProperty Path
            $LineNumber = $Results.CurrentTopic.FailedLineNumber
            switch ($Editor) {
                { $_ -in 'code', 'code-insiders' } {
                    $FullArgument = '--goto "{0}":{1} --reuse-window' -f $FilePath, $LineNumber
                    Start-Process $Editor -ArgumentList $FullArgument
                }
                atom {
                    $FullArgument = '"{0}":{1}' -f $FilePath, $LineNumber
                    Start-Process $Editor -ArgumentList $FullArgument
                }
                {$_ -in 'powershell_ise', 'isep' } {
                    $FullArgument = "{0}" -f $FilePath
                    Start-Process -FilePath $Editor -ArgumentList $FullArgument
                }
                default {
                    if ($Editor) {
                        $FullArgument = "{0}" -f $FilePath
                        & $Editor $FullArgument
                    }
                    else {
                        Invoke-Item $FilePath
                    }
                }
            }
        }
        default {
            if ($ClearScreen) {
                Clear-Host
            }

            Show-MeditationPrompt -Greeting

            try {
                $Results = Get-Karma @GetParams
            }
            catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }

            if ($Results.Complete) {
                $Params = @{
                    KoansPassed    = $Results.KoansPassed
                    TotalKoans     = $Results.TotalKoans
                    RequestedTopic = $Topic
                    Complete       = $Results.Complete
                }
            }
            else {
                $Params = @{
                    DescribeName   = $Results.Describe
                    ItName         = $Results.It
                    Expectation    = $Results.Expectation
                    Meditation     = $Results.Meditation
                    KoansPassed    = $Results.KoansPassed
                    TotalKoans     = $Results.TotalKoans
                    CurrentTopic   = $Results.CurrentTopic
                    RequestedTopic = $Topic
                }

                if ($Detailed) {
                    $Params.Add('Results', $Results.Results)
                }
            }

            Show-MeditationPrompt @Params
        }
    }
}