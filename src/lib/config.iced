
exports.config =
  derive:
    initial_delay : 500
    sync_initial_delay : 200
    internal_delay : 1
    iters_per_slot : 10
  pw :
    min_size : 8
    max_size : 16
  timeouts :
    cache : 5*60
    document : 2*60
    input : 5*60
  server:
    host : "oneshallpass.com"
    generation : 1
    version : 2
    secbits : 3
    length : 32
    
