fs = require 'fs'
path = require 'path'
file = require 'file'
child = require 'child_process'
util = require 'util'
require 'colors'
CoffeeScript = require 'coffee-script'
tty = require 'tty'

module.exports.options = options =
  excludeDirs: ['.git.*', 'bin.*','node_modules.*', 'temp.*', 'tools.*']
  excludeCompileDirs: ['.git.*', 'bin.*','test.*','node_modules.*', 'temp.*', 'tools.*'] 

rootDirPath = ""
filesToCleanup = []
watchedFiles = []
compilationRequests = []
testRequests = []
isRunningTests = no

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

  queueTest()
  
waitForCompilationRequests = ->
  setInterval handleCompileRequests, 50

handleCompileRequests = ->
  
  return if isRunningTests

  if compilationRequests.length > 0
    console.log "Compiling...#{compilationRequests.length}".green
  
  requests = compilationRequests
  compilationRequests = []

  for f in requests
    compileFile f

waitForTestRequests = ->
  setInterval handleTestRequests, 500

handleTestRequests = ->

  return if isRunningTests

  if testRequests.length > 0  
       
    testRequests = []
    
    try
      isRunningTests = yes
      runMocha -> isRunningTests = false
          
    catch error
      console.log "ERROR running test: #{error}".red
    
watchRootFolder = ->
  watchDir rootDirPath, options.excludeDirs

processRootFolder = ->
  processAllFilesInFolder rootDirPath

cleanAllCompiledFilesOnProcessExit = ->
  process.on 'exit', ->
    console.log "Cleaning #{filesToCleanup.length} compiled files."
    fs.unlinkSync filePath for filePath in filesToCleanup

processAllFilesInFolder = (dirPath) ->
  handleAllFiles dirPath, options.excludeDirs
  compileAllFiles dirPath, options.excludeCompileDirs
  
enumerateAllFiles = (rootDirPath, excludeDirs, callbackPerFile) ->

  if not excludeDirs
    throw "ERROR MISSING EXCLUDES"

  file.walkSync rootDirPath, (dirPath, dirs, files) ->

    dirName = path.relative rootDirPath, dirPath
    return if isMatchedByAny dirName, excludeDirs

    fullPaths = (path.join(dirPath,p) for p in files)
    fullPaths.forEach (filePath) -> callbackPerFile dirPath, filePath

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
  
handleAllFiles = (dirPath, excludeDirs) ->
  
  enumerateAllFiles dirPath, excludeDirs, (dirPath, filePath) ->   
    handleDetectedFile filePath     
  
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

    return if isRunningTests
    processAllFilesInFolder rootDirPath, excludeDirs    
    queueTest()
  
watchFile = (filePath) ->
  
  return if not path.existsSync filePath
  return if watchedFiles.indexOf(filePath) >= 0
    
  watchedFiles.push filePath

  #console.log "WATCH #{filePath}"
  fs.watch filePath, (event,filename) ->
    #console.log "CHANGE:#{event}:#{filePath}"

    return if isRunningTests    

    if path.existsSync filePath

      if not isCompiledJavascriptFileForMatchingCoffeeScript(filePath) and not isIgnoredCompileFile(filePath)
        queueFileCompile filePath if isCoffeeScriptFile filePath
    
    queueTest()
  
isIgnoredCompileFile = (filePath)->
  relativePath = path.relative rootDirPath, filePath
  console.log relativePath
  console.log options.excludeCompileDirs
  isMatchedByAny relativePath, options.excludeCompileDirs

runMocha = (cbFinished)->
   
  return if not path.existsSync 'test'

  console.log 'Testing...'.green
  
  try  

    opt = 
      cwd: process.cwd()
      setsid:true
      #customFds: [1,2,3]    
      

    #process.stdin.pause()
    #tty.setRawMode(true);
    mochaPath = path.join( __dirname, '../node_modules/mocha/bin/_mocha' );

    proc = child.spawn process.argv[0], [mochaPath], opt
    proc.stdout.pipe process.stdout
    proc.stderr.pipe process.stdout

    #proc.stdout.on 'data', (data)->process.stdout.write(data)
    #proc.stderr.on 'data', (data)->process.stderr.write(data)

    proc.on 'exit', ->
      console.log()
      console.log "Testing completed.".green
      #tty.setRawMode(false);
      cbFinished()
    
  catch error
    console.log "ERROR starting tests >".red
    console.log error
    cbFinished()

compileToJavascript = (filePath) ->

  javascriptFilePath = changeToJavascriptExtension filePath

  if path.existsSync javascriptFilePath
    return if isNewer javascriptFilePath, filePath
    console.log "re-compiling #{filePath} -> #{javascriptFilePath}"
  else
    console.log "compiling #{filePath} -> #{javascriptFilePath}"

  compileCoffeeScriptFileToJavascriptFile filePath, javascriptFilePath
  cleanupFile javascriptFilePath

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

