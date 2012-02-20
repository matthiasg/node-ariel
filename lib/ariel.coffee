fs = require 'fs'
path = require 'path'
file = require 'file'
CoffeeScript = require 'coffee-script'



module.exports.options = options = excludeDirs: ['.git.*', 'bin.*','test.*','node_modules.*'] 


module.exports.test = () -> true
module.exports.watchDir = (dirPath) ->

  if not path.existsSync dirPath
    console.log "Cannot watch '#{dirPath}'. Directory does not exist."
    return

  console.log "watching dir: #{dirPath}"

  enumerateAllFiles dirPath, options.excludeDirs, (dirPath, file ) ->
    
    compileToJavascript file if isCoffeeScriptFile file 
    return if isCompiledJavascriptFileForMatchingCoffeeScript

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

  javascriptFilePath = convertToJavascriptExtension filePath

  if path.existsSync javascriptFilePath
    return if isNewer javascriptFilePath, filePath

  console.log "compiling #{filePath} -> #{javascriptFilePath}"

  code = fs.readFileSync(filePath).toString()
  js = CoffeeScript.compile( code ) #, getCoffeeScriptOptions(filePath) )

  fs.writeFileSync javascriptFilePath, js

isNewer = (a, b) ->
  aStats = fs.statSync a
  bStats = fs.statSync b
  
  return aStats.mtime.getTime() > bStats.mtime.getTime()

getCoffeeScriptOptions = (filePath) ->
  filename: filePath,
  source: filePath
  bare: no

isCoffeeScriptFile = (filePath) -> path.extname(filePath) == '.coffee'
isCompiledJavascriptFileForMatchingCoffeeScript = (filePath) -> return false

convertToJavascriptExtension = (filePath) ->  
  
  dirname = path.dirname(filePath)
  oldExtension = path.extname(filePath)
  nameWithoutExtension = path.basename(filePath, oldExtension )

  path.join(  dirname, nameWithoutExtension  + ".js" )
