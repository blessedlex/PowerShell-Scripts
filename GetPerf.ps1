<#

#>

#Processor
#Get-Counter -Counter "\Processor Information(*)\% of Maximum Frequency"
(Get-Counter -Counter "\Processor(*)\% Processor Time").countersamples
(Get-Counter -Counter "\system\Processor Queue Length").countersamples
$TopCpuProc=Get-WmiObject Win32_PerfRawData_PerfProc_Process -filter "Name <> '_Total' AND Name <> 'Idle'" | Sort PercentProcessorTime -descending | Select -first 5 Name,@{n="PercentProcessorTime";e={($_.PercentProcessorTime/100000/100)/60}},IDProcess
#Disk
(Get-Counter -Counter "\LogicalDisk(*)\% Free Space").countersamples
(Get-Counter -Counter "\LogicalDisk(*)\Free Megabytes").countersamples
(Get-Counter -Counter "\LogicalDisk(*)\Current Disk Queue Length").countersamples
(Get-Counter -Counter "\PhysicalDisk(*)\Avg. Disk Sec/Read").countersamples
#Get-Counter -Counter "\logicaldisk(*)\Avg. Disk sec/Read"
#Get-Counter -Counter "\logicaldisk(*)\Avg. Disk sec/Write"
#Memory
(Get-Counter -Counter "\Paging File(_total)\% Usage").countersamples
(Get-Counter -Counter "\Memory\% Committed Bytes In Use").countersamples
(Get-Counter -Counter "\Memory\Available MBytes").countersamples
##(Get-Counter -Counter "\Memory\Pages/sec").countersamples
$TopMemProc = Get-Process | Sort-Object -Descending WS | select -first 5 ProcessName, @{n="WS";e={$_.ws/1mb}}
#IIS
(Get-Counter -Counter "\ASP.NET Applications(*)\Requests/Sec").countersamples
(Get-Counter -Counter "\ASP.NET\Application Restarts").countersamples
(Get-Counter -Counter "\ASP.NET\Request Wait Time").countersamples
(Get-Counter -Counter "\ASP.NET\Requests Queued").countersamples
#(Get-Counter -Counter "\.NET CLR Exceptions(*)\# of Exceps Thrown / sec").countersamples
#(Get-Counter -Counter "\.NET CLR Memory(*)\# Total Committed Bytes").countersamples
(Get-Counter -Counter "\Web Service(*)\Get Requests/sec").countersamples
(Get-Counter -Counter "\Web Service(*)\Post Requests/sec").countersamples
(Get-Counter -Counter "\Web Service(*)\Current Connections").countersamples
#"HTTP Service Request queue"
#Network
#Get-Counter -Counter "\Network Adapter(*)\Output Queue Length" https://technet.microsoft.com/en-us/library/jj574079(v=ws.11).aspx
(Get-Counter -Counter "\Network Interface(*)\Output Queue Length").countersamples
(Get-Counter -Counter "\TCPv4\Segments Retransmitted/sec").countersamples
(Get-Counter -Counter "\Network Interface(*)\Packets Received Discarded").countersamples
(Get-Counter -Counter "\Network Interface(*)\Packets Received Errors").countersamples
(Get-Counter -Counter "\Network Interface(*)\Packets Outbound Discarded").countersamples
(Get-Counter -Counter "\Network Interface(*)\Packets Outbound Errors").countersamples
(Get-Counter -Counter "\WFPv4\Packets Discarded/sec").countersamples
(Get-Counter -Counter "\TCPv4\Connection Failures").countersamples
#Database
(Get-Counter -Counter "\SQLServer:Memory Manager\Memory Grants Pending").countersamples
(Get-Counter -Counter "\SQLServer:SQL Statistics\Batch Requests/sec").countersamples
(Get-Counter -Counter "\SQLServer:SQL Statistics\Complications/sec").countersamples
(Get-Counter -Counter "\SQLServer:SQL Statistics\Recomplications/sec").countersamples
(Get-Counter -Counter "\SQLServer:Buffer Manager\Page Life Expectancy").countersamples

##(Get-Counter -Counter "\Process(*)\Handle Count").countersamples
(Get-Counter -Counter "\Process(*)\Thread Count").countersamples




"\MSMQ Incoming HTTP Traffic\Incoming HTTP Messages"
"\MSMQ Queue(*)\Messages in Queue"
"\MSMQ Outgoing HTTP Traffic\Outgoing HTTP Messages"
"\MSMQ Service\Total messages in all queues"
"\PhysicalDisk(*)\Avg. Disk Sec/Read"
"\Process(*)\Thread Count"