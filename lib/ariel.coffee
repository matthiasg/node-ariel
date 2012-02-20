fs = require 'fs'
path = require 'path'
file = require 'file'
child = require 'child_process'
CoffeeScript = require 'coffee-script'

module.exports.options = options = excludeDirs: ['.git.*', 'bin.*','test.*','node_modules.*'] 

rootDir = ""

module.exports.test = () -> true
module.exports.watchDir = (dirPath) ->

  if not path.existsSync dirPath
    console.log "Cannot watch '#{dirPath}'. Directory does not exist."
    return

  rootDir = dirPath   

  console.log "watching dir: #{dirPath}"
  compileFilesInDir dirPath, options.excludeDirs, (filePath) ->  
    cleanupFile filePath if isCompiledJavascriptFileForMatchingCoffeeScript filePath
    watchFile filePath 

  watchDir dirPath

cleanupFile = (filePath) ->
  process.on 'exit', -> fs.unlinkSync filePath

compileFilesInDir = (dirPath, excludeDirs, cbCompiledFile) ->
  
  enumerateAllFiles dirPath, excludeDirs, (dirPath, filePath) ->
    compileFile filePath   
    cbCompiledFile(filePath) if cbCompiledFile
  
compileFile = (filePath) ->

  compileToJavascript(filePath) if isCoffeeScriptFile filePath 

  if isJavascriptFile filePath
    return if isCompiledJavascriptFileForMatchingCoffeeScript filePath

watchDir = (dirPath) ->
  fs.watch dirPath, (event,filename) ->
    console.log "detected change in #{dirPath}: #{event}@#{filename}"
    compileFilesInDir dirPath, options.excludeDirs    

watchFile = (filePath) ->
  fs.watch filePath, (event,filename) ->
    console.log "detected change in #{filePath}: #{event}@#{filename}"
    compileFile filePath
  console.log "watching #{filePath}"

runMocha = ->
  proc = child.spawn ['mocha'], customFds: [0,1,2]
  #proc.on('exit', process.exit);
  
enumerateAllFiles = (rootDirPath, excludeDirs, callbackPerFile) ->

  file.walk rootDirPath, (unknown, dirPath, dirs, files) ->

    dirName = path.relative rootDirPath, dirPath
    return if isMatchedByAny dirName, excludeDirs
    
    files.forEach (filePath) -> callbackPerFile dirPath, filePath

isMatchedByAny = (str, matchers) ->

  for m in matchers   
    return true if str.match m
    
  console.log "not skipping #{str}"      
  return false

compileToJavascript = (filePath) ->

  javascriptFilePath = changeToJavascriptExtension filePath

  if path.existsSync javascriptFilePath
    return if isNewer javascriptFilePath, filePath
    console.log "re-compiling #{filePath} -> #{javascriptFilePath}"
  else
    console.log "compiling #{filePath} -> #{javascriptFilePath}"

  compileCoffeeScriptFileToJavascriptFile filePath, javascriptFilePath

compileCoffeeScriptFileToJavascriptFile = (coffeePath, jsPath) ->

  code = fs.readFileSync(coffeePath).toString()
  compiledJs = CoffeeScript.compile code, getCoffeeScriptOptions(coffeePath)
  fs.writeFileSync jsPath, compiledJs

isNewer = (a, b) ->
  aStats = fs.statSync a
  bStats = fs.statSync b
  
  return aStats.mtime.getTime() > bStats.mtime.getTime()

getCoffeeScriptOptions = (filePath) ->
  filename: filePath,
  bare: no

isCoffeeScriptFile = (filePath) -> path.extname(filePath) == '.coffee'
isJavascriptFile = (filePath) -> path.extname(filePath) == '.js'
isCompiledJavascriptFileForMatchingCoffeeScript = (filePath) -> path.existsSync changeToCoffeeScriptExtension filePath 

changeToCoffeeScriptExtension = (filePath) ->  changeExtension(filePath, '.js')
changeToJavascriptExtension = (filePath) ->  changeExtension(filePath, '.js')

changeExtension = (filePath, newExtension) ->  
  
  dirname = path.dirname(filePath)
  oldExtension = path.extname(filePath)
  nameWithoutExtension = path.basename(filePath, oldExtension )

  path.join( dirname, nameWithoutExtension  + newExtension )
