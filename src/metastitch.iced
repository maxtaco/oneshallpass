@._modules = {}

metastitch_module = (mod, main) ->
  mainmod = @.require(main)
  @._modules[mod] = (exports,require,module) ->
    module.exports = mainmod
  @.require = null

metastitch_finish = () ->
  @require.define @._modules
