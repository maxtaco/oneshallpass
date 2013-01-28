@._modules = {}

metastitch_module = (mod, main) ->
  mainmod = @.require(main)
  console.log mainmod
  @._modules[mod] = (exports,require,module) ->
    module.exports = mainmod
  @.require = null

metastitch_finish = () ->
  console.log @._modules
  @require.define @._modules
