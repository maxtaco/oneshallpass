
exports.config =
  input :
    defaults :
      algo_version : 3
      security_bits : 8
      generation : 1
      length : 12
      num_symbols : 0
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
    algo_version : 3
    security_bits : 7
    length : 32
    num_symbols : 0
    
