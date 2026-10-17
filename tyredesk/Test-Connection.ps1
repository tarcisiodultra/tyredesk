[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Server,
    [string]$DirectAddress,
    [ValidateRange(1, 65535)][int]$DirectPort = 21118
)
$ErrorActionPreference = 'Stop'

function Test-TcpPort([string]$Address, [int]$Port, [string]$Purpose) {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $ok = $false
    try {
        $pending = $tcp.BeginConnect($Address, $Port, $null, $null)
        try {
            if ($pending.AsyncWaitHandle.WaitOne(3000)) {
                $tcp.EndConnect($pending)
                $ok = $tcp.Connected
            }
        } finally { $pending.AsyncWaitHandle.Close() }
    } catch { $ok = $false }
    finally { $tcp.Dispose() }
    [pscustomobject]@{ Address = $Address; Port = $Port; TCP = $ok; Purpose = $Purpose }
}

Test-TcpPort $Server 21115 'Teste NAT do servidor'
Test-TcpPort $Server 21116 'Identificacao e negociacao por ID'
Test-TcpPort $Server 21117 'Retransmissao (fallback)'
if ($DirectAddress) {
    Test-TcpPort $DirectAddress $DirectPort 'Acesso direto por IP (precisa estar habilitado no destino)'
}
Write-Information 'TCP acessivel nao comprova conexao P2P. UDP e NAT devem ser validados em uma sessao real entre duas redes.' -InformationAction Continue
