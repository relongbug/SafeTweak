# Material 3 style WPF window for SafeTweak. Dot-sourced by SafeTweak.ps1, uses its functions.
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$script:Xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="SafeTweak" Width="980" Height="720" MinWidth="760" MinHeight="560"
        WindowStartupLocation="CenterScreen" Background="{DynamicResource Surface}"
        FontFamily="Segoe UI Variable Text, Segoe UI" FontSize="14" Foreground="{DynamicResource OnSurface}">
  <Window.Resources>
    <!-- Material 3 baseline palette; Set-Theme swaps these for dark -->
    <SolidColorBrush x:Key="Surface" Color="#FEF7FF"/>
    <SolidColorBrush x:Key="OnSurface" Color="#1D1B20"/>
    <SolidColorBrush x:Key="Primary" Color="#6750A4"/>
    <SolidColorBrush x:Key="OnPrimary" Color="#FFFFFF"/>
    <SolidColorBrush x:Key="SurfaceLow" Color="#F7F2FA"/>
    <SolidColorBrush x:Key="SurfaceHighest" Color="#E6E0E9"/>
    <SolidColorBrush x:Key="OnSurfaceVariant" Color="#49454F"/>
    <SolidColorBrush x:Key="Outline" Color="#79747E"/>

    <Style x:Key="Card" TargetType="Border">
      <Setter Property="Background" Value="{DynamicResource SurfaceLow}"/>
      <Setter Property="CornerRadius" Value="16"/>
      <Setter Property="Padding" Value="20,16"/>
      <Setter Property="Margin" Value="0,0,0,12"/>
    </Style>
    <Style x:Key="CardTitle" TargetType="TextBlock">
      <Setter Property="FontSize" Value="16"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
    </Style>
    <Style x:Key="CardText" TargetType="TextBlock">
      <Setter Property="Foreground" Value="{DynamicResource OnSurfaceVariant}"/>
      <Setter Property="TextWrapping" Value="Wrap"/>
      <Setter Property="Margin" Value="0,4,16,0"/>
    </Style>

    <!-- M3 switch -->
    <Style x:Key="Switch" TargetType="ToggleButton">
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="VerticalAlignment" Value="Center"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ToggleButton">
            <Grid Width="52" Height="32" Background="Transparent">
              <Border x:Name="Track" CornerRadius="16" Background="{DynamicResource SurfaceHighest}" BorderBrush="{DynamicResource Outline}" BorderThickness="2"/>
              <Ellipse x:Name="Thumb" Width="16" Height="16" Fill="{DynamicResource Outline}" HorizontalAlignment="Left" Margin="8,0,0,0"/>
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="Track" Property="Background" Value="{DynamicResource Primary}"/>
                <Setter TargetName="Track" Property="BorderBrush" Value="{DynamicResource Primary}"/>
                <Setter TargetName="Thumb" Property="Fill" Value="{DynamicResource OnPrimary}"/>
                <Setter TargetName="Thumb" Property="Width" Value="24"/>
                <Setter TargetName="Thumb" Property="Height" Value="24"/>
                <Setter TargetName="Thumb" Property="HorizontalAlignment" Value="Right"/>
                <Setter TargetName="Thumb" Property="Margin" Value="0,0,4,0"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter Property="Opacity" Value="0.38"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- M3 filled and outlined buttons -->
    <Style x:Key="Filled" TargetType="Button">
      <Setter Property="Foreground" Value="{DynamicResource OnPrimary}"/>
      <Setter Property="Background" Value="{DynamicResource Primary}"/>
      <Setter Property="BorderBrush" Value="{DynamicResource Primary}"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Height" Value="40"/>
      <Setter Property="Padding" Value="24,0"/>
      <Setter Property="Margin" Value="8,0,0,0"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bg" CornerRadius="20" Background="{TemplateBinding Background}"
                    BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="1" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bg" Property="Opacity" Value="0.88"/></Trigger>
              <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.38"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="Outlined" TargetType="Button" BasedOn="{StaticResource Filled}">
      <Setter Property="Foreground" Value="{DynamicResource Primary}"/>
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="BorderBrush" Value="{DynamicResource Outline}"/>
    </Style>
  </Window.Resources>

  <Grid Margin="24">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>
    <Grid.ColumnDefinitions>
      <ColumnDefinition Width="3*"/>
      <ColumnDefinition Width="2*"/>
    </Grid.ColumnDefinitions>

    <StackPanel Grid.ColumnSpan="2" Margin="4,0,0,20">
      <TextBlock Text="SafeTweak" FontSize="32" FontFamily="Segoe UI Variable Display, Segoe UI"/>
      <TextBlock x:Name="Subtitle" Foreground="{DynamicResource OnSurfaceVariant}" Margin="0,4,0,0"
                 Text="Small, honest, reversible Windows tweaks. Everything is backed up before it changes."/>
    </StackPanel>

    <StackPanel Grid.Column="1" Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,8,0,0">
      <TextBlock Text="Dark theme" VerticalAlignment="Center" Margin="0,0,12,0"/>
      <ToggleButton x:Name="swDark" Style="{StaticResource Switch}"/>
    </StackPanel>

    <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Hidden" Margin="0,0,16,0">
      <StackPanel>
        <Border Style="{StaticResource Card}"><DockPanel>
          <ToggleButton x:Name="swTemp" DockPanel.Dock="Right" Style="{StaticResource Switch}"/>
          <StackPanel><TextBlock Style="{StaticResource CardTitle}" Text="Clean temporary files"/>
            <TextBlock Style="{StaticResource CardText}" Text="Deletes files older than 24 hours from your Temp folder and Windows\Temp. Files in use are skipped. This is the only step that cannot be undone."/></StackPanel>
        </DockPanel></Border>

        <Border Style="{StaticResource Card}"><DockPanel>
          <ToggleButton x:Name="swTelemetry" DockPanel.Dock="Right" Style="{StaticResource Switch}"/>
          <StackPanel><TextBlock Style="{StaticResource CardTitle}" Text="Reduce telemetry"/>
            <TextBlock Style="{StaticResource CardText}" Text="Diagnostic data to the minimum level, advertising ID and tailored experiences off, Connected User Experiences (DiagTrack) service disabled."/></StackPanel>
        </DockPanel></Border>

        <Border Style="{StaticResource Card}"><DockPanel>
          <ToggleButton x:Name="swPower" DockPanel.Dock="Right" Style="{StaticResource Switch}"/>
          <StackPanel><TextBlock Style="{StaticResource CardTitle}" Text="High performance power plan"/>
            <TextBlock Style="{StaticResource CardText}" Text="Switches to the built-in High performance plan. Uses more power; skipped on laptops that do not offer it."/></StackPanel>
        </DockPanel></Border>

        <Border Style="{StaticResource Card}"><DockPanel>
          <ToggleButton x:Name="swVisual" DockPanel.Dock="Right" Style="{StaticResource Switch}"/>
          <StackPanel><TextBlock Style="{StaticResource CardTitle}" Text="Turn off visual effects"/>
            <TextBlock Style="{StaticResource CardText}" Text="Animations, shadows, Aero Peek and fades off; font smoothing stays on. Helps on weak GPUs. Sign out to apply fully."/></StackPanel>
        </DockPanel></Border>

        <Border Style="{StaticResource Card}"><StackPanel>
          <TextBlock Style="{StaticResource CardTitle}" Text="Startup apps"/>
          <TextBlock Style="{StaticResource CardText}" Text="Turn off the apps you do not need at sign-in. Same flag as Task Manager, so you can turn them back on there too."/>
          <StackPanel x:Name="StartupList" Margin="0,12,0,0"/>
        </StackPanel></Border>
      </StackPanel>
    </ScrollViewer>

    <Border Grid.Row="1" Grid.Column="1" Background="{DynamicResource SurfaceHighest}" CornerRadius="16" Padding="16">
      <DockPanel>
        <TextBlock DockPanel.Dock="Top" Style="{StaticResource CardTitle}" Text="Log" Margin="0,0,0,8"/>
        <TextBox x:Name="Log" IsReadOnly="True" BorderThickness="0" Background="Transparent" Foreground="{DynamicResource OnSurface}" TextWrapping="Wrap"
                 FontFamily="Cascadia Mono, Consolas" FontSize="12" VerticalScrollBarVisibility="Hidden"/>
      </DockPanel>
    </Border>

    <DockPanel Grid.Row="2" Grid.ColumnSpan="2" Margin="4,20,0,0" LastChildFill="False">
      <ToggleButton x:Name="swDry" Style="{StaticResource Switch}" DockPanel.Dock="Left"/>
      <TextBlock x:Name="DryLabel" Text="Dry run: only show what would change" VerticalAlignment="Center" Margin="12,0,0,0" DockPanel.Dock="Left"/>
      <Button x:Name="btnApply" Style="{StaticResource Filled}" Content="Apply selected" DockPanel.Dock="Right"/>
      <Button x:Name="btnUndo" Style="{StaticResource Outlined}" Content="Undo everything" DockPanel.Dock="Right"/>
    </DockPanel>
  </Grid>
</Window>
'@

$Palettes = @{
    Light = @{ Surface = '#FEF7FF'; OnSurface = '#1D1B20'; Primary = '#6750A4'; OnPrimary = '#FFFFFF'
               SurfaceLow = '#F7F2FA'; SurfaceHighest = '#E6E0E9'; OnSurfaceVariant = '#49454F'; Outline = '#79747E' }
    Dark  = @{ Surface = '#141218'; OnSurface = '#E6E0E9'; Primary = '#D0BCFF'; OnPrimary = '#381E72'
               SurfaceLow = '#1D1B20'; SurfaceHighest = '#36343B'; OnSurfaceVariant = '#CAC4D0'; Outline = '#938F99' }
}

function Test-SystemDarkTheme {
    (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -ErrorAction SilentlyContinue).AppsUseLightTheme -eq 0
}

function Set-Theme([bool]$Dark) {
    $window = $script:Ui.Window
    $palette = $Palettes[$(if ($Dark) { 'Dark' } else { 'Light' })]
    $converter = New-Object Windows.Media.BrushConverter
    foreach ($key in $palette.Keys) { $window.Resources[$key] = $converter.ConvertFromString($palette[$key]) }
    # Dark title bar too (Windows 10 20H1+ and 11); harmless if the call is not supported.
    $hwnd = (New-Object Windows.Interop.WindowInteropHelper $window).Handle
    if ($hwnd -ne [IntPtr]::Zero) {
        if (-not ('SafeTweak.Dwm' -as [type])) {
            Add-Type -Namespace SafeTweak -Name Dwm -MemberDefinition '[DllImport("dwmapi.dll")] public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int value, int size);'
        }
        $on = [int]$Dark
        [void][SafeTweak.Dwm]::DwmSetWindowAttribute($hwnd, 20, [ref]$on, 4)
    }
}

function Update-StartupList {
    $ui = $script:Ui
    $ui.StartupList.Children.Clear()
    $script:StartupRows = @()
    foreach ($item in @(Get-StartupItems)) {
        $row = New-Object Windows.Controls.DockPanel
        $row.Margin = '0,4,0,4'
        $switch = New-Object Windows.Controls.Primitives.ToggleButton
        $switch.Style = $ui.Window.FindResource('Switch')
        $switch.IsChecked = $item.Enabled
        $switch.IsEnabled = $item.Enabled  # re-enabling is done by Undo or Task Manager
        $switch.ToolTip = $item.Command
        [Windows.Controls.DockPanel]::SetDock($switch, 'Right')
        $label = New-Object Windows.Controls.TextBlock
        $label.Text = $item.Name
        $label.VerticalAlignment = 'Center'
        $label.TextTrimming = 'CharacterEllipsis'
        [void]$row.Children.Add($switch)
        [void]$row.Children.Add($label)
        [void]$ui.StartupList.Children.Add($row)
        $script:StartupRows += [pscustomobject]@{ Item = $item; Switch = $switch }
    }
    if (-not $script:StartupRows) {
        $none = New-Object Windows.Controls.TextBlock
        $none.Text = 'No startup apps found in the Run keys.'
        [void]$ui.StartupList.Children.Add($none)
    }
}

function Invoke-GuiAction([scriptblock]$Action) {
    $ui = $script:Ui
    $script:DryRun = [bool]$ui.swDry.IsChecked
    $ui.btnApply.IsEnabled = $false; $ui.btnUndo.IsEnabled = $false
    try { & $Action } catch { Write-Log "ERROR: $($_.Exception.Message)" }
    finally {
        $ui.btnApply.IsEnabled = $true; $ui.btnUndo.IsEnabled = $true
        Update-StartupList
        Write-Log ''
    }
}

function Show-SafeTweakWindow {
    $window = [Windows.Markup.XamlReader]::Parse($script:Xaml)
    $script:Ui = @{ Window = $window }
    foreach ($n in 'Subtitle', 'StartupList', 'Log', 'swTemp', 'swTelemetry', 'swPower', 'swVisual', 'swDry', 'swDark', 'DryLabel', 'btnApply', 'btnUndo') {
        $script:Ui[$n] = $window.FindName($n)
    }
    $ui = $script:Ui

    # shortcut: work runs on the UI thread and only repaints between log lines; move to a runspace if steps get slow.
    $script:LogSink = {
        param($m)
        $script:Ui.Log.AppendText("$m`r`n")
        $script:Ui.Log.ScrollToEnd()
        $script:Ui.Window.Dispatcher.Invoke([Action] {}, [Windows.Threading.DispatcherPriority]::Background)
    }

    $ui.swDark.IsChecked = Test-SystemDarkTheme
    Set-Theme $ui.swDark.IsChecked
    $window.Add_SourceInitialized({ Set-Theme $script:Ui.swDark.IsChecked })  # the title bar needs a window handle
    $ui.swDark.Add_Click({ Set-Theme $script:Ui.swDark.IsChecked })

    $ui.swDry.IsChecked = $script:DryRun
    if (-not (Test-Admin)) {
        $ui.swDry.IsChecked = $true
        $ui.swDry.IsEnabled = $false
        $ui.DryLabel.Text = 'Dry run only: start as administrator to apply changes'
    }

    $ui.btnApply.Add_Click({
        Invoke-GuiAction {
            $ui = $script:Ui
            $off = @($script:StartupRows | Where-Object { $_.Item.Enabled -and -not $_.Switch.IsChecked } | ForEach-Object { $_.Item })
            $todo = @()
            foreach ($n in 'Temp', 'Telemetry', 'Power', 'Visual') { if ($ui["sw$n"].IsChecked) { $todo += $n } }
            if ($off) { $todo += 'Startup' }
            if (-not $todo) { Write-Log 'Nothing selected.'; return }
            foreach ($n in $todo) { Invoke-Tweak $n $off }
            Write-Log $(if ($script:DryRun) { 'Dry run finished, nothing was changed.' } else { "Done. Backup: $script:BackupFile" })
        }
    })
    $ui.btnUndo.Add_Click({ Invoke-GuiAction { Undo-All } })

    Update-StartupList
    Write-Log "SafeTweak $script:Version. Backup file: $script:BackupFile"
    [void]$window.ShowDialog()
    $script:LogSink = $null
}
