
(Get-Counter -ComputerName $server -Counter "\MSMQ Incoming HTTP Traffic\Incoming HTTP Messages").countersamples
(Get-Counter -Counter "\MSMQ Queue(*)\Messages in Queue").countersamples
get-counter -listset MSMQ* | Select-Object -expandproperty Counter
(Get-Counter -Counter "\MSMQ Incoming HTTP Traffic\Incoming HTTP Messages").countersamples
(Get-Counter -Counter "\MSMQ Service\Total messages in all queues").countersamples