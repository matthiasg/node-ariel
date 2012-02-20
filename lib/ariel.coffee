fs = require 'fs'
path = require 'path'
file = require 'file'
child = require 'child_process'
util = require 'util'
require 'colors'
CoffeeScript = require 'coffee-script'

module.exports.options = options = excludeDirs: ['.git.*', 'bin.*','test.*','node_modules.*'] 

rootDirPath = ""
filesToCleanup = []
watchedFiles = []
compilationRequests = []
testRequests = []

module.exports.test = () -> true
module.exports.watchDir = (dirPath) ->

  if not path.existsSync dirPath
    console.log "Cannot watch '#{dirPath}'. Directory does not exist."
    return

  rootDirPath = dirPath   

  console.log "watching dir: #{rootDirPath}"
  
  waitForCompilationRequests()
  waitForTestRequests()
  
  watchRootFolder()
  processRootFolder()

  cleanAllCompiledFilesOnProcessExit()

  runMocha()
  
waitForCompilationRequests = ->
  setInterval handleCompileRequests, 100

handleCompileRequests = ->
  
  if compilationRequests.length > 0
    console.log "Compiling...#{compilationRequests.length}".green
  
  requests = compilationRequests
  compilationRequests = []

  for f in requests
    compileFile f

waitForTestRequests = ->
  setInterval handleTestRequests, 300

handleTestRequests = ->
  if testRequests.length > 0  
    console.log "Testing...".green
    runMocha()
    testRequests = []

watchRootFolder = ->
  watchDir rootDirPath, options.excludeDirs

processRootFolder = ->
  processAllFilesInFolder rootDirPath, options.excludeDirs

cleanAllCompiledFilesOnProcessExit = ->
  process.on 'exit', ->
    console.log "Cleaning #{filesToCleanup.length} compiled files."
    fs.unlinkSync filePath for filePath in filesToCleanup

processAllFilesInFolder = (dirPath, excludeDirs) ->
  enumerateAllFiles dirPath, options.excludeDirs, (dirPath, filePath) -> handleDetectedFile filePath     
  compileAllFiles dirPath, options.excludeDirs
  
enumerateAllFiles = (rootDirPath, excludeDirs, callbackPerFile) ->
  file.walk rootDirPath, (unknown, dirPath, dirs, files) ->

    dirName = path.relative rootDirPath, dirPath
    return if isMatchedByAny dirName, excludeDirs
    
    files.forEach (filePath) -> callbackPerFile dirPath, filePath

isMatchedByAny = (str, matchers) ->

  for m in matchers   
    return true if str.match m
  return false

handleDetectedFile = (filePath) ->
  #console.log "detected #{filePath}"
  cleanupFile filePath if isCompiledJavascriptFileForMatchingCoffeeScript(filePath)
  watchFile filePath 

cleanupFile = (filePath) ->
  if filesToCleanup.indexOf(filePath) < 0
    #console.log "will cleanup #{filePath} later"
    filesToCleanup.push filePath 
  
compileAllFiles = (dirPath, excludeDirs) ->
  
  enumerateAllFiles dirPath, excludeDirs, (dirPath, filePath) ->   
    queueFileCompile filePath if isCoffeeScriptFile filePath
  
compileFile = (filePath) ->
    
  if not isCoffeeScriptFile filePath
    console.log "NOT COFFEE:#{filePath}".red

  compileToJavascript(filePath) if isCoffeeScriptFile filePath

queueTest = ->
  if testRequests.length == 0
    testRequests.push 'test'

queueFileCompile = (filePath) ->
  if compilationRequests.indexOf(filePath) < 0
    compilationRequests.push filePath

watchDir = (dirPath, excludeDirs) ->
  fs.watch dirPath, (event,filename) ->
    console.log 'detected dir change'
    processAllFilesInFolder rootDirPath, excludeDirs    
    queueTest()
  
watchFile = (filePath) ->
  
  return if watchedFiles.indexOf(filePath) >= 0
    
  watchedFiles.push filePath

  #console.log "WATCH #{filePath}"
  fs.watch filePath, (event,filename) ->
    #console.log "CHANGE:#{event}:#{filePath}"
    
    if path.existsSync filePath
      queueFileCompile filePath if not isCompiledJavascriptFileForMatchingCoffeeScript(filePath)
    return if isCoffeeScriptFile filePath
    
    queueTest()
  
runMocha = ->
  console.log 'running tests...'

  #proc = child.spawn ['mocha'], customFds: [0,1,2]
  #proc.on('exit', process.exit);
  
compileToJavascript = (filePath) ->

  javascriptFilePath = changeToJavascriptExtension filePath

  if path.existsSync javascriptFilePath
    return if isNewer javascriptFilePath, filePath
    console.log "re-compiling #{filePath} -> #{javascriptFilePath}"
  else
    console.log "compiling #{filePath} -> #{javascriptFilePath}"

  compileCoffeeScriptFileToJavascriptFile filePath, javascriptFilePath

compileCoffeeScriptFileToJavascriptFile = (coffeePath, jsPath) ->
  
  try
    code = fs.readFileSync(coffeePath).toString()
    compiledJs = CoffeeScript.compile code, getCoffeeScriptOptions(coffeePath)  
    fs.writeFileSync jsPath, compiledJs
  catch error
    console.log "Error compiling #{coffeePath}:".red + error
    fs.unlinkSync jsPath if path.existsSync jsPath
    

  return
  

isNewer = (a, b) ->
  aStats = fs.statSync a
  bStats = fs.statSync b
  
  return aStats.mtime.getTime() > bStats.mtime.getTime()

getCoffeeScriptOptions = (filePath) ->
  filename: filePath,
  bare: no

isCoffeeScriptFile = (filePath) -> path.extname(filePath) == '.coffee'
isJavascriptFile = (filePath) -> path.extname(filePath) == '.js'

isCompiledJavascriptFileForMatchingCoffeeScript = (filePath) ->
  
  return isJavascriptFile(filePath) and 
         path.existsSync(changeToCoffeeScriptExtension(filePath))
  
changeToCoffeeScriptExtension = (filePath) ->  changeExtension(filePath, '.coffee')
changeToJavascriptExtension = (filePath) ->  changeExtension(filePath, '.js')

changeExtension = (filePath, newExtension) ->  
  
  dirname = path.dirname(filePath)
  oldExtension = path.extname(filePath)
  nameWithoutExtension = path.basename(filePath, oldExtension )

  return path.join( dirname, nameWithoutExtension  + newExtension )

