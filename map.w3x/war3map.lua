gg_trg_NoFog = nil
function InitGlobals()
end

do; local _, codeLoc = pcall(error, "", 2) --get line number where DebugUtils begins.
    --[[
     --------------------------
     -- | Debug Utils 2.0a | --
     --------------------------
    
     --> https://www.hiveworkshop.com/threads/debug-utils-ingame-console-etc.330758/
    
     - by Eikonium, with special thanks to:
        - @Bribe, for pretty table print, showing that xpcall's message handler executes before the stack unwinds and useful suggestions like name caching and stack trace improvements.
        - @Jampion, for useful suggestions like print caching and applying Debug.try to all code entry points
        - @Luashine, for useful feedback and building "WC3 Debug Console Paste Helper" (https://github.com/Luashine/wc3-debug-console-paste-helper#readme)
        - @HerlySQR, for showing a way to get a stack trace in Wc3 (https://www.hiveworkshop.com/threads/lua-getstacktrace.340841/)
        - @Macadamia, for showing a way to print warnings upon accessing undeclared globals, where this all started with (https://www.hiveworkshop.com/threads/lua-very-simply-trick-to-help-lua-users-track-syntax-errors.326266/)
    
    -----------------------------------------------------------------------------------------------------------------------------
    | Provides debugging utility for Wc3-maps using Lua.                                                                        |
    |                                                                                                                           |
    | Including:                                                                                                                |
    |   1. Automatic ingame error messages upon running erroneous code from triggers or timers.                                 |
    |   2. Ingame Console that allows you to execute code via Wc3 ingame chat.                                                  |
    |   3. Automatic warnings upon reading undeclared globals (which also triggers after misspelling globals)                   |
    |   4. Debug-Library functions for manual error handling.                                                                   |
    |   5. Caching of loading screen print messages until game start (which simplifies error handling during loading screen)    |
    |   6. Overwritten tostring/print-functions to show the actual string-name of an object instead of the memory position.     |
    |   7. Conversion of war3map.lua-error messages to local file error messages.                                               |
    |   8. Other useful debug utility (table.print and Debug.wc3Type)                                                           |
    -----------------------------------------------------------------------------------------------------------------------------
    
    -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    | Installation:                                                                                                                                                             |
    |                                                                                                                                                                           |
    |   1. Copy the code (DebugUtils.lua, StringWidth.lua and IngameConsole.lua) into your map. Use script files (Ctrl+U) in your trigger editor, not text-based triggers!      |
    |   2. Order the files: DebugUtils above StringWidth above IngameConsole. Make sure they are above ALL other scripts (crucial for local line number feature).               |
    |   3. Adjust the settings in the settings-section further below to receive the debug environment that fits your needs.                                                     |
    |                                                                                                                                                                           |
    | Deinstallation:                                                                                                                                                           |
    |                                                                                                                                                                           |
    |  - Debug Utils is meant to provide debugging utility and as such, shall be removed or invalidated from the map closely before release.                                    |
    |  - Optimally delete the whole Debug library. If that isn't suitable (because you have used library functions at too many places), you can instead replace Debug Utils     |
    |    by the following line of code that will invalidate all Debug functionality (without breaking your code):                                                               |
    |    Debug = setmetatable({try = function(...) return select(2,pcall(...)) end}, {__index = function(t,k) return DoNothing end}); try = Debug.try                           |
    |  - If that is also not suitable for you (because your systems rely on the Debug functionality to some degree), at least set ALLOW_INGAME_CODE_EXECUTION to false.         |
    |  - Be sure to test your map thoroughly after removing Debug Utils.                                                                                                        |
    -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    * Documentation and API-Functions:
    *
    *       - All automatic functionality provided by Debug Utils can be deactivated using the settings directly below the documentation.
    *
    * -------------------------
    * | Ingame Code Execution |
    * -------------------------
    *       - Debug Utils provides the ability to run code via chat command from within Wc3, if you have conducted step 3 from the installation section.
    *       - You can either open the ingame console by typing "-console" into the chat, or directly execute code by typing "-exec <code>".
    *       - See IngameConsole script for further documentation.
    *
    * ------------------
    * | Error Handling |
    * ------------------
    *        - Debug Utils automatically applies error handling (i.e. Debug.try) to code executed by your triggers and timers (error handling means that error messages are printed on screen, if anything doesn't run properly).
    *        - You can still use the below library functions for manual debugging.
    *
    *    Debug.try(funcToExecute, ...) / try(funcToExecute, ...) -> ...
    *        - Calls the specified function with the specified parameters in protected mode (i.e. code after Debug.try will continue to run even if the function fails to execute).
    *        - If the call is successful, returns the specified function's original return values (so p1 = Debug.try(Player, 0) will work fine).
    *        - If the call is unsuccessful, prints an error message on screen (including stack trace and parameters you have potentially logged before the error occured)
    *        - By default, the error message consists of a line-reference to war3map.lua (which you can look into by forcing a syntax error in WE or by exporting it from your map via File -> Export Script).
    *          You can get more helpful references to local script files instead, see section about "Local script references".
    *        - Example: Assume you have a code line like "func(param1,param2)", which doesn't work and you want to know why.
    *           Option 1: Change it to "Debug.try(func, param1, param2)", i.e. separate the function from the parameters.
    *           Option 2: Change it to "Debug.try(function() return func(param1, param2) end)", i.e. pack it into an anonymous function (optionally skip the return statement).
    *    Debug.log(...)
    *        - Logs the specified parameters to the Debug-log. The Debug-log will be printed upon the next error being catched by Debug.try, Debug.assert or Debug.throwError.
    *        - The Debug-log will only hold one set of parameters per code-location. That means, if you call Debug.log() inside any function, only the params saved within the latest call of that function will be kept.
    *    Debug.throwError(...)
    *        - Prints an error message including document, line number, stack trace, previously logged parameters and all specified parameters on screen. Parameters can have any type.
    *        - In contrast to Lua's native error function, this can be called outside of protected mode and doesn't halt code execution.
    *    Debug.assert(condition:boolean, errorMsg:string, ...) -> ...
    *        - Prints the specified error message including document, line number, stack trace and previously logged parameters on screen, IF the specified condition fails (i.e. resolves to false/nil).
    *        - Returns ..., IF the specified condition holds.
    *        - This works exactly like Lua's native assert, except that it also works outside of protected mode and does not halt code execution.
    *    Debug.traceback() -> string
    *        - Returns the stack trace at the position where this is called. You need to manually print it.
    *    Debug.getLine([depth: integer]) -> integer?
    *        - Returns the line in war3map.lua, where this function is executed.
    *        - You can specify a depth d >= 1 to instead return the line, where the d-th function in the stack trace was called. I.e. depth = 2 will return the line of execution of the function that calls Debug.getLine.
    *        - Due to Wc3's limited stack trace ability, this might sometimes return nil for depth >= 3, so better apply nil-checks on the result.
    *    Debug.getLocalErrorMsg(errorMsg:string) -> string
    *        - Takes an error message containing a file and a linenumber and converts war3map.lua-lines to local document lines as defined by uses of Debug.beginFile() and Debug.endFile().
    *        - Error Msg must be formatted like "<document>:<linenumber><Rest>".
    *
    * -----------------------------------
    * | Warnings for undeclared globals |
    * -----------------------------------
    *        - DebugUtils will print warnings on screen, if you read an undeclared global variable.
    *        - This is technically the case, when you misspelled on a function name, like calling CraeteUnit instead of CreateUnit.
    *        - Keep in mind though that the same warning will pop up after reading a global that was intentionally nilled. If you don't like this, turn of this feature in the settings.
    *
    * -----------------
    * | Print Caching |
    * -----------------
    *        - DebugUtils caches print()-calls occuring during loading screen and delays them to after game start.
    *        - This also applies to loading screen error messages, so you can wrap erroneous parts of your Lua root in Debug.try-blocks and see the message after game start.
    *
    * -------------------------
    * | Local File Stacktrace |
    * -------------------------
    *        - By default, error messages and stack traces printed by the error handling functionality of Debug Utils contain references to war3map.lua (a big file just appending all your local scripts).
    *        - The Debug-library provides the two functions below to index your local scripts, activating local file names and line numbers (matching those in your IDE) instead of the war3map.lua ones.
    *        - This allows you to inspect errors within your IDE (VSCode) instead of the World Editor.
    *
    *    Debug.beginFile(fileName: string [, depth: integer])
    *        - Tells the Debug library that the specified file begins exactly here (i.e. in the line, where this is called).
    *        - Using this improves stack traces of error messages. "war3map.lua"-references between <here> and the next Debug.endFile() will be converted to file-specific references.
    *        - All war3map.lua-lines located between the call of Debug.beginFile(fileName) and the next call of Debug.beginFile OR Debug.endFile are treated to be part of "fileName".
    *        - !!! To be called in the Lua root in Line 1 of every document you wish to track. Line 1 means exactly line 1, before any comment! This way, the line shown in the trace will exactly match your IDE.
    *        - Depth can be ignored, except if you want to use a custom wrapper around Debug.beginFile(), in which case you need to set the depth parameter to 1 to record the line of the wrapper instead of the line of Debug.beginFile().
    *    Debug.endFile([depth: integer])
    *        - Ends the current file that was previously begun by using Debug.beginFile(). War3map.lua-lines after this will not be converted until the next instance of Debug.beginFile().
    *        - The next call of Debug.beginFile() will also end the previous one, so using Debug.endFile() is optional. Mainly recommended to use, if you prefer to have war3map.lua-references in a certain part of your script (such as within GUI triggers).
    *        - Depth can be ignored, except if you want to use a custom wrapper around Debug.endFile(), you need to increase the depth parameter to 1 to record the line of the wrapper instead of the line of Debug.endFile().
    *
    * ----------------
    * | Name Caching |
    * ----------------
    *        - DebugUtils overwrites the tostring-function so that it prints the name of a non-primitive object (if available) instead of its memory position. The same applies to print().
    *        - For instance, print(CreateUnit) will show "function: CreateUnit" on screen instead of "function: 0063A698".
    *        - The table holding all those names is referred to as "Name Cache".
    *        - All names of objects in global scope will automatically be added to the Name Cache both within Lua root and again at game start (to get names for overwritten natives and your own objects).
    *        - New names entering global scope will also automatically be added, even after game start. The same applies to subtables of _G up to a depth of Debug.settings.NAME_CACHE_DEPTH.
    *        - Objects within subtables will be named after their parent tables and keys. For instance, the name of the function within T = {{bla = function() end}} is "T[1].bla".
    *        - The automatic adding doesn't work for objects saved into existing variables/keys after game start (because it's based on __newindex metamethod which simply doesn't trigger)
    *        - You can manually add names to the name cache by using the following API-functions:
    *
    *    Debug.registerName(whichObject:any, name:string)
    *        - Adds the specified object under the specified name to the name cache, letting tostring and print output "<type>: <name>" going foward.
    *        - The object must be non-primitive, i.e. this won't work on strings, numbers and booleans.
    *        - This will overwrite existing names for the specified object with the specified name.
    *    Debug.registerNamesFrom(parentTable:table [, parentTableName:string] [, depth])
    *        - Adds names for all values from within the specified parentTable to the name cache.
    *        - Names for entries will be like "<parentTableName>.<key>" or "<parentTableName>[<key>]" (depending on the key type), using the existing name of the parentTable from the name cache.
    *        - You can optionally specify a parentTableName to use that for the entry naming instead of the existing name. Doing so will also register that name for the parentTable, if it doesn't already has one.
    *        - Specifying the empty string as parentTableName will suppress it in the naming and just register all values as "<key>". Note that only string keys will be considered this way.
    *        - In contrast to Debug.registerName(), this function will NOT overwrite existing names, but just add names for new objects.
    *    Debug.oldTostring(object:any) -> string
    *        - The old tostring-function in case you still need outputs like "function: 0063A698".
    *
    * -----------------
    * | Other Utility |
    * -----------------
    *
    *    Debug.wc3Type(object:any) -> string
    *        - Returns the Warcraft3-type of the input object. E.g. Debug.wc3Type(Player(0)) will return "player".
    *        - Returns type(object), if used on Lua-objects.
    *    table.tostring(whichTable [, depth:integer] [, pretty_yn:boolean])
    *        - Creates a list of all (key,value)-pairs from the specified table. Also lists subtable entries up to the specified depth (unlimited, if not specified).
    *        - E.g. for T = {"a", 5, {7}}, table.tostring(T) would output '{(1, "a"), (2, 5), (3, {(1, 7)})}' (if using concise style, i.e. pretty_yn being nil or false).
    *        - Not specifying a depth can potentially lead to a stack overflow for self-referential tables (e.g X = {}; X[1] = X). Choose a sensible depth to prevent this (in doubt start with 1 and test upwards).
    *        - Supports pretty style by setting pretty_yn to true. Pretty style is linebreak-separated, uses indentations and has other visual improvements. Use it on small tables only, because Wc3 can't show that many linebreaks at once.
    *        - All of the following is valid syntax: table.tostring(T), table.tostring(T, depth), table.tostring(T, pretty_yn) or table.tostring(T, depth, pretty_yn).
    *        - table.tostring is not multiplayer-synced.
    *    table.print(whichTable [, depth:integer] [, pretty_yn:boolean])
    *        - Prints table.tostring(...).
    *
    ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------]]
    
        ----------------
        --| Settings |--
        ----------------
    
        Debug = {
            --BEGIN OF SETTINGS--
            settings = {
                    SHOW_TRACE_ON_ERROR = true                      ---Set to true to show a stack trace on every error in addition to the regular message (msg sources: automatic error handling, Debug.try, Debug.throwError, ...)
                ,   USE_TRY_ON_TRIGGERADDACTION = true              ---Set to true for automatic error handling on TriggerAddAction (applies Debug.try on every trigger action).
                ,   USE_TRY_ON_CONDITION = true                     ---Set to true for automatic error handling on boolexpressions created via Condition() or Filter() (essentially applies Debug.try on every trigger condition).
                ,   USE_TRY_ON_TIMERSTART = true                    ---Set to true for automatic error handling on TimerStart (applies Debug.try on every timer callback).
                ,   USE_TRY_ON_COROUTINES = true                    ---Set to true for improved stack traces on errors within coroutines (applies Debug.try on coroutine.create and coroutine.wrap). This lets stack traces point to the erroneous function executed within the coroutine (instead of the function creating the coroutine).
                ,   ALLOW_INGAME_CODE_EXECUTION = true              ---Set to true to enable IngameConsole and -exec command.
                ,   WARNING_FOR_UNDECLARED_GLOBALS = true           ---Set to true to print warnings upon accessing undeclared globals (i.e. globals with nil-value). This is technically the case after having misspelled on a function name (like CraeteUnit instead of CreateUnit).
                ,   SHOW_TRACE_FOR_UNDECLARED_GLOBALS = false       ---Set to true to include a stack trace into undeclared global warnings. Only takes effect, if WARNING_FOR_UNDECLARED_GLOBALS is also true.
                ,   USE_PRINT_CACHE = true                          ---Set to true to let print()-calls during loading screen be cached until the game starts.
                ,   PRINT_DURATION = nil                            ---Adjust the duration in seconds that values printed by print() last on screen. Set to nil to use default duration (which depends on string length).
                ,   USE_NAME_CACHE = true                           ---Set to true to let tostring/print output the string-name of an object instead of its memory location (except for booleans/numbers/strings). E.g. print(CreateUnit) will output "function: CreateUnit" instead of "function: 0063A698".
                ,   AUTO_REGISTER_NEW_NAMES = true                  ---Automatically adds new names from global scope (and subtables of _G up to NAME_CACHE_DEPTH) to the name cache by adding metatables with the __newindex metamethod to ALL tables accessible from global scope.
                ,   NAME_CACHE_DEPTH = 0                            ---Set to 0 to only affect globals. Experimental feature: Set to an integer > 0 to also cache names for subtables of _G (up to the specified depth). Warning: This will alter the __newindex metamethod of subtables of _G (but not break existing functionality).
            }
            --END OF SETTINGS--
            --START OF CODE--
            ,   data = {
                    nameCache = {}                                  ---@type table<any,string> contains the string names of any object in global scope (random for objects that have multiple names)
                ,   nameCacheMirror = {}                            ---@type table<string,any> contains the (name,object)-pairs of all objects in the name cache. Used to prevent name duplicates that might otherwise occur upon reassigning globals.
                ,   nameDepths = {}                                 ---@type table<any,integer> contains the depth of the name used by by any object in the name cache (i.e. the depth within the parentTable).
                ,   autoIndexedTables = {}                          ---@type table<table,boolean> contains (t,true), if DebugUtils already set a __newindex metamethod for name caching in t. Prevents double application.
                ,   paramLog = {}                                   ---@type table<string,string> saves logged information per code location. to be filled by Debug.log(), to be printed by Debug.try()
                ,   sourceMap = {{firstLine= 1,file='DebugUtils'}}  ---@type table<integer,{firstLine:integer,file:string,lastLine?:integer}> saves lines and file names of all documents registered via Debug.beginFile().
                ,   printCache = {n=0}                              ---@type string[] contains the strings that were attempted to print during loading screen.
            }
        }
        --localization
        local settings, paramLog, nameCache, nameDepths, autoIndexedTables, nameCacheMirror, sourceMap, printCache = Debug.settings, Debug.data.paramLog, Debug.data.nameCache, Debug.data.nameDepths, Debug.data.autoIndexedTables, Debug.data.nameCacheMirror, Debug.data.sourceMap, Debug.data.printCache
    
        --Write DebugUtils first line number to sourceMap:
        ---@diagnostic disable-next-line: need-check-nil
        Debug.data.sourceMap[1].firstLine = tonumber(codeLoc:match(":\x25d+"):sub(2,-1))
    
        -------------------------------------------------
        --| File Indexing for local Error Msg Support |--
        -------------------------------------------------
    
        -- Functions for war3map.lua -> local file conversion for error messages.
    
        ---Returns the line number in war3map.lua, where this is called (for depth = 0).
        ---Choose a depth > 0 to instead return the line, where the corresponding function in the stack leading to this call is executed.
        ---@param depth? integer default: 0.
        ---@return number?
        function Debug.getLine(depth)
            depth = depth or 0
            local _, location = pcall(error, "", depth + 3) ---@diagnostic disable-next-line: need-check-nil
            local line = location:match(":\x25d+") --extracts ":1000" from "war3map.lua:1000:..."
            return tonumber(line and line:sub(2,-1)) --check if line is nil before applying string.sub to prevent errors (nil can result from string.match above, although it should never do so in our case)
        end
    
        ---Tells the Debug library that the specified file begins exactly here (i.e. in the line, where this is called).
        ---
        ---Using this improves stack traces of error messages. Stack trace will have "war3map.lua"-references between this and the next Debug.endFile() converted to file-specific references.
        ---
        ---To be called in the Lua root in Line 1 of every file you wish to track! Line 1 means exactly line 1, before any comment! This way, the line shown in the trace will exactly match your IDE.
        ---
        ---If you want to use a custom wrapper around Debug.beginFile(), you need to increase the depth parameter to 1 to record the line of the wrapper instead of the line of Debug.beginFile().
        ---@param fileName string
        ---@param depth? integer default: 0. Set to 1, if you call this from a wrapper (and use the wrapper in line 1 of every document).
        ---@param lastLine? integer Ignore this. For compatibility with Total Initialization.
        function Debug.beginFile(fileName, depth, lastLine)
            depth, fileName = depth or 0, fileName or '' --filename is not actually optional, we just default to '' to prevent crashes.
            local line = Debug.getLine(depth + 1)
            if line then --for safety reasons. we don't want to add a non-existing line to the sourceMap
                table.insert(sourceMap, {firstLine = line, file = fileName, lastLine = lastLine}) --automatically sorted list, because calls of Debug.beginFile happen logically in the order of the map script.
            end
        end
    
        ---Tells the Debug library that the file previously started with Debug.beginFile() ends here.
        ---This is in theory optional to use, as the next call of Debug.beginFile will also end the previous. Still good practice to always use this in the last line of every file.
        ---If you want to use a custom wrapper around Debug.endFile(), you need to increase the depth parameter to 1 to record the line of the wrapper instead of the line of Debug.endFile().
        ---@param depth? integer
        function Debug.endFile(depth)
            depth = depth or 0
            local line = Debug.getLine(depth + 1)
            sourceMap[#sourceMap].lastLine = line
        end
    
        ---Takes an error message containing a file and a linenumber and converts both to local file and line as saved to Debug.sourceMap.
        ---@param errorMsg string must be formatted like "<document>:<linenumber><RestOfMsg>".
        ---@return string convertedMsg a string of the form "<localDocument>:<localLinenumber><RestOfMsg>"
        function Debug.getLocalErrorMsg(errorMsg)
            local startPos, endPos = errorMsg:find(":\x25d*") --start and end position of line number. The part before that is the document, part after the error msg.
            if startPos and endPos then --can be nil, if input string was not of the desired form "<document>:<linenumber><RestOfMsg>".
                local document, line, rest = errorMsg:sub(1, startPos), tonumber(errorMsg:sub(startPos+1, endPos)), errorMsg:sub(endPos+1, -1) --get error line in war3map.lua
                if document == 'war3map.lua:' and line then --only convert war3map.lua-references to local position. Other files such as Blizzard.j.lua are not converted (obiously).
                    for i = #sourceMap, 1, -1 do --find local file containing the war3map.lua error line.
                        if line >= sourceMap[i].firstLine then --war3map.lua line is part of sourceMap[i].file
                            if not sourceMap[i].lastLine or line <= sourceMap[i].lastLine then --if lastLine is given, we must also check for it
                                return sourceMap[i].file .. ":" .. (line - sourceMap[i].firstLine + 1) .. rest
                            else --if line is larger than firstLine and lastLine of sourceMap[i], it is not part of a tracked file -> return global war3map.lua position.
                                break --prevent return within next step of the loop ("line >= sourceMap[i].firstLine" would be true again, but wrong file)
                            end
                        end
                    end
                end
            end
            return errorMsg
        end
        local convertToLocalErrorMsg = Debug.getLocalErrorMsg
    
        ----------------------
        --| Error Handling |--
        ----------------------
    
        local concat
        ---Applies tostring() on all input params and concatenates them 4-space-separated.
        ---@param firstParam any
        ---@param ... any
        ---@return string
        concat = function(firstParam, ...)
            if select('#', ...) == 0 then
                return tostring(firstParam)
            end
            return tostring(firstParam) .. '    ' .. concat(...)
        end
    
        ---Returns the stack trace between the specified startDepth and endDepth.
        ---The trace lists file names and line numbers. File name is only listed, if it has changed from the previous traced line.
        ---The previous file can also be specified as an input parameter to suppress the first file name in case it's identical.
        ---@param startDepth integer
        ---@param endDepth integer
        ---@return string trace
        local function getStackTrace(startDepth, endDepth)
            local trace, separator = "", ""
            local _, lastFile, tracePiece, lastTracePiece
            for loopDepth = startDepth, endDepth do --get trace on different depth level
                _, tracePiece = pcall(error, "", loopDepth) ---@type boolean, string
                tracePiece = convertToLocalErrorMsg(tracePiece)
                if #tracePiece > 0 and lastTracePiece ~= tracePiece then --some trace pieces can be empty, but there can still be valid ones beyond that
                    trace = trace .. separator .. ((tracePiece:match("^.-:") == lastFile) and tracePiece:match(":\x25d+"):sub(2,-1) or tracePiece:match("^.-:\x25d+"))
                    lastFile, lastTracePiece, separator = tracePiece:match("^.-:"), tracePiece, " <- "
                end
            end
            return trace
        end
    
        ---Message Handler to be used by the try-function below.
        ---Adds stack trace plus formatting to the message and prints it.
        ---@param errorMsg string
        ---@param startDepth? integer default: 4 for use in xpcall
        local function errorHandler(errorMsg, startDepth)
            startDepth = startDepth or 4 --xpcall doesn't specify this param, so it defaults to 4 in this case
            errorMsg = convertToLocalErrorMsg(errorMsg)
            --Print original error message and stack trace.
            print("|cffff5555ERROR at " .. errorMsg .. "|r")
            if settings.SHOW_TRACE_ON_ERROR then
                print("|cffff5555Traceback (most recent call first):|r")
                print("|cffff5555" .. getStackTrace(startDepth,200) .. "|r")
            end
            --Also print entries from param log, if there are any.
            for location, loggedParams in pairs(paramLog) do
                print("|cff888888Logged at " .. convertToLocalErrorMsg(location) .. loggedParams .. "|r")
                paramLog[location] = nil
            end
        end
    
        ---Tries to execute the specified function with the specified parameters in protected mode and prints an error message (including stack trace), if unsuccessful.
        ---
        ---Example use: Assume you have a code line like "CreateUnit(0,1,2)", which doesn't work and you want to know why.
        ---* Option 1: Change it to "Debug.try(CreateUnit, 0, 1, 2)", i.e. separate the function from the parameters.
        ---* Option 2: Change it to "Debug.try(function() return CreateUnit(0,1,2) end)", i.e. pack it into an anonymous function. You can skip the "return", if you don't need the return values.
        ---When no error occured, the try-function will return all values returned by the input function.
        ---When an error occurs, try will print the resulting error and stack trace.
        ---@param funcToExecute function the function to call in protected mode
        ---@param ... any params for the input-function
        ---@return ... any
        function Debug.try(funcToExecute, ...)
            return select(2, xpcall(funcToExecute, errorHandler,...))
        end
        try = Debug.try
    
        ---Prints "ERROR:" and the specified error objects on the Screen. Also prints the stack trace leading to the error. You can specify as many arguments as you wish.
        ---
        ---In contrast to Lua's native error function, this can be called outside of protected mode and doesn't halt code execution.
        ---@param ... any objects/errormessages to be printed (doesn't have to be strings)
        function Debug.throwError(...)
            errorHandler(getStackTrace(4,4) .. ": " .. concat(...), 5)
        end
    
        ---Prints the specified error message, if the specified condition fails (i.e. if it resolves to false or nil).
        ---
        ---Returns all specified arguments after the errorMsg, if the condition holds.
        ---
        ---In contrast to Lua's native assert function, this can be called outside of protected mode and doesn't halt code execution (even in case of condition failure).
        ---@param condition any actually a boolean, but you can use any object as a boolean.
        ---@param errorMsg string the message to be printed, if the condition fails
        ---@param ... any will be returned, if the condition holds
        function Debug.assert(condition, errorMsg, ...)
            if condition then
                return ...
            else
                errorHandler(getStackTrace(4,4) .. ": " .. errorMsg, 5)
            end
        end
    
        ---Returns the stack trace at the code position where this function is called.
        ---The returned string includes war3map.lua/blizzard.j.lua code positions of all functions from the stack trace in the order of execution (most recent call last). It does NOT include function names.
        ---@return string
        function Debug.traceback()
            return getStackTrace(3,200)
        end
    
        ---Saves the specified parameters to the debug log at the location where this function is called. The Debug-log will be printed for all affected locations upon the try-function catching an error.
        ---The log is unique per code location: Parameters logged at code line x will overwrite the previous ones logged at x. Parameters logged at different locations will all persist and be printed.
        ---@param ... any save any information, for instance the parameters of the function call that you are logging.
        function Debug.log(...)
            local _, location = pcall(error, "", 3) ---@diagnostic disable-next-line: need-check-nil
            paramLog[location or ''] = concat(...)
        end
    
        ------------------------------------
        --| Name Caching (API-functions) |--
        ------------------------------------
    
        --Help-table. The registerName-functions below shall not work on call-by-value-types, i.e. booleans, strings and numbers (renaming a value of any primitive type doesn't make sense).
        local skipType = {boolean = true, string = true, number = true, ['nil'] = true}
        --Set weak keys to nameCache and nameDepths and weak values for nameCacheMirror to prevent garbage collection issues
        setmetatable(nameCache, {__mode = 'k'})
        setmetatable(nameDepths, getmetatable(nameCache))
        setmetatable(nameCacheMirror, {__mode = 'v'})
    
        ---Removes the name from the name cache, if already used for any object (freeing it for the new object). This makes sure that a name is always unique.
        ---This doesn't solve the
        ---@param name string
        local function removeNameIfNecessary(name)
            if nameCacheMirror[name] then
                nameCache[nameCacheMirror[name]] = nil
                nameCacheMirror[name] = nil
            end
        end
    
        ---Registers a name for the specified object, which will be the future output for tostring(whichObject).
        ---You can overwrite existing names for whichObject by using this.
        ---@param whichObject any
        ---@param name string
        function Debug.registerName(whichObject, name)
            if not skipType[type(whichObject)] then
                removeNameIfNecessary(name)
                nameCache[whichObject] = name
                nameCacheMirror[name] = whichObject
                nameDepths[name] = 0
            end
        end
    
        ---Registers a new name to the nameCache as either just <key> (if parentTableName is the empty string), <table>.<key> (if parentTableName is given and string key doesn't contain whitespace) or <name>[<key>] notation (for other keys in existing tables).
        ---Only string keys without whitespace support <key>- and <table>.<key>-notation. All other keys require a parentTableName.
        ---@param parentTableName string | '""' empty string suppresses <table>-affix.
        ---@param key any
        ---@param object any only call-be-ref types allowed
        ---@param parentTableDepth? integer
        local function addNameToCache(parentTableName, key, object, parentTableDepth)
            parentTableDepth = parentTableDepth or -1
            --Don't overwrite existing names for the same object, don't add names for primitive types.
            if nameCache[object] or skipType[type(object)] then
                return
            end
            local name
            --apply dot-syntax for string keys without whitespace
            if type(key) == 'string' and not string.find(key, "\x25s") then
                if parentTableName == "" then
                    name = key
                    nameDepths[object] = 0
                else
                    name =  parentTableName .. "." .. key
                    nameDepths[object] = parentTableDepth + 1
                end
            --apply bracket-syntax for all other keys. This requires a parentTableName.
            elseif parentTableName ~= "" then
                name = type(key) == 'string' and ('"' .. key .. '"') or key
                name = parentTableName .. "[" .. tostring(name) .. "]"
                nameDepths[object] = parentTableDepth + 1
            end
            --Stop in cases without valid name (like parentTableName = "" and key = [1])
            if name then
                removeNameIfNecessary(name)
                nameCache[object] = name
                nameCacheMirror[name] = object
            end
        end
    
        ---Registers all call-by-reference objects in the given parentTable to the nameCache.
        ---Automatically filters out primitive objects and already registed Objects.
        ---@param parentTable table
        ---@param parentTableName? string
        local function registerAllObjectsInTable(parentTable, parentTableName)
            parentTableName = parentTableName or nameCache[parentTable] or ""
            --Register all call-by-ref-objects in parentTable
            for key, object in pairs(parentTable) do
                addNameToCache(parentTableName, key, object, nameDepths[parentTable])
            end
        end
    
        ---Adds names for all values of the specified parentTable to the name cache. Names will be "<parentTableName>.<key>" or "<parentTableName>[<key>]", depending on the key type.
        ---
        ---Example: Given a table T = {f = function() end, [1] = {}}, tostring(T.f) and tostring(T[1]) will output "function: T.f" and "table: T[1]" respectively after running Debug.registerNamesFrom(T).
        ---The name of T itself must either be specified as an input parameter OR have previously been registered. It can also be suppressed by inputting the empty string (so objects will just display by their own names).
        ---The names of objects in global scope are automatically registered during loading screen.
        ---@param parentTable table base table of which all entries shall be registered (in the Form parentTableName.objectName).
        ---@param parentTableName? string|'""' Nil: takes <parentTableName> as previously registered. Empty String: Skips <parentTableName> completely. String <s>: Objects will show up as "<s>.<objectName>".
        ---@param depth? integer objects within sub-tables up to the specified depth will also be added. Default: 1 (only elements of whichTable). Must be >= 1.
        ---@overload fun(parentTable:table, depth:integer)
        function Debug.registerNamesFrom(parentTable, parentTableName, depth)
            --Support overloaded definition fun(parentTable:table, depth:integer)
            if type(parentTableName) == 'number' then
                depth = parentTableName
                parentTableName = nil
            end
            --Apply default values
            depth = depth or 1
            parentTableName = parentTableName or nameCache[parentTable] or ""
            --add name of T in case it hasn't already
            if not nameCache[parentTable] and parentTableName ~= "" then
                Debug.registerName(parentTable, parentTableName)
            end
            --Register all call-by-ref-objects in parentTable. To be preferred over simple recursive approach to ensure that top level names are preferred.
            registerAllObjectsInTable(parentTable, parentTableName)
            --if depth > 1 was specified, also register Names from subtables.
            if depth > 1 then
                for _, object in pairs(parentTable) do
                    if type(object) == 'table' then
                        Debug.registerNamesFrom(object, nil, depth - 1)
                    end
                end
            end
        end
    
        -------------------------------------------
        --| Name Caching (Loading Screen setup) |--
        -------------------------------------------
    
        ---Registers all existing object names from global scope and Lua incorporated libraries to be used by tostring() overwrite below.
        local function registerNamesFromGlobalScope()
            --Add all names from global scope to the name cache.
            Debug.registerNamesFrom(_G, "")
            --Add all names of Warcraft-enabled Lua libraries as well:
            --Could instead add a depth to the function call above, but we want to ensure that these libraries are added even if the user has chosen depth 0.
            for _, lib in ipairs({coroutine, math, os, string, table, utf8, Debug}) do
                Debug.registerNamesFrom(lib)
            end
            --Add further names that are not accessible from global scope:
            --Player(i)
            for i = 0, GetBJMaxPlayerSlots() - 1 do
                Debug.registerName(Player(i), "Player(" .. i .. ")")
            end
        end
    
        --Set empty metatable to _G. __index is added when game starts (for "attempt to read undeclared global"-errors), __newindex is added right below (for building the name cache).
        setmetatable(_G, getmetatable(_G) or {}) --getmetatable(_G) should always return nil provided that DebugUtils is the topmost script file in the trigger editor, but we still include this for safety-
    
        -- Save old tostring into Debug Library before overwriting it.
        Debug.oldTostring = tostring
    
        if settings.USE_NAME_CACHE then
            local oldTostring = tostring
            tostring = function(obj) --new tostring(CreateUnit) prints "function: CreateUnit"
                --tostring of non-primitive object is NOT guaranteed to be like "<type>:<hex>", because it might have been changed by some __tostring-metamethod.
                if settings.USE_NAME_CACHE then --return names from name cache only if setting is enabled. This allows turning it off during runtime (via Ingame Console) to revert to old tostring.
                    return nameCache[obj] and ((oldTostring(obj):match("^.-: ") or (oldTostring(obj) .. ": ")) .. nameCache[obj]) or oldTostring(obj)
                end
                return Debug.oldTostring(obj)
            end
            --Add names to Debug.data.objectNames within Lua root. Called below the other Debug-stuff to get the overwritten versions instead of the original ones.
            registerNamesFromGlobalScope()
    
            --Prepare __newindex-metamethod to automatically add new names to the name cache
            if settings.AUTO_REGISTER_NEW_NAMES then
                local nameRegisterNewIndex
                ---__newindex to be used for _G (and subtables up to a certain depth) to automatically register new names to the nameCache.
                ---Tables in global scope will use their own name. Subtables of them will use <parentName>.<childName> syntax.
                ---Global names don't support container[key]-notation (because "_G[...]" is probably not desired), so we only register string type keys instead of using prettyTostring.
                ---@param t table
                ---@param k any
                ---@param v any
                ---@param skipRawset? boolean set this to true when combined with another __newindex. Suppresses rawset(t,k,v) (because the other __newindex is responsible for that).
                nameRegisterNewIndex = function(t,k,v, skipRawset)
                    local parentDepth = nameDepths[t] or 0
                    --Make sure the parent table has an existing name before using it as part of the child name
                    if t == _G or nameCache[t] then
                        local existingName = nameCache[v]
                        if not existingName then
                            addNameToCache((t == _G and "") or nameCache[t], k, v, parentDepth)
                        end
                        --If v is a table and the parent table has a valid name, inherit __newindex to v's existing metatable (or create a new one), if that wasn't already done.
                        if type(v) == 'table' and nameDepths[v] < settings.NAME_CACHE_DEPTH then
                            if not existingName then
                                --If v didn't have a name before, also add names for elements contained in v by construction (like v = {x = function() end} ).
                                Debug.registerNamesFrom(v, settings.NAME_CACHE_DEPTH - nameDepths[v])
                            end
                            --Apply __newindex to new tables.
                            if not autoIndexedTables[v] then
                                autoIndexedTables[v] = true
                                local mt = getmetatable(v)
                                if not mt then
                                    mt = {}
                                    setmetatable(v, mt) --only use setmetatable when we are sure there wasn't any before to prevent issues with "__metatable"-metamethod.
                                end
                                local existingNewIndex = mt.__newindex
                                local isTable_yn = (type(existingNewIndex) == 'table')
                                --If mt has an existing __newindex, add the name-register effect to it (effectively create a new __newindex using the old)
                                if existingNewIndex then
                                    mt.__newindex = function(t,k,v)
                                        nameRegisterNewIndex(t,k,v, true) --setting t[k] = v might not be desired in case of existing newindex. Skip it and let existingNewIndex make the decision.
                                        if isTable_yn then
                                            existingNewIndex[k] = v
                                        else
                                            return existingNewIndex(t,k,v)
                                        end
                                    end
                                else
                                --If mt doesn't have an existing __newindex, add one that adds the object to the name cache.
                                    mt.__newindex = nameRegisterNewIndex
                                end
                            end
                        end
                    end
                    --Set t[k] = v.
                    if not skipRawset then
                        rawset(t,k,v)
                    end
                end
    
                --Apply metamethod to _G.
                local existingNewIndex = getmetatable(_G).__newindex --should always be nil provided that DebugUtils is the topmost script in your trigger editor. Still included for safety.
                local isTable_yn = (type(existingNewIndex) == 'table')
                if existingNewIndex then
                    getmetatable(_G).__newindex = function(t,k,v)
                        nameRegisterNewIndex(t,k,v, true)
                        if isTable_yn then
                            existingNewIndex[k] = v
                        else
                            existingNewIndex(t,k,v)
                        end
                    end
                else
                    getmetatable(_G).__newindex = nameRegisterNewIndex
                end
            end
        end
    
        ------------------------------------------------------
        --| Native Overwrite for Automatic Error Handling  |--
        ------------------------------------------------------
    
        --A table to store the try-wrapper for each function. This avoids endless re-creation of wrapper functions within the hooks below.
        --Weak keys ensure that garbage collection continues as normal.
        local tryWrappers = setmetatable({}, {__mode = 'k'}) ---@type table<function,function>
        local try = Debug.try
    
        ---Takes a function and returns a wrapper executing the same function within Debug.try.
        ---Wrappers are permanently stored (until the original function is garbage collected) to ensure that they don't have to be created twice for the same function.
        ---@param func? function
        ---@return function
        local function getTryWrapper(func)
            if func then
                tryWrappers[func] = tryWrappers[func] or function(...) return try(func, ...) end
            end
            return tryWrappers[func] --returns nil for func = nil (important for TimerStart overwrite below)
        end
    
        --Overwrite TriggerAddAction, TimerStart, Condition and Filter natives to let them automatically apply Debug.try.
        --Also overwrites coroutine.create and coroutine.wrap to let stack traces point to the function executed within instead of the function creating the coroutine.
        if settings.USE_TRY_ON_TRIGGERADDACTION then
            local originalTriggerAddAction = TriggerAddAction
            TriggerAddAction = function(whichTrigger, actionFunc)
                return originalTriggerAddAction(whichTrigger, getTryWrapper(actionFunc))
            end
        end
        if settings.USE_TRY_ON_TIMERSTART then
            local originalTimerStart = TimerStart
            TimerStart = function(whichTimer, timeout, periodic, handlerFunc)
                originalTimerStart(whichTimer, timeout, periodic, getTryWrapper(handlerFunc))
            end
        end
        if settings.USE_TRY_ON_CONDITION then
            local originalCondition = Condition
            Condition = function(func)
                return originalCondition(getTryWrapper(func))
            end
            Filter = Condition
        end
        if settings.USE_TRY_ON_COROUTINES then
            local originalCoroutineCreate = coroutine.create
            ---@diagnostic disable-next-line: duplicate-set-field
            coroutine.create = function(f)
                return originalCoroutineCreate(getTryWrapper(f))
            end
            local originalCoroutineWrap = coroutine.wrap
            ---@diagnostic disable-next-line: duplicate-set-field
            coroutine.wrap = function(f)
                return originalCoroutineWrap(getTryWrapper(f))
            end
        end
    
        ------------------------------------------
        --| Cache prints during Loading Screen |--
        ------------------------------------------
    
        -- Apply the duration as specified in the settings.
        if settings.PRINT_DURATION then
            local display, getLocalPlayer, dur = DisplayTimedTextToPlayer, GetLocalPlayer, settings.PRINT_DURATION
            print = function(...)
                display(getLocalPlayer(), 0, 0, dur, concat(...))
            end
        end
    
        -- Delay loading screen prints to after game start.
        if settings.USE_PRINT_CACHE then
            local oldPrint = print
            --loading screen print will write the values into the printCache
            print = function(...)
                if bj_gameStarted then
                    oldPrint(...)
                else --during loading screen only: concatenate input arguments 4-space-separated, implicitely apply tostring on each, cache to table
                    printCache.n = printCache.n + 1
                    printCache[printCache.n] = concat(...)
                end
            end
        end
    
        -------------------------
        --| Modify Game Start |--
        -------------------------
    
        local originalMarkGameStarted = MarkGameStarted
        --Hook certain actions into the start of the game.
        MarkGameStarted = function()
            originalMarkGameStarted()
            if settings.WARNING_FOR_UNDECLARED_GLOBALS then
                local existingIndex = getmetatable(_G).__index
                local isTable_yn = (type(existingIndex) == 'table')
                getmetatable(_G).__index = function(t, k) --we made sure that _G has a metatable further above.
                    --if string.sub(tostring(k),1,3) ~= 'bj_' then
                        print("Trying to read undeclared global at " .. getStackTrace(4,4) .. ": " .. tostring(k)
                            .. (settings.SHOW_TRACE_FOR_UNDECLARED_GLOBALS and "\nTraceback (most recent call first):\n" .. getStackTrace(4,200) or ""))
                    --end
                    if existingIndex then
                        if isTable_yn then
                            return existingIndex[k]
                        end
                        return existingIndex(t,k)
                    end
                    return rawget(t,k)
                end
            end
    
            --Add names to Debug.data.objectNames again to ensure that overwritten natives also make it to the name cache.
            --Overwritten natives have a new value, but the old key, so __newindex didn't trigger. But we can be sure that objectNames[v] doesn't yet exist, so adding again is safe.
            if settings.USE_NAME_CACHE then
                for _,v in pairs(_G) do
                    nameCache[v] = nil
                end
                registerNamesFromGlobalScope()
            end
    
            --Print messages that have been cached during loading screen.
            if settings.USE_PRINT_CACHE then
                --Note that we don't restore the old print. The overwritten variant only applies caching behaviour to loading screen prints anyway and "unhooking" always adds other risks.
                for _, str in ipairs(printCache) do
                    print(str)
                end
                printCache = nil --frees reference for the garbage collector
            end
    
            --Create triggers listening to "-console" and "-exec" chat input.
            if settings.ALLOW_INGAME_CODE_EXECUTION and IngameConsole then
                IngameConsole.createTriggers()
            end
        end
    
        ---------------------
        --| Other Utility |--
        ---------------------
    
        do
            ---Returns the type of a warcraft object as string, e.g. "unit" upon inputting a unit.
            ---@param input any
            ---@return string
            function Debug.wc3Type(input)
                local typeString = type(input)
                if typeString == 'userdata' then
                    typeString = tostring(input) --tostring returns the warcraft type plus a colon and some hashstuff.
                    return typeString:sub(1, (typeString:find(":", nil, true) or 0) -1) --string.find returns nil, if the argument is not found, which would break string.sub. So we need to replace by 0.
                else
                    return typeString
                end
            end
            Wc3Type = Debug.wc3Type --for backwards compatibility
    
            local conciseTostring, prettyTostring
    
            ---Translates a table into a comma-separated list of its (key,value)-pairs. Also translates subtables up to the specified depth.
            ---E.g. {"a", 5, {7}} will display as '{(1, "a"), (2, 5), (3, {(1, 7)})}'.
            ---@param object any
            ---@param depth? integer default: unlimited. Unlimited depth will throw a stack overflow error on self-referential tables.
            ---@return string
            conciseTostring = function (object, depth)
                depth = depth or -1
                if type(object) == 'string' then
                    return '"' .. object .. '"'
                elseif depth ~= 0 and type(object) == 'table' then
                    local elementArray = {}
                    local keyAsString
                    for k,v in pairs(object) do
                        keyAsString = type(k) == 'string' and ('"' .. tostring(k) .. '"') or tostring(k)
                        table.insert(elementArray, '(' .. keyAsString .. ', ' .. conciseTostring(v, depth -1) .. ')')
                    end
                    return '{' .. table.concat(elementArray, ', ') .. '}'
                end
                return tostring(object)
            end
    
            ---Creates a list of all (key,value)-pairs from the specified table. Also lists subtable entries up to the specified depth.
            ---Major differences to concise print are:
            --- * Format: Linebreak-formatted instead of one-liner, uses "[key] = value" instead of "(key,value)"
            --- * Will also unpack tables used as keys
            --- * Also includes the table's memory position as returned by tostring(table).
            --- * Tables referenced multiple times will only be unpacked upon first encounter and abbreviated on subsequent encounters
            --- * As a consequence, pretty version can be executed with unlimited depth on self-referential tables.
            ---@param object any
            ---@param depth? integer default: unlimited.
            ---@param constTable table
            ---@param indent string
            ---@return string
            prettyTostring = function(object, depth, constTable, indent)
                depth = depth or -1
                local objType = type(object)
                if objType == "string" then
                    return '"'..object..'"' --wrap the string in quotes.
                elseif objType == 'table' and depth ~= 0 then
                    if not constTable[object] then
                        constTable[object] = tostring(object):gsub(":","")
                        if next(object)==nil then
                            return constTable[object]..": {}"
                        else
                            local mappedKV = {}
                            for k,v in pairs(object) do
                                table.insert(mappedKV, '\n  ' .. indent ..'[' .. prettyTostring(k, depth - 1, constTable, indent .. "  ") .. '] = ' .. prettyTostring(v, depth - 1, constTable, indent .. "  "))
                            end
                            return constTable[object]..': {'.. table.concat(mappedKV, ',') .. '\n'..indent..'}'
                        end
                    end
                end
                return constTable[object] or tostring(object)
            end
    
            ---Creates a list of all (key,value)-pairs from the specified table. Also lists subtable entries up to the specified depth.
            ---Supports concise style and pretty style.
            ---Concise will display {"a", 5, {7}} as '{(1, "a"), (2, 5), (3, {(1, 7)})}'.
            ---Pretty is linebreak-separated, so consider table size before converting. Pretty also abbreviates tables referenced multiple times.
            ---Can be called like table.tostring(T), table.tostring(T, depth), table.tostring(T, pretty_yn) or table.tostring(T, depth, pretty_yn).
            ---table.tostring is not multiplayer-synced.
            ---@param whichTable table
            ---@param depth? integer default: unlimited
            ---@param pretty_yn? boolean default: false (concise)
            ---@return string
            ---@overload fun(whichTable:table, pretty_yn?:boolean):string
            function table.tostring(whichTable, depth, pretty_yn)
                --reassign input params, if function was called as table.tostring(whichTable, pretty_yn)
                if type(depth) == 'boolean' then
                    pretty_yn = depth
                    depth = -1
                end
                return pretty_yn and prettyTostring(whichTable, depth, {}, "") or conciseTostring(whichTable, depth)
            end
    
            ---Prints a list of (key,value)-pairs contained in the specified table and its subtables up to the specified depth.
            ---Supports concise style and pretty style. Pretty is linebreak-separated, so consider table size before printing.
            ---Can be called like table.print(T), table.print(T, depth), table.print(T, pretty_yn) or table.print(T, depth, pretty_yn).
            ---@param whichTable table
            ---@param depth? integer default: unlimited
            ---@param pretty_yn? boolean default: false (concise)
            ---@overload fun(whichTable:table, pretty_yn?:boolean)
            function table.print(whichTable, depth, pretty_yn)
                print(table.tostring(whichTable, depth, pretty_yn))
            end
        end
    end
    Debug.endFile()
------------------------
----| String Width |----
------------------------

--[[
    offers functions to measure the width of a string (i.e. the space it takes on screen, not the number of chars). Wc3 font is not monospace, so the system below has protocolled every char width and simply sums up all chars in a string.
    output measures are:
    1. Multiboard-width (i.e. 1-based screen share used in Multiboards column functions)
    2. Line-width for screen prints
    every unknown char will be treated as having default width (see constants below)
--]]

do
    ----------------------------
    ----| String Width API |----
    ----------------------------

    local multiboardCharTable = {}                        ---@type table  -- saves the width in screen percent (on 1920 pixel width resolutions) that each char takes up, when displayed in a multiboard.
    local DEFAULT_MULTIBOARD_CHAR_WIDTH = 1. / 128.        ---@type number    -- used for unknown chars (where we didn't define a width in the char table)
    local MULTIBOARD_TO_PRINT_FACTOR = 1. / 36.            ---@type number    -- 36 is actually the lower border (longest width of a non-breaking string only consisting of the letter "i")

    ---Returns the width of a char in a multiboard, when inputting a char (string of length 1) and 0 otherwise.
    ---also returns 0 for non-recorded chars (like ` and ´ and ß and § and €)
    ---@param char string | integer integer bytecode representations of chars are also allowed, i.e. the results of string.byte().
    ---@param textlanguage? '"ger"'| '"eng"' (default: 'eng'), depending on the text language in the Warcraft 3 installation settings.
    ---@return number
    function string.charMultiboardWidth(char, textlanguage)
        return multiboardCharTable[textlanguage or 'eng'][char] or DEFAULT_MULTIBOARD_CHAR_WIDTH
    end

    ---returns the width of a string in a multiboard (i.e. output is in screen percent)
    ---unknown chars will be measured with default width (see constants above)
    ---@param multichar string
    ---@param textlanguage? '"ger"'| '"eng"' (default: 'eng'), depending on the text language in the Warcraft 3 installation settings.
    ---@return number
    function string.multiboardWidth(multichar, textlanguage)
        local chartable = table.pack(multichar:byte(1,-1)) --packs all bytecode char representations into a table
        local charWidth = 0.
        for i = 1, chartable.n do
            charWidth = charWidth + string.charMultiboardWidth(chartable[i], textlanguage)
        end
        return charWidth
    end

    ---The function should match the following criteria: If the value returned by this function is smaller than 1.0, than the string fits into a single line on screen.
    ---The opposite is not necessarily true (but should be true in the majority of cases): If the function returns bigger than 1.0, the string doesn't necessarily break.
    ---@param char string | integer integer bytecode representations of chars are also allowed, i.e. the results of string.byte().
    ---@param textlanguage? '"ger"'| '"eng"' (default: 'eng'), depending on the text language in the Warcraft 3 installation settings.
    ---@return number
    function string.charPrintWidth(char, textlanguage)
        return string.charMultiboardWidth(char, textlanguage) * MULTIBOARD_TO_PRINT_FACTOR
    end

    ---The function should match the following criteria: If the value returned by this function is smaller than 1.0, than the string fits into a single line on screen.
    ---The opposite is not necessarily true (but should be true in the majority of cases): If the function returns bigger than 1.0, the string doesn't necessarily break.
    ---@param multichar string
    ---@param textlanguage? '"ger"'| '"eng"' (default: 'eng'), depending on the text language in the Warcraft 3 installation settings.
    ---@return number
    function string.printWidth(multichar, textlanguage)
        return string.multiboardWidth(multichar, textlanguage) * MULTIBOARD_TO_PRINT_FACTOR
    end

    ----------------------------------
    ----| String Width Internals |----
    ----------------------------------

    ---@param charset '"ger"'| '"eng"' (default: 'eng'), depending on the text language in the Warcraft 3 installation settings.
    ---@param char string|integer either the char or its bytecode
    ---@param lengthInScreenWidth number
    local function setMultiboardCharWidth(charset, char, lengthInScreenWidth)
        multiboardCharTable[charset] = multiboardCharTable[charset] or {}
        multiboardCharTable[charset][char] = lengthInScreenWidth
    end

    ---numberPlacements says how often the char can be placed in a multiboard column, before reaching into the right bound.
    ---@param charset '"ger"'| '"eng"' (default: 'eng'), depending on the text language in the Warcraft 3 installation settings.
    ---@param char string|integer either the char or its bytecode
    ---@param numberPlacements integer
    local function setMultiboardCharWidthBase80(charset, char, numberPlacements)
        setMultiboardCharWidth(charset, char, 0.8 / numberPlacements) --1-based measure. 80./numberPlacements would result in Screen Percent.
        setMultiboardCharWidth(charset, char:byte(1,-1), 0.8 / numberPlacements)
    end

    -- Set Char Width for all printable ascii chars in screen width (1920 pixels). Measured on a 80percent screen width multiboard column by counting the number of chars that fit into it.
    -- Font size differs by text install language and patch (1.32- vs. 1.33+)
    if BlzGetUnitOrderCount then --identifies patch 1.33+
        --German font size for patch 1.33+
        setMultiboardCharWidthBase80('ger', "a", 144)
        setMultiboardCharWidthBase80('ger', "b", 131)
        setMultiboardCharWidthBase80('ger', "c", 144)
        setMultiboardCharWidthBase80('ger', "d", 120)
        setMultiboardCharWidthBase80('ger', "e", 131)
        setMultiboardCharWidthBase80('ger', "f", 240)
        setMultiboardCharWidthBase80('ger', "g", 120)
        setMultiboardCharWidthBase80('ger', "h", 131)
        setMultiboardCharWidthBase80('ger', "i", 288)
        setMultiboardCharWidthBase80('ger', "j", 288)
        setMultiboardCharWidthBase80('ger', "k", 144)
        setMultiboardCharWidthBase80('ger', "l", 288)
        setMultiboardCharWidthBase80('ger', "m", 85)
        setMultiboardCharWidthBase80('ger', "n", 131)
        setMultiboardCharWidthBase80('ger', "o", 120)
        setMultiboardCharWidthBase80('ger', "p", 120)
        setMultiboardCharWidthBase80('ger', "q", 120)
        setMultiboardCharWidthBase80('ger', "r", 206)
        setMultiboardCharWidthBase80('ger', "s", 160)
        setMultiboardCharWidthBase80('ger', "t", 206)
        setMultiboardCharWidthBase80('ger', "u", 131)
        setMultiboardCharWidthBase80('ger', "v", 131)
        setMultiboardCharWidthBase80('ger', "w", 96)
        setMultiboardCharWidthBase80('ger', "x", 144)
        setMultiboardCharWidthBase80('ger', "y", 131)
        setMultiboardCharWidthBase80('ger', "z", 144)
        setMultiboardCharWidthBase80('ger', "A", 103)
        setMultiboardCharWidthBase80('ger', "B", 120)
        setMultiboardCharWidthBase80('ger', "C", 111)
        setMultiboardCharWidthBase80('ger', "D", 103)
        setMultiboardCharWidthBase80('ger', "E", 144)
        setMultiboardCharWidthBase80('ger', "F", 160)
        setMultiboardCharWidthBase80('ger', "G", 96)
        setMultiboardCharWidthBase80('ger', "H", 96)
        setMultiboardCharWidthBase80('ger', "I", 240)
        setMultiboardCharWidthBase80('ger', "J", 240)
        setMultiboardCharWidthBase80('ger', "K", 120)
        setMultiboardCharWidthBase80('ger', "L", 144)
        setMultiboardCharWidthBase80('ger', "M", 76)
        setMultiboardCharWidthBase80('ger', "N", 96)
        setMultiboardCharWidthBase80('ger', "O", 90)
        setMultiboardCharWidthBase80('ger', "P", 131)
        setMultiboardCharWidthBase80('ger', "Q", 90)
        setMultiboardCharWidthBase80('ger', "R", 120)
        setMultiboardCharWidthBase80('ger', "S", 131)
        setMultiboardCharWidthBase80('ger', "T", 144)
        setMultiboardCharWidthBase80('ger', "U", 103)
        setMultiboardCharWidthBase80('ger', "V", 120)
        setMultiboardCharWidthBase80('ger', "W", 76)
        setMultiboardCharWidthBase80('ger', "X", 111)
        setMultiboardCharWidthBase80('ger', "Y", 120)
        setMultiboardCharWidthBase80('ger', "Z", 120)
        setMultiboardCharWidthBase80('ger', "1", 144)
        setMultiboardCharWidthBase80('ger', "2", 120)
        setMultiboardCharWidthBase80('ger', "3", 120)
        setMultiboardCharWidthBase80('ger', "4", 120)
        setMultiboardCharWidthBase80('ger', "5", 120)
        setMultiboardCharWidthBase80('ger', "6", 120)
        setMultiboardCharWidthBase80('ger', "7", 131)
        setMultiboardCharWidthBase80('ger', "8", 120)
        setMultiboardCharWidthBase80('ger', "9", 120)
        setMultiboardCharWidthBase80('ger', "0", 120)
        setMultiboardCharWidthBase80('ger', ":", 288)
        setMultiboardCharWidthBase80('ger', ";", 288)
        setMultiboardCharWidthBase80('ger', ".", 288)
        setMultiboardCharWidthBase80('ger', "#", 120)
        setMultiboardCharWidthBase80('ger', ",", 288)
        setMultiboardCharWidthBase80('ger', " ", 286) --space
        setMultiboardCharWidthBase80('ger', "'", 180)
        setMultiboardCharWidthBase80('ger', "!", 180)
        setMultiboardCharWidthBase80('ger', "$", 131)
        setMultiboardCharWidthBase80('ger', "&", 90)
        setMultiboardCharWidthBase80('ger', "/", 180)
        setMultiboardCharWidthBase80('ger', "(", 240)
        setMultiboardCharWidthBase80('ger', ")", 240)
        setMultiboardCharWidthBase80('ger', "=", 120)
        setMultiboardCharWidthBase80('ger', "?", 144)
        setMultiboardCharWidthBase80('ger', "^", 144)
        setMultiboardCharWidthBase80('ger', "<", 144)
        setMultiboardCharWidthBase80('ger', ">", 144)
        setMultiboardCharWidthBase80('ger', "-", 180)
        setMultiboardCharWidthBase80('ger', "+", 120)
        setMultiboardCharWidthBase80('ger', "*", 180)
        setMultiboardCharWidthBase80('ger', "|", 287) --2 vertical bars in a row escape to one. So you could print 960 ones in a line, 480 would display. Maybe need to adapt to this before calculating string width.
        setMultiboardCharWidthBase80('ger', "~", 111)
        setMultiboardCharWidthBase80('ger', "{", 240)
        setMultiboardCharWidthBase80('ger', "}", 240)
        setMultiboardCharWidthBase80('ger', "[", 240)
        setMultiboardCharWidthBase80('ger', "]", 240)
        setMultiboardCharWidthBase80('ger', "_", 144)
        setMultiboardCharWidthBase80('ger', "\x25", 103) --percent
        setMultiboardCharWidthBase80('ger', "\x5C", 205) --backslash
        setMultiboardCharWidthBase80('ger', "\x22", 120) --double quotation mark
        setMultiboardCharWidthBase80('ger', "\x40", 90) --at sign
        setMultiboardCharWidthBase80('ger', "\x60", 144) --Gravis (Accent)

        --English font size for patch 1.33+
        setMultiboardCharWidthBase80('eng', "a", 144)
        setMultiboardCharWidthBase80('eng', "b", 120)
        setMultiboardCharWidthBase80('eng', "c", 131)
        setMultiboardCharWidthBase80('eng', "d", 120)
        setMultiboardCharWidthBase80('eng', "e", 120)
        setMultiboardCharWidthBase80('eng', "f", 240)
        setMultiboardCharWidthBase80('eng', "g", 120)
        setMultiboardCharWidthBase80('eng', "h", 120)
        setMultiboardCharWidthBase80('eng', "i", 288)
        setMultiboardCharWidthBase80('eng', "j", 288)
        setMultiboardCharWidthBase80('eng', "k", 144)
        setMultiboardCharWidthBase80('eng', "l", 288)
        setMultiboardCharWidthBase80('eng', "m", 80)
        setMultiboardCharWidthBase80('eng', "n", 120)
        setMultiboardCharWidthBase80('eng', "o", 111)
        setMultiboardCharWidthBase80('eng', "p", 111)
        setMultiboardCharWidthBase80('eng', "q", 111)
        setMultiboardCharWidthBase80('eng', "r", 206)
        setMultiboardCharWidthBase80('eng', "s", 160)
        setMultiboardCharWidthBase80('eng', "t", 206)
        setMultiboardCharWidthBase80('eng', "u", 120)
        setMultiboardCharWidthBase80('eng', "v", 144)
        setMultiboardCharWidthBase80('eng', "w", 90)
        setMultiboardCharWidthBase80('eng', "x", 131)
        setMultiboardCharWidthBase80('eng', "y", 144)
        setMultiboardCharWidthBase80('eng', "z", 144)
        setMultiboardCharWidthBase80('eng', "A", 103)
        setMultiboardCharWidthBase80('eng', "B", 120)
        setMultiboardCharWidthBase80('eng', "C", 103)
        setMultiboardCharWidthBase80('eng', "D", 96)
        setMultiboardCharWidthBase80('eng', "E", 131)
        setMultiboardCharWidthBase80('eng', "F", 160)
        setMultiboardCharWidthBase80('eng', "G", 96)
        setMultiboardCharWidthBase80('eng', "H", 90)
        setMultiboardCharWidthBase80('eng', "I", 240)
        setMultiboardCharWidthBase80('eng', "J", 240)
        setMultiboardCharWidthBase80('eng', "K", 120)
        setMultiboardCharWidthBase80('eng', "L", 131)
        setMultiboardCharWidthBase80('eng', "M", 76)
        setMultiboardCharWidthBase80('eng', "N", 90)
        setMultiboardCharWidthBase80('eng', "O", 85)
        setMultiboardCharWidthBase80('eng', "P", 120)
        setMultiboardCharWidthBase80('eng', "Q", 85)
        setMultiboardCharWidthBase80('eng', "R", 120)
        setMultiboardCharWidthBase80('eng', "S", 131)
        setMultiboardCharWidthBase80('eng', "T", 144)
        setMultiboardCharWidthBase80('eng', "U", 96)
        setMultiboardCharWidthBase80('eng', "V", 120)
        setMultiboardCharWidthBase80('eng', "W", 76)
        setMultiboardCharWidthBase80('eng', "X", 111)
        setMultiboardCharWidthBase80('eng', "Y", 120)
        setMultiboardCharWidthBase80('eng', "Z", 111)
        setMultiboardCharWidthBase80('eng', "1", 103)
        setMultiboardCharWidthBase80('eng', "2", 111)
        setMultiboardCharWidthBase80('eng', "3", 111)
        setMultiboardCharWidthBase80('eng', "4", 111)
        setMultiboardCharWidthBase80('eng', "5", 111)
        setMultiboardCharWidthBase80('eng', "6", 111)
        setMultiboardCharWidthBase80('eng', "7", 111)
        setMultiboardCharWidthBase80('eng', "8", 111)
        setMultiboardCharWidthBase80('eng', "9", 111)
        setMultiboardCharWidthBase80('eng', "0", 111)
        setMultiboardCharWidthBase80('eng', ":", 288)
        setMultiboardCharWidthBase80('eng', ";", 288)
        setMultiboardCharWidthBase80('eng', ".", 288)
        setMultiboardCharWidthBase80('eng', "#", 103)
        setMultiboardCharWidthBase80('eng', ",", 288)
        setMultiboardCharWidthBase80('eng', " ", 286) --space
        setMultiboardCharWidthBase80('eng', "'", 360)
        setMultiboardCharWidthBase80('eng', "!", 288)
        setMultiboardCharWidthBase80('eng', "$", 131)
        setMultiboardCharWidthBase80('eng', "&", 120)
        setMultiboardCharWidthBase80('eng', "/", 180)
        setMultiboardCharWidthBase80('eng', "(", 206)
        setMultiboardCharWidthBase80('eng', ")", 206)
        setMultiboardCharWidthBase80('eng', "=", 111)
        setMultiboardCharWidthBase80('eng', "?", 180)
        setMultiboardCharWidthBase80('eng', "^", 144)
        setMultiboardCharWidthBase80('eng', "<", 111)
        setMultiboardCharWidthBase80('eng', ">", 111)
        setMultiboardCharWidthBase80('eng', "-", 160)
        setMultiboardCharWidthBase80('eng', "+", 111)
        setMultiboardCharWidthBase80('eng', "*", 144)
        setMultiboardCharWidthBase80('eng', "|", 479) --2 vertical bars in a row escape to one. So you could print 960 ones in a line, 480 would display. Maybe need to adapt to this before calculating string width.
        setMultiboardCharWidthBase80('eng', "~", 144)
        setMultiboardCharWidthBase80('eng', "{", 160)
        setMultiboardCharWidthBase80('eng', "}", 160)
        setMultiboardCharWidthBase80('eng', "[", 206)
        setMultiboardCharWidthBase80('eng', "]", 206)
        setMultiboardCharWidthBase80('eng', "_", 120)
        setMultiboardCharWidthBase80('eng', "\x25", 103) --percent
        setMultiboardCharWidthBase80('eng', "\x5C", 180) --backslash
        setMultiboardCharWidthBase80('eng', "\x22", 180) --double quotation mark
        setMultiboardCharWidthBase80('eng', "\x40", 85) --at sign
        setMultiboardCharWidthBase80('eng', "\x60", 206) --Gravis (Accent)
    else
        --German font size up to patch 1.32
        setMultiboardCharWidthBase80('ger', "a", 144)
        setMultiboardCharWidthBase80('ger', "b", 144)
        setMultiboardCharWidthBase80('ger', "c", 144)
        setMultiboardCharWidthBase80('ger', "d", 131)
        setMultiboardCharWidthBase80('ger', "e", 144)
        setMultiboardCharWidthBase80('ger', "f", 240)
        setMultiboardCharWidthBase80('ger', "g", 120)
        setMultiboardCharWidthBase80('ger', "h", 144)
        setMultiboardCharWidthBase80('ger', "i", 360)
        setMultiboardCharWidthBase80('ger', "j", 288)
        setMultiboardCharWidthBase80('ger', "k", 144)
        setMultiboardCharWidthBase80('ger', "l", 360)
        setMultiboardCharWidthBase80('ger', "m", 90)
        setMultiboardCharWidthBase80('ger', "n", 144)
        setMultiboardCharWidthBase80('ger', "o", 131)
        setMultiboardCharWidthBase80('ger', "p", 131)
        setMultiboardCharWidthBase80('ger', "q", 131)
        setMultiboardCharWidthBase80('ger', "r", 206)
        setMultiboardCharWidthBase80('ger', "s", 180)
        setMultiboardCharWidthBase80('ger', "t", 206)
        setMultiboardCharWidthBase80('ger', "u", 144)
        setMultiboardCharWidthBase80('ger', "v", 131)
        setMultiboardCharWidthBase80('ger', "w", 96)
        setMultiboardCharWidthBase80('ger', "x", 144)
        setMultiboardCharWidthBase80('ger', "y", 131)
        setMultiboardCharWidthBase80('ger', "z", 144)
        setMultiboardCharWidthBase80('ger', "A", 103)
        setMultiboardCharWidthBase80('ger', "B", 131)
        setMultiboardCharWidthBase80('ger', "C", 120)
        setMultiboardCharWidthBase80('ger', "D", 111)
        setMultiboardCharWidthBase80('ger', "E", 144)
        setMultiboardCharWidthBase80('ger', "F", 180)
        setMultiboardCharWidthBase80('ger', "G", 103)
        setMultiboardCharWidthBase80('ger', "H", 103)
        setMultiboardCharWidthBase80('ger', "I", 288)
        setMultiboardCharWidthBase80('ger', "J", 240)
        setMultiboardCharWidthBase80('ger', "K", 120)
        setMultiboardCharWidthBase80('ger', "L", 144)
        setMultiboardCharWidthBase80('ger', "M", 80)
        setMultiboardCharWidthBase80('ger', "N", 103)
        setMultiboardCharWidthBase80('ger', "O", 96)
        setMultiboardCharWidthBase80('ger', "P", 144)
        setMultiboardCharWidthBase80('ger', "Q", 90)
        setMultiboardCharWidthBase80('ger', "R", 120)
        setMultiboardCharWidthBase80('ger', "S", 144)
        setMultiboardCharWidthBase80('ger', "T", 144)
        setMultiboardCharWidthBase80('ger', "U", 111)
        setMultiboardCharWidthBase80('ger', "V", 120)
        setMultiboardCharWidthBase80('ger', "W", 76)
        setMultiboardCharWidthBase80('ger', "X", 111)
        setMultiboardCharWidthBase80('ger', "Y", 120)
        setMultiboardCharWidthBase80('ger', "Z", 120)
        setMultiboardCharWidthBase80('ger', "1", 288)
        setMultiboardCharWidthBase80('ger', "2", 131)
        setMultiboardCharWidthBase80('ger', "3", 144)
        setMultiboardCharWidthBase80('ger', "4", 120)
        setMultiboardCharWidthBase80('ger', "5", 144)
        setMultiboardCharWidthBase80('ger', "6", 131)
        setMultiboardCharWidthBase80('ger', "7", 144)
        setMultiboardCharWidthBase80('ger', "8", 131)
        setMultiboardCharWidthBase80('ger', "9", 131)
        setMultiboardCharWidthBase80('ger', "0", 131)
        setMultiboardCharWidthBase80('ger', ":", 480)
        setMultiboardCharWidthBase80('ger', ";", 360)
        setMultiboardCharWidthBase80('ger', ".", 480)
        setMultiboardCharWidthBase80('ger', "#", 120)
        setMultiboardCharWidthBase80('ger', ",", 360)
        setMultiboardCharWidthBase80('ger', " ", 288) --space
        setMultiboardCharWidthBase80('ger', "'", 480)
        setMultiboardCharWidthBase80('ger', "!", 360)
        setMultiboardCharWidthBase80('ger', "$", 160)
        setMultiboardCharWidthBase80('ger', "&", 96)
        setMultiboardCharWidthBase80('ger', "/", 180)
        setMultiboardCharWidthBase80('ger', "(", 288)
        setMultiboardCharWidthBase80('ger', ")", 288)
        setMultiboardCharWidthBase80('ger', "=", 160)
        setMultiboardCharWidthBase80('ger', "?", 180)
        setMultiboardCharWidthBase80('ger', "^", 144)
        setMultiboardCharWidthBase80('ger', "<", 160)
        setMultiboardCharWidthBase80('ger', ">", 160)
        setMultiboardCharWidthBase80('ger', "-", 144)
        setMultiboardCharWidthBase80('ger', "+", 160)
        setMultiboardCharWidthBase80('ger', "*", 206)
        setMultiboardCharWidthBase80('ger', "|", 480) --2 vertical bars in a row escape to one. So you could print 960 ones in a line, 480 would display. Maybe need to adapt to this before calculating string width.
        setMultiboardCharWidthBase80('ger', "~", 144)
        setMultiboardCharWidthBase80('ger', "{", 240)
        setMultiboardCharWidthBase80('ger', "}", 240)
        setMultiboardCharWidthBase80('ger', "[", 240)
        setMultiboardCharWidthBase80('ger', "]", 288)
        setMultiboardCharWidthBase80('ger', "_", 144)
        setMultiboardCharWidthBase80('ger', "\x25", 111) --percent
        setMultiboardCharWidthBase80('ger', "\x5C", 206) --backslash
        setMultiboardCharWidthBase80('ger', "\x22", 240) --double quotation mark
        setMultiboardCharWidthBase80('ger', "\x40", 103) --at sign
        setMultiboardCharWidthBase80('ger', "\x60", 240) --Gravis (Accent)

        --English Font size up to patch 1.32
        setMultiboardCharWidthBase80('eng', "a", 144)
        setMultiboardCharWidthBase80('eng', "b", 120)
        setMultiboardCharWidthBase80('eng', "c", 131)
        setMultiboardCharWidthBase80('eng', "d", 120)
        setMultiboardCharWidthBase80('eng', "e", 131)
        setMultiboardCharWidthBase80('eng', "f", 240)
        setMultiboardCharWidthBase80('eng', "g", 120)
        setMultiboardCharWidthBase80('eng', "h", 131)
        setMultiboardCharWidthBase80('eng', "i", 360)
        setMultiboardCharWidthBase80('eng', "j", 288)
        setMultiboardCharWidthBase80('eng', "k", 144)
        setMultiboardCharWidthBase80('eng', "l", 360)
        setMultiboardCharWidthBase80('eng', "m", 80)
        setMultiboardCharWidthBase80('eng', "n", 131)
        setMultiboardCharWidthBase80('eng', "o", 120)
        setMultiboardCharWidthBase80('eng', "p", 120)
        setMultiboardCharWidthBase80('eng', "q", 120)
        setMultiboardCharWidthBase80('eng', "r", 206)
        setMultiboardCharWidthBase80('eng', "s", 160)
        setMultiboardCharWidthBase80('eng', "t", 206)
        setMultiboardCharWidthBase80('eng', "u", 131)
        setMultiboardCharWidthBase80('eng', "v", 144)
        setMultiboardCharWidthBase80('eng', "w", 90)
        setMultiboardCharWidthBase80('eng', "x", 131)
        setMultiboardCharWidthBase80('eng', "y", 144)
        setMultiboardCharWidthBase80('eng', "z", 144)
        setMultiboardCharWidthBase80('eng', "A", 103)
        setMultiboardCharWidthBase80('eng', "B", 120)
        setMultiboardCharWidthBase80('eng', "C", 103)
        setMultiboardCharWidthBase80('eng', "D", 103)
        setMultiboardCharWidthBase80('eng', "E", 131)
        setMultiboardCharWidthBase80('eng', "F", 160)
        setMultiboardCharWidthBase80('eng', "G", 103)
        setMultiboardCharWidthBase80('eng', "H", 96)
        setMultiboardCharWidthBase80('eng', "I", 288)
        setMultiboardCharWidthBase80('eng', "J", 240)
        setMultiboardCharWidthBase80('eng', "K", 120)
        setMultiboardCharWidthBase80('eng', "L", 131)
        setMultiboardCharWidthBase80('eng', "M", 76)
        setMultiboardCharWidthBase80('eng', "N", 96)
        setMultiboardCharWidthBase80('eng', "O", 85)
        setMultiboardCharWidthBase80('eng', "P", 131)
        setMultiboardCharWidthBase80('eng', "Q", 85)
        setMultiboardCharWidthBase80('eng', "R", 120)
        setMultiboardCharWidthBase80('eng', "S", 131)
        setMultiboardCharWidthBase80('eng', "T", 144)
        setMultiboardCharWidthBase80('eng', "U", 103)
        setMultiboardCharWidthBase80('eng', "V", 120)
        setMultiboardCharWidthBase80('eng', "W", 76)
        setMultiboardCharWidthBase80('eng', "X", 111)
        setMultiboardCharWidthBase80('eng', "Y", 120)
        setMultiboardCharWidthBase80('eng', "Z", 111)
        setMultiboardCharWidthBase80('eng', "1", 206)
        setMultiboardCharWidthBase80('eng', "2", 131)
        setMultiboardCharWidthBase80('eng', "3", 131)
        setMultiboardCharWidthBase80('eng', "4", 111)
        setMultiboardCharWidthBase80('eng', "5", 131)
        setMultiboardCharWidthBase80('eng', "6", 120)
        setMultiboardCharWidthBase80('eng', "7", 131)
        setMultiboardCharWidthBase80('eng', "8", 111)
        setMultiboardCharWidthBase80('eng', "9", 120)
        setMultiboardCharWidthBase80('eng', "0", 111)
        setMultiboardCharWidthBase80('eng', ":", 360)
        setMultiboardCharWidthBase80('eng', ";", 360)
        setMultiboardCharWidthBase80('eng', ".", 360)
        setMultiboardCharWidthBase80('eng', "#", 103)
        setMultiboardCharWidthBase80('eng', ",", 360)
        setMultiboardCharWidthBase80('eng', " ", 288) --space
        setMultiboardCharWidthBase80('eng', "'", 480)
        setMultiboardCharWidthBase80('eng', "!", 360)
        setMultiboardCharWidthBase80('eng', "$", 131)
        setMultiboardCharWidthBase80('eng', "&", 120)
        setMultiboardCharWidthBase80('eng', "/", 180)
        setMultiboardCharWidthBase80('eng', "(", 240)
        setMultiboardCharWidthBase80('eng', ")", 240)
        setMultiboardCharWidthBase80('eng', "=", 111)
        setMultiboardCharWidthBase80('eng', "?", 180)
        setMultiboardCharWidthBase80('eng', "^", 144)
        setMultiboardCharWidthBase80('eng', "<", 131)
        setMultiboardCharWidthBase80('eng', ">", 131)
        setMultiboardCharWidthBase80('eng', "-", 180)
        setMultiboardCharWidthBase80('eng', "+", 111)
        setMultiboardCharWidthBase80('eng', "*", 180)
        setMultiboardCharWidthBase80('eng', "|", 480) --2 vertical bars in a row escape to one. So you could print 960 ones in a line, 480 would display. Maybe need to adapt to this before calculating string width.
        setMultiboardCharWidthBase80('eng', "~", 144)
        setMultiboardCharWidthBase80('eng', "{", 240)
        setMultiboardCharWidthBase80('eng', "}", 240)
        setMultiboardCharWidthBase80('eng', "[", 240)
        setMultiboardCharWidthBase80('eng', "]", 240)
        setMultiboardCharWidthBase80('eng', "_", 120)
        setMultiboardCharWidthBase80('eng', "\x25", 103) --percent
        setMultiboardCharWidthBase80('eng', "\x5C", 180) --backslash
        setMultiboardCharWidthBase80('eng', "\x22", 206) --double quotation mark
        setMultiboardCharWidthBase80('eng', "\x40", 96) --at sign
        setMultiboardCharWidthBase80('eng', "\x60", 206) --Gravis (Accent)
    end
end
Debug.beginFile("IngameConsole")
--[[

--------------------------
----| Ingame Console |----
--------------------------

/**********************************************
* Allows you to use the following ingame commands:
* "-exec <code>" to execute any code ingame.
* "-console" to start an ingame console interpreting any further chat input as code and showing both return values of function calls and error messages. Furthermore, the print function will print
*    directly to the console after it got started. You can still look up all print messages in the F12-log.
***********************
* -------------------
* |Using the console|
* -------------------
* Any (well, most) chat input by any player after starting the console is interpreted as code and directly executed. You can enter terms (like 4+5 or just any variable name), function calls (like print("bla"))
* and set-statements (like y = 5). If the code has any return values, all of them are printed to the console. Erroneous code will print an error message.
* Chat input starting with a hyphen is being ignored by the console, i.e. neither executed as code nor printed to the console. This allows you to still use other chat commands like "-exec" without prompting errors.
***********************
* ------------------
* |Multiline-Inputs|
* ------------------
* You can prevent a chat input from being immediately executed by preceeding it with the '>' character. All lines entered this way are halted, until any line not starting with '>' is being entered.
* The first input without '>' will execute all halted lines (and itself) in one chunk.
* Example of a chat input (the console will add an additional '>' to every line):
* >function a(x)
* >return x
* end
***********************
* Note that multiline inputs don't accept pure term evaluations, e.g. the following input is not supported and will prompt an error, while the same lines would have worked as two single-line inputs:
* >x = 5
* x
***********************
* -------------------
* |Reserved Keywords|
* -------------------
* The following keywords have a reserved functionality, i.e. are direct commands for the console and will not be interpreted as code:
* - 'help'          - will show a list of all reserved keywords along very short explanations.
* - 'exit'          - will shut down the console
* - 'share'         - will share the players console with every other player, allowing others to read and write into it. Will force-close other players consoles, if they have one active.
* - 'clear'         - will clear all text from the console, except the word 'clear'
* - 'lasttrace'     - will show the stack trace of the latest error that occured within IngameConsole
* - 'show'          - will show the console, after it was accidently hidden (you can accidently hide it by showing another multiboard, while the console functionality is still up and running).
* - 'printtochat'   - will let the print function return to normal behaviour (i.e. print to the chat instead of the console).
* - 'printtoconsole'- will let the print function print to the console (which is default behaviour).
* - 'autosize on'   - will enable automatic console resize depending on the longest string in the display. This is turned on by default.
* - 'autosize off'  - will disable automatic console resize and instead linebreak long strings into multiple lines.
* - 'textlang eng'  - lets the console use english Wc3 text language font size to compute linebreaks (look in your Blizzard launcher settings to find out)
* - 'textlang ger'  - lets the console use german Wc3 text language font size to compute linebreaks (look in your Blizzard launcher settings to find out)
***********************
* --------------
* |Paste Helper|
* --------------
* @Luashine has created a tool that simplifies pasting multiple lines of code from outside Wc3 into the IngameConsole.
* This is particularly useful, when you want to execute a large chunk of testcode containing several linebreaks.
* Goto: https://github.com/Luashine/wc3-debug-console-paste-helper#readme
*
*************************************************/
--]]

----------------
--| Settings |--
----------------

---@class IngameConsole
IngameConsole = {
    --Settings
    numRows = 20                        ---@type integer Number of Rows of the console (multiboard), excluding the title row. So putting 20 here will show 21 rows, first being the title row.
    ,   autosize = true                 ---@type boolean Defines, whether the width of the main Column automatically adjusts with the longest string in the display.
    ,   currentWidth = 0.5              ---@type number Current and starting Screen Share of the console main column.
    ,   mainColMinWidth = 0.3           ---@type number Minimum Screen share of the console main column.
    ,   mainColMaxWidth = 0.8           ---@type number Maximum Scren share of the console main column.
    ,   tsColumnWidth = 0.06            ---@type number Screen Share of the Timestamp Column
    ,   linebreakBuffer = 0.008         ---@type number Screen Share that is added to longest string in display to calculate the screen share for the console main column. Compensates for the small inaccuracy of the String Width function.
    ,   maxLinebreaks = 8               ---@type integer Defines the maximum amount of linebreaks, before the remaining output string will be cut and not further displayed.
    ,   printToConsole = true           ---@type boolean defines, if the print function should print to the console or to the chat
    ,   sharedConsole = false           ---@type boolean defines, if the console is displayed to each player at the same time (accepting all players input) or if all players much start their own console.
    ,   showTraceOnError = false        ---@type boolean defines, if the console shows a trace upon printing errors. Usually not too useful within console, because you have just initiated the erroneous call.
    ,   textLanguage = 'eng'            ---@type string text language of your Wc3 installation, which influences font size (look in the settings of your Blizzard launcher). Currently only supports 'eng' and 'ger'.
    ,   colors = {
        timestamp = "bbbbbb"            ---@type string Timestamp Color
        ,   singleLineInput = "ffffaa"  ---@type string Color to be applied to single line console inputs
        ,   multiLineInput = "ffcc55"   ---@type string Color to be applied to multi line console inputs
        ,   returnValue = "00ffff"      ---@type string Color applied to return values
        ,   error = "ff5555"            ---@type string Color to be applied to errors resulting of function calls
        ,   keywordInput = "ff00ff"     ---@type string Color to be applied to reserved keyword inputs (console reserved keywords)
        ,   info = "bbbbbb"             ---@type string Color to be applied to info messages from the console itself (for instance after creation or after printrestore)
    }
    --Privates
    ,   numCols = 2                     ---@type integer Number of Columns of the console (multiboard). Adjusting this requires further changes on code base.
    ,   player = nil                    ---@type player player for whom the console is being created
    ,   currentLine = 0                 ---@type integer Current Output Line of the console.
    ,   inputload = ''                  ---@type string Input Holder for multi-line-inputs
    ,   output = {}                     ---@type string[] Array of all output strings
    ,   outputTimestamps = {}           ---@type string[] Array of all output string timestamps
    ,   outputWidths = {}               ---@type number[] remembers all string widths to allow for multiboard resize
    ,   trigger = nil                   ---@type trigger trigger processing all inputs during console lifetime
    ,   multiboard = nil                ---@type multiboard
    ,   timer = nil                     ---@type timer gets started upon console creation to measure timestamps
    ,   errorHandler = nil              ---@type fun(errorMsg:string):string error handler to be used within xpcall. We create one per console to make it compatible with console-specific settings.
    ,   lastTrace = ''                  ---@type string trace of last error occured within console. To be printed via reserved keyword "lasttrace"
    --Statics
    ,   keywords = {}                   ---@type table<string,function> saves functions to be executed for all reserved keywords
    ,   playerConsoles = {}             ---@type table<player,IngameConsole> Consoles currently being active. up to one per player.
    ,   originalPrint = print           ---@type function original print function to restore, after the console gets closed.
}
IngameConsole.__index = IngameConsole
IngameConsole.__name = 'IngameConsole'

------------------------
--| Console Creation |--
------------------------

---Creates and opens up a new console.
---@param consolePlayer player player for whom the console is being created
---@return IngameConsole
function IngameConsole.create(consolePlayer)
    local new = {} ---@type IngameConsole
    setmetatable(new, IngameConsole)
    ---setup Object data
    new.player = consolePlayer
    new.output = {}
    new.outputTimestamps = {}
    new.outputWidths = {}
    --Timer
    new.timer = CreateTimer()
    TimerStart(new.timer, 3600., true, nil) --just to get TimeElapsed for printing Timestamps.
    --Trigger to be created after short delay, because otherwise it would fire on "-console" input immediately and lead to stack overflow.
    new:setupTrigger()
    --Multiboard
    new:setupMultiboard()
    --Create own error handler per console to be compatible with console-specific settings
    new:setupErrorHandler()
    --Share, if settings say so
    if IngameConsole.sharedConsole then
        new:makeShared() --we don't have to exit other players consoles, because we look for the setting directly in the class and there just logically can't be other active consoles.
    end
    --Welcome Message
    new:out('info', 0, false, "Console started. Any further chat input will be executed as code, except when beginning with \x22-\x22.")
    return new
end

---Creates the multiboard used for console display.
function IngameConsole:setupMultiboard()
    self.multiboard = CreateMultiboard()
    MultiboardSetRowCount(self.multiboard, self.numRows + 1) --title row adds 1
    MultiboardSetColumnCount(self.multiboard, self.numCols)
    MultiboardSetTitleText(self.multiboard, "Console")
    local mbitem
    for col = 1, self.numCols do
        for row = 1, self.numRows + 1 do --Title row adds 1
            mbitem = MultiboardGetItem(self.multiboard, row -1, col -1)
            MultiboardSetItemStyle(mbitem, true, false)
            MultiboardSetItemValueColor(mbitem, 255, 255, 255, 255)    -- Colors get applied via text color code
            MultiboardSetItemWidth(mbitem, (col == 1 and self.tsColumnWidth) or self.currentWidth )
            MultiboardReleaseItem(mbitem)
        end
    end
    mbitem = MultiboardGetItem(self.multiboard, 0, 0)
    MultiboardSetItemValue(mbitem, "|cffffcc00Timestamp|r")
    MultiboardReleaseItem(mbitem)
    mbitem = MultiboardGetItem(self.multiboard, 0, 1)
    MultiboardSetItemValue(mbitem, "|cffffcc00Line|r")
    MultiboardReleaseItem(mbitem)
    self:showToOwners()
end

---Creates the trigger that responds to chat events.
function IngameConsole:setupTrigger()
    self.trigger = CreateTrigger()
    TriggerRegisterPlayerChatEvent(self.trigger, self.player, "", false) --triggers on any input of self.player
    TriggerAddCondition(self.trigger, Condition(function() return string.sub(GetEventPlayerChatString(),1,1) ~= '-' end)) --console will not react to entered stuff starting with '-'. This still allows to use other chat orders like "-exec".
    TriggerAddAction(self.trigger, function() self:processInput(GetEventPlayerChatString()) end)
end

---Creates an Error Handler to be used by xpcall below.
---Adds stack trace plus formatting to the message.
function IngameConsole:setupErrorHandler()
    self.errorHandler = function(errorMsg)
        errorMsg = Debug.getLocalErrorMsg(errorMsg)
        local _, tracePiece, lastFile = nil, "", errorMsg:match("^.-:") or "<unknown>" -- errors on objects created within Ingame Console don't have a file and linenumber. Consider "x = {}; x[nil] = 5".
        local fullMsg = errorMsg .. "\nTraceback (most recent call first):\n" .. (errorMsg:match("^.-:\x25d+") or "<unknown>")
        --Get Stack Trace. Starting at depth 5 ensures that "error", "messageHandler", "xpcall" and the input error message are not included.
        for loopDepth = 5, 50 do --get trace on depth levels up to 50
            ---@diagnostic disable-next-line: cast-local-type, assign-type-mismatch
            _, tracePiece = pcall(error, "", loopDepth) ---@type boolean, string
            tracePiece = Debug.getLocalErrorMsg(tracePiece)
            if #tracePiece > 0 then --some trace pieces can be empty, but there can still be valid ones beyond that
                fullMsg = fullMsg .. " <- " .. ((tracePiece:match("^.-:") == lastFile) and tracePiece:match(":\x25d+"):sub(2,-1) or tracePiece:match("^.-:\x25d+"))
                lastFile = tracePiece:match("^.-:")
            end
        end
        self.lastTrace = fullMsg
        return "ERROR: " .. (self.showTraceOnError and fullMsg or errorMsg)
    end
end

---Shares this console with all players.
function IngameConsole:makeShared()
    local player
    for i = 0, GetBJMaxPlayers() -1 do
        player = Player(i)
        if (GetPlayerSlotState(player) == PLAYER_SLOT_STATE_PLAYING) and (IngameConsole.playerConsoles[player] ~= self) then --second condition ensures that the player chat event is not added twice for the same player.
            IngameConsole.playerConsoles[player] = self
            TriggerRegisterPlayerChatEvent(self.trigger, player, "", false) --triggers on any input
        end
    end
    self.sharedConsole = true
end

---------------------
--|      In       |--
---------------------

---Processes a chat string. Each input will be printed. Incomplete multiline-inputs will be halted until completion. Completed inputs will be converted to a function and executed. If they have an output, it will be printed.
---@param inputString string
function IngameConsole:processInput(inputString)
    --if the input is a reserved keyword, conduct respective actions and skip remaining actions.
    if IngameConsole.keywords[inputString] then --if the input string is a reserved keyword
        self:out('keywordInput', 1, false, inputString)
        IngameConsole.keywords[inputString](self) --then call the method with the same name. IngameConsole.keywords["exit"](self) is just self.keywords:exit().
        return
    end
    --if the input is a multi-line-input, queue it into the string buffer (inputLoad), but don't yet execute anything
    if string.sub(inputString, 1, 1) == '>' then --multiLineInput
        inputString = string.sub(inputString, 2, -1)
        self:out('multiLineInput',2, false, inputString)
        self.inputload = self.inputload .. inputString .. '\r' --carriage return
    else --if the input is either singleLineInput OR the last line of multiLineInput, execute the whole thing.
        self:out(self.inputload == '' and 'singleLineInput' or 'multiLineInput', 1, false, inputString)
        self.inputload = self.inputload .. inputString
        local loadedFunc, errorMsg = load("return " .. self.inputload) --adds return statements, if possible (works for term statements)
        if loadedFunc == nil then
            loadedFunc, errorMsg = load(self.inputload)
        end
        self.inputload = '' --empty inputload before execution of pcall. pcall can break (rare case, can for example be provoked with metatable.__tostring = {}), which would corrupt future console inputs.
        --manually catch case, where the input did not define a proper Lua statement (i.e. loadfunc is nil)
        local results = loadedFunc and table.pack(xpcall(loadedFunc, self.errorHandler)) or {false, "Input is not a valid Lua-statement: " .. errorMsg}
        --output error message (unsuccessful case) or return values (successful case)
        if not results[1] then --results[1] is the error status that pcall always returns. False stands for: error occured.
            self:out('error', 0, true, results[2]) -- second result of pcall is the error message in case an error occured
        elseif results.n > 1 then --Check, if there was at least one valid output argument. We check results.n instead of results[2], because we also get nil as a proper return value this way.
            self:out('returnValue', 0, true, table.unpack(results, 2, results.n))
        end
    end
end

----------------------
--|      Out       |--
----------------------

-- split color codes, split linebreaks, print lines separately, print load-errors, update string width, update text, error handling with stack trace.

---Duplicates Color coding around linebreaks to make each line printable separately.
---Operates incorrectly on lookalike color codes invalidated by preceeding escaped vertical bar (like "||cffffcc00bla|r").
---Also operates incorrectly on multiple color codes, where the first is missing the end sequence (like "|cffffcc00Hello |cff0000ffWorld|r")
---@param inputString string
---@return string, integer
function IngameConsole.spreadColorCodes(inputString)
    local replacementTable = {} --remembers all substrings to be replaced and their replacements.
    for foundInstance, color in inputString:gmatch("((|c\x25x\x25x\x25x\x25x\x25x\x25x\x25x\x25x).-|r)") do
        replacementTable[foundInstance] = foundInstance:gsub("(\r?\n)", "|r\x251" .. color)
    end
    return inputString:gsub("((|c\x25x\x25x\x25x\x25x\x25x\x25x\x25x\x25x).-|r)", replacementTable)
end

---Concatenates all inputs to one string, spreads color codes around line breaks and prints each line to the console separately.
---@param colorTheme? '"timestamp"'| '"singleLineInput"' | '"multiLineInput"' | '"result"' | '"keywordInput"' | '"info"' | '"error"' | '"returnValue"' Decides about the color to be applied. Currently accepted: 'timestamp', 'singleLineInput', 'multiLineInput', 'result', nil. (nil equals no colorTheme, i.e. white color)
---@param numIndentations integer Number of '>' chars that shall preceed the output
---@param hideTimestamp boolean Set to false to hide the timestamp column and instead show a "->" symbol.
---@param ... any the things to be printed in the console.
function IngameConsole:out(colorTheme, numIndentations, hideTimestamp, ...)
    local inputs = table.pack(...)
    for i = 1, inputs.n do
        inputs[i] = tostring(inputs[i]) --apply tostring on every input param in preparation for table.concat
    end
    --Concatenate all inputs (4-space-separated)
    local printOutput = table.concat(inputs, '    ', 1, inputs.n)
    printOutput = printOutput:find("(\r?\n)") and IngameConsole.spreadColorCodes(printOutput) or printOutput
    local substrStart, substrEnd = 1, 1
    local numLinebreaks, completePrint = 0, true
    repeat
        substrEnd = (printOutput:find("(\r?\n)", substrStart) or 0) - 1
        numLinebreaks, completePrint = self:lineOut(colorTheme, numIndentations, hideTimestamp, numLinebreaks, printOutput:sub(substrStart, substrEnd))
        hideTimestamp = true
        substrStart = substrEnd + 2
    until substrEnd == -1 or numLinebreaks > self.maxLinebreaks
    if substrEnd ~= -1 or not completePrint then
        self:lineOut('info', 0, false, 0, "Previous value not entirely printed after exceeding maximum number of linebreaks. Consider adjusting 'IngameConsole.maxLinebreaks'.")
    end
    self:updateMultiboard()
end

---Prints the given string to the console with the specified colorTheme and the specified number of indentations.
---Only supports one-liners (no \n) due to how multiboards work. Will add linebreaks though, if the one-liner doesn't fit into the given multiboard space.
---@param colorTheme? '"timestamp"'| '"singleLineInput"' | '"multiLineInput"' | '"result"' | '"keywordInput"' | '"info"' | '"error"' | '"returnValue"' Decides about the color to be applied. Currently accepted: 'timestamp', 'singleLineInput', 'multiLineInput', 'result', nil. (nil equals no colorTheme, i.e. white color)
---@param numIndentations integer Number of greater '>' chars that shall preceed the output
---@param hideTimestamp boolean Set to false to hide the timestamp column and instead show a "->" symbol.
---@param numLinebreaks integer
---@param printOutput string the line to be printed in the console.
---@return integer numLinebreaks, boolean hasPrintedEverything returns true, if everything could be printed. Returns false otherwise (can happen for very long strings).
function IngameConsole:lineOut(colorTheme, numIndentations, hideTimestamp, numLinebreaks, printOutput)
    --add preceeding greater chars
    printOutput = ('>'):rep(numIndentations) .. printOutput
    --Print a space instead of the empty string. This allows the console to identify, if the string has already been fully printed (see while-loop below).
    if printOutput == '' then
        printOutput = ' '
    end
    --Compute Linebreaks.
    local linebreakWidth = ((self.autosize and self.mainColMaxWidth) or self.currentWidth )
    local partialOutput = nil
    local maxPrintableCharPosition
    local printWidth
    while string.len(printOutput) > 0  and numLinebreaks <= self.maxLinebreaks do --break, if the input string has reached length 0 OR when the maximum number of linebreaks would be surpassed.
        --compute max printable substring (in one multiboard line)
        maxPrintableCharPosition, printWidth = IngameConsole.getLinebreakData(printOutput, linebreakWidth - self.linebreakBuffer, self.textLanguage)
        --adds timestamp to the first line of any output
        if numLinebreaks == 0 then
            partialOutput = printOutput:sub(1, numIndentations) .. ((IngameConsole.colors[colorTheme] and "|cff" .. IngameConsole.colors[colorTheme] .. printOutput:sub(numIndentations + 1, maxPrintableCharPosition) .. "|r") or printOutput:sub(numIndentations + 1, maxPrintableCharPosition)) --Colorize the output string, if a color theme was specified. IngameConsole.colors[colorTheme] can be nil.
            table.insert(self.outputTimestamps, "|cff" .. IngameConsole.colors['timestamp'] .. ((hideTimestamp and '            ->') or IngameConsole.formatTimerElapsed(TimerGetElapsed(self.timer))) .. "|r")
        else
            partialOutput = (IngameConsole.colors[colorTheme] and "|cff" .. IngameConsole.colors[colorTheme] .. printOutput:sub(1, maxPrintableCharPosition) .. "|r") or printOutput:sub(1, maxPrintableCharPosition) --Colorize the output string, if a color theme was specified. IngameConsole.colors[colorTheme] can be nil.
            table.insert(self.outputTimestamps, '            ..') --need a dummy entry in the timestamp list to make it line-progress with the normal output.
        end
        numLinebreaks = numLinebreaks + 1
        --writes output string and width to the console tables.
        table.insert(self.output, partialOutput)
        table.insert(self.outputWidths, printWidth + self.linebreakBuffer) --remember the Width of this printed string to adjust the multiboard size in case. 0.5 percent is added to avoid the case, where the multiboard width is too small by a tiny bit, thus not showing some string without spaces.
        --compute remaining string to print
        printOutput = string.sub(printOutput, maxPrintableCharPosition + 1, -1) --remaining string until the end. Returns empty string, if there is nothing left
    end
    self.currentLine = #self.output
    return numLinebreaks, string.len(printOutput) == 0 --printOutput is the empty string, if and only if everything has been printed
end

---Lets the multiboard show the recently printed lines.
function IngameConsole:updateMultiboard()
    local startIndex = math.max(self.currentLine - self.numRows, 0) --to be added to loop counter to get to the index of output table to print
    local outputIndex = 0
    local maxWidth = 0.
    local mbitem
    for i = 1, self.numRows do --doesn't include title row (index 0)
        outputIndex = i + startIndex
        mbitem = MultiboardGetItem(self.multiboard, i, 0)
        MultiboardSetItemValue(mbitem, self.outputTimestamps[outputIndex] or '')
        MultiboardReleaseItem(mbitem)
        mbitem = MultiboardGetItem(self.multiboard, i, 1)
        MultiboardSetItemValue(mbitem, self.output[outputIndex] or '')
        MultiboardReleaseItem(mbitem)
        maxWidth = math.max(maxWidth, self.outputWidths[outputIndex] or 0.) --looping through non-defined widths, so need to coalesce with 0
    end
    --Adjust Multiboard Width, if necessary.
    maxWidth = math.min(math.max(maxWidth, self.mainColMinWidth), self.mainColMaxWidth)
    if self.autosize and self.currentWidth ~= maxWidth then
        self.currentWidth = maxWidth
        for i = 1, self.numRows +1 do
            mbitem = MultiboardGetItem(self.multiboard, i-1, 1)
            MultiboardSetItemWidth(mbitem, maxWidth)
            MultiboardReleaseItem(mbitem)
        end
        self:showToOwners() --reshow multiboard to update item widths on the frontend
    end
end

---Shows the multiboard to all owners (one or all players)
function IngameConsole:showToOwners()
    if self.sharedConsole or GetLocalPlayer() == self.player then
        MultiboardDisplay(self.multiboard, true)
        MultiboardMinimize(self.multiboard, false)
    end
end

---Formats the elapsed time as "mm: ss. hh" (h being a hundreds of a sec)
function IngameConsole.formatTimerElapsed(elapsedInSeconds)
    return string.format("\x2502d: \x2502.f. \x2502.f", elapsedInSeconds // 60, math.fmod(elapsedInSeconds, 60.) // 1, math.fmod(elapsedInSeconds, 1) * 100)
end

---Computes the max printable substring for a given string and a given linebreakWidth (regarding a single line of console).
---Returns both the substrings last char position and its total width in the multiboard.
---@param stringToPrint string the string supposed to be printed in the multiboard console.
---@param linebreakWidth number the maximum allowed width in one line of the console, before a string must linebreak
---@param textLanguage string 'ger' or 'eng'
---@return integer maxPrintableCharPosition, number printWidth
function IngameConsole.getLinebreakData(stringToPrint, linebreakWidth, textLanguage)
    local loopWidth = 0.
    local bytecodes = table.pack(string.byte(stringToPrint, 1, -1))
    for i = 1, bytecodes.n do
        loopWidth = loopWidth + string.charMultiboardWidth(bytecodes[i], textLanguage)
        if loopWidth > linebreakWidth then
            return i-1, loopWidth - string.charMultiboardWidth(bytecodes[i], textLanguage)
        end
    end
    return bytecodes.n, loopWidth
end

-------------------------
--| Reserved Keywords |--
-------------------------

---Exits the Console
---@param self IngameConsole
function IngameConsole.keywords.exit(self)
    DestroyMultiboard(self.multiboard)
    DestroyTrigger(self.trigger)
    DestroyTimer(self.timer)
    IngameConsole.playerConsoles[self.player] = nil
    if next(IngameConsole.playerConsoles) == nil then --set print function back to original, when no one has an active console left.
        print = IngameConsole.originalPrint
    end
end

---Lets the console print to chat
---@param self IngameConsole
function IngameConsole.keywords.printtochat(self)
    self.printToConsole = false
    self:out('info', 0, false, "The print function will print to the normal chat.")
end

---Lets the console print to itself (default)
---@param self IngameConsole
function IngameConsole.keywords.printtoconsole(self)
    self.printToConsole = true
    self:out('info', 0, false, "The print function will print to the console.")
end

---Shows the console in case it was hidden by another multiboard before
---@param self IngameConsole
function IngameConsole.keywords.show(self)
    self:showToOwners() --might be necessary to do, if another multiboard has shown up and thereby hidden the console.
    self:out('info', 0, false, "Console is showing.")
end

---Prints all available reserved keywords plus explanations.
---@param self IngameConsole
function IngameConsole.keywords.help(self)
    self:out('info', 0, false, "The Console currently reserves the following keywords:")
    self:out('info', 0, false, "'help' shows the text you are currently reading.")
    self:out('info', 0, false, "'exit' closes the console.")
    self:out('info', 0, false, "'lasttrace' shows the stack trace of the latest error that occured within IngameConsole.")
    self:out('info', 0, false, "'share' allows other players to read and write into your console, but also force-closes their own consoles.")
    self:out('info', 0, false, "'clear' clears all text from the console.")
    self:out('info', 0, false, "'show' shows the console. Sensible to use, when displaced by another multiboard.")
    self:out('info', 0, false, "'printtochat' lets Wc3 print text to normal chat again.")
    self:out('info', 0, false, "'printtoconsole' lets Wc3 print text to the console (default).")
    self:out('info', 0, false, "'autosize on' enables automatic console resize depending on the longest line in the display.")
    self:out('info', 0, false, "'autosize off' retains the current console size.")
    self:out('info', 0, false, "'textlang eng' will use english text installation font size to compute linebreaks (default).")
    self:out('info', 0, false, "'textlang ger' will use german text installation font size to compute linebreaks.")
    self:out('info', 0, false, "Preceeding a line with '>' prevents immediate execution, until a line not starting with '>' has been entered.")
end

---Clears the display of the console.
---@param self IngameConsole
function IngameConsole.keywords.clear(self)
    self.output = {}
    self.outputTimestamps = {}
    self.outputWidths = {}
    self.currentLine = 0
    self:out('keywordInput', 1, false, 'clear') --we print 'clear' again. The keyword was already printed by self:processInput, but cleared immediately after.
end

---Shares the console with other players in the same game.
---@param self IngameConsole
function IngameConsole.keywords.share(self)
    for _, console in pairs(IngameConsole.playerConsoles) do
        if console ~= self then
            IngameConsole.keywords['exit'](console) --share was triggered during console runtime, so there potentially are active consoles of others players that need to exit.
        end
    end
    self:makeShared()
    self:showToOwners() --showing it to the other players.
    self:out('info', 0,false, "The console of player " .. GetConvertedPlayerId(self.player) .. " is now shared with all players.")
end

---Enables auto-sizing of console (will grow and shrink together with text size)
---@param self IngameConsole
IngameConsole.keywords["autosize on"] = function(self)
    self.autosize = true
    self:out('info', 0,false, "The console will now change size depending on its content.")
end

---Disables auto-sizing of console
---@param self IngameConsole
IngameConsole.keywords["autosize off"] = function(self)
    self.autosize = false
    self:out('info', 0,false, "The console will retain the width that it currently has.")
end

---Lets linebreaks be computed by german font size
---@param self IngameConsole
IngameConsole.keywords["textlang ger"] = function(self)
    self.textLanguage = 'ger'
    self:out('info', 0,false, "Linebreaks will now compute with respect to german text installation font size.")
end

---Lets linebreaks be computed by english font size
---@param self IngameConsole
IngameConsole.keywords["textlang eng"] = function(self)
    self.textLanguage = 'eng'
    self:out('info', 0,false, "Linebreaks will now compute with respect to english text installation font size.")
end

---Prints the stack trace of the latest error that occured within IngameConsole.
---@param self IngameConsole
IngameConsole.keywords["lasttrace"] = function(self)
    self:out('error', 0,false, self.lastTrace)
end

--------------------
--| Main Trigger |--
--------------------

do
    --Actions to be executed upon typing -exec
    local function execCommand_Actions()
        local input = string.sub(GetEventPlayerChatString(),7,-1)
        print("Executing input: |cffffff44" .. input .. "|r")
        --try preceeding the input by a return statement (preparation for printing below)
        local loadedFunc, errorMsg = load("return ".. input)
        if not loadedFunc then --if that doesn't produce valid code, try without return statement
            loadedFunc, errorMsg = load(input)
        end
        --execute loaded function in case the string defined a valid function. Otherwise print error.
        if errorMsg then
            print("|cffff5555Invalid Lua-statement: " .. Debug.getLocalErrorMsg(errorMsg) .. "|r")
        else
            ---@diagnostic disable-next-line: param-type-mismatch
            local results = table.pack(Debug.try(loadedFunc))
            if results[1] ~= nil or results.n > 1 then
                for i = 1, results.n do
                    results[i] = tostring(results[i])
                end
                --concatenate all function return values to one colorized string
                print("|cff00ffff" .. table.concat(results, '    ', 1, results.n) .. "|r")
            end
        end
    end

    local function execCommand_Condition()
        return string.sub(GetEventPlayerChatString(), 1, 6) == "-exec "
    end

    local function startIngameConsole()
        --if the triggering player already has a console, show that console and stop executing further actions
        if IngameConsole.playerConsoles[GetTriggerPlayer()] then
            IngameConsole.playerConsoles[GetTriggerPlayer()]:showToOwners()
            return
        end
        --create Ingame Console object
        IngameConsole.playerConsoles[GetTriggerPlayer()] = IngameConsole.create(GetTriggerPlayer())
        --overwrite print function
        print = function(...)
            IngameConsole.originalPrint(...) --the new print function will also print "normally", but clear the text immediately after. This is to add the message to the F12-log.
            if IngameConsole.playerConsoles[GetLocalPlayer()] and IngameConsole.playerConsoles[GetLocalPlayer()].printToConsole then
                ClearTextMessages() --clear text messages for all players having an active console
            end
            for player, console in pairs(IngameConsole.playerConsoles) do
                if console.printToConsole and (player == console.player) then --player == console.player ensures that the console only prints once, even if the console was shared among all players
                    console:out(nil, 0, false, ...)
                end
            end
        end
    end

    ---Creates the triggers listening to "-console" and "-exec" chat input.
    ---Being executed within DebugUtils (MarkGameStart overwrite).
    function IngameConsole.createTriggers()
        --Exec
        local execTrigger = CreateTrigger()
        TriggerAddCondition(execTrigger, Condition(execCommand_Condition))
        TriggerAddAction(execTrigger, execCommand_Actions)
        --Real Console
        local consoleTrigger = CreateTrigger()
        TriggerAddAction(consoleTrigger, startIngameConsole)
        --Events
        for i = 0, GetBJMaxPlayers() -1 do
            TriggerRegisterPlayerChatEvent(execTrigger, Player(i), "-exec ", false)
            TriggerRegisterPlayerChatEvent(consoleTrigger, Player(i), "-console", true)
        end
    end
end
Debug.endFile()
if Debug then Debug.beginFile "Total Initialization" end
--[[——————————————————————————————————————————————————————
    Total Initialization version 5.3
    Created by: Bribe
    Contributors: Eikonium, HerlySQR, Tasyen, Luashine, Forsakn
    Inspiration: Almia, ScorpioT1000, Troll-Brain
————————————————————————————————————————————————————————————]]

---Calls the user's initialization function during the map's loading process. The first argument should either be the init function,
---or it should be the string to give the initializer a name (works similarly to a module name/identically to a vJass library name).
---
---To use requirements, call `Require.strict "LibraryName"` or `Require.optional "LibraryName"`. Alternatively, the OnInit callback
---function can take the `Require` table as a single parameter: `OnInit(function(import) import.strict "ThisIsTheSameAsRequire" end)`.
---
-- - `OnInit.global` or just `OnInit` is called after InitGlobals and is the standard point to initialize.
-- - `OnInit.trig` is called after InitCustomTriggers, and is useful for removing hooks that should only apply to GUI events.
-- - `OnInit.map` is the last point in initialization before the loading screen is completed.
-- - `OnInit.final` occurs immediately after the loading screen has disappeared, and the game has started.
---@class OnInit
--
--Simple Initialization without declaring a library name:
---@overload async fun(initCallback: Initializer.Callback)
--
--Advanced initialization with a library name and an optional third argument to signal to Eikonium's DebugUtils that the file has ended.
---@overload async fun(libraryName: string, initCallback: Initializer.Callback, debugLineNum?: integer)
--
--A way to yield your library to allow other libraries in the same initialization sequence to load, then resume once they have loaded.
---@overload async fun(customInitializerName: string)
--
-- `OnInit.module` will only call the OnInit function if the module is required by another resource, rather than being called at a pre-
-- specified point in the loading process. It works similarly to Go, in that including modules in your map that are not actually being
-- required will throw an error message.
---@field module async fun(moduleName: string, initCallback: Initializer.Callback, debugLineNum?: integer)
--
---@field library async fun(initList: table|string, userFunc: function)
OnInit = {}

---@alias Initializer.Callback fun(require?: function):any?

---@generic string
---@alias Requirement async fun(reqName:`string`, source?: table):string

-- `Require` will yield the calling coroutine until the requirement exists. This can be used on named `OnInit` resources, or on normal
-- global variables. Due to the way Sumneko's syntax highlighter works, the return value will only be linted for defined @class objects.
--
-- `Require` only works from within a yieldable coroutine during the map loading process. It is intended to be called from within an
-- `OnInit` callback function.
--
-- Syntax for strict requirements that throw errors if not found: `Require.strict "SomeLibrary"`
--
-- Syntax for requirements that give up if the required library or variable is not found: `Require.optional "SomeLibrary"`
--
---@class Require: { [string]: Requirement }
--
---@field strict Requirement
Require = {}
do
    local library = {} --You can change this to false if you don't use `Require` nor the `OnInit.library` API.

    --CONFIGURABLE LEGACY API FUNCTION:
    local function assignLegacyAPI(_ENV, OnInit)
        local _ENV = _ENV --Needed to fix a bug in the Lua Language Server. Detailed here: https://github.com/sumneko/lua-language-server/issues/1715
        OnGlobalInit = OnInit; OnTrigInit = OnInit.trig; OnMapInit = OnInit.map; OnGameStart = OnInit.final              --Global Initialization Lite API
        --OnMainInit = OnInit.main; OnLibraryInit = OnInit.library; OnGameInit = OnInit.final                            --short-lived experimental API
        --onGlobalInit = OnInit; onTriggerInit = OnInit.trig; onInitialization = OnInit.map; onGameStart = OnInit.final  --original Global Initialization API
        --OnTriggerInit = OnInit.trig; OnInitialization = OnInit.map                                                     --Forsakn's Ordered Indices API
    end
    --END CONFIGURABLES

    local _G, rawget, insert = _G, rawget, table.insert

    local initFuncQueue = {}
    ---@type fun(name: string, continue?: function)
    local function runInitializers(name, continue)
        if initFuncQueue[name] then
            for _,func in ipairs(initFuncQueue[name]) do
                coroutine.wrap(func)(Require)
            end
            initFuncQueue[name] = nil
        end
        if library  then library:resume() end
        if continue then continue()       end
    end
    do
        ---@type fun(hookName: string, continue?: function)
        local function hook(hookName, continue)
            local hookedFunc = rawget(_G, hookName)
            if hookedFunc then
                rawset(_G, hookName,
                    function()
                        hookedFunc()
                        runInitializers(hookName, continue)
                    end
                )
            else
                runInitializers(hookName, continue)
            end
        end
        hook("InitGlobals", function()
            hook("InitCustomTriggers", function()
                hook("RunInitializationTriggers")
            end)
        end)
        hook("MarkGameStarted", function()
            if library then
                for _,func in ipairs(library.queuedInitializerList) do
                    func(nil, true) --run errors for missing requirements.
                end
                for _,func in pairs(library.yieldedModuleMatrix) do
                    func(true) --run errors for modules that aren't required.
                end
            end
            OnInit=nil;Require=nil ---@diagnostic disable-line
        end)
    end
    ---@type fun(initName: string, libraryName: string|Initializer.Callback, func?: Initializer.Callback, debugLineNum?: integer, incDebugLevel?: boolean)
    local function addUserFunc(initName, libraryName, func, debugLineNum, incDebugLevel)
        if not func then
            func = libraryName
        else
            assert(type(libraryName)=="string")
            if debugLineNum and Debug then
                Debug.beginFile(libraryName, incDebugLevel and 7 or 6)
                Debug.data.sourceMap[#Debug.data.sourceMap].lastLine = debugLineNum
            end
            if library then
                func = library:create(libraryName, func)
            end
        end
        assert(type(func) == "function") ---@cast func Initializer.Callback
       
        initFuncQueue[initName] = initFuncQueue[initName] or {}
        insert(initFuncQueue[initName], func)

        if initName == "root" or initName == "module" then
            runInitializers(initName)
        end
    end

    ---@type fun(name:string): async fun(libraryName: string, initCallback: Initializer.Callback, debugLineNum?: integer)
    ---@overload fun(name:string): async fun(initCallback: Initializer.Callback)
    local function createInit(name)
        return function(libraryNameOrInitFunc, userInitFunc, debugLineNum, incDebugLevel) ---@diagnostic disable-line: redundant-parameter
            addUserFunc(name, libraryNameOrInitFunc, userInitFunc, debugLineNum, incDebugLevel)
        end
    end
    OnInit.global = createInit "InitGlobals"                -- Called after InitGlobals, and is the standard point to initialize.
    OnInit.trig   = createInit "InitCustomTriggers"         -- Called after InitCustomTriggers, and is useful for removing hooks that should only apply to GUI events.   
    OnInit.map    = createInit "RunInitializationTriggers"  -- Called last in the script's loading screen sequence. Runs after the GUI "Map Initialization" events have run.
    OnInit.final  = createInit "MarkGameStarted"            -- Called immediately after the loading screen has disappeared, and the game has started.

    setmetatable(OnInit, {__call = function(self, libraryNameOrInitFunc, userInitFunc, debugLineNum)
        if userInitFunc or type(libraryNameOrInitFunc)=="function" then
            self.global(libraryNameOrInitFunc, userInitFunc, debugLineNum, true) --Calling OnInit directly defaults to OnInit.global (AKA OnGlobalInit)
        elseif library then
            library:declare(libraryNameOrInitFunc) --API handler for OnInit "Custom initializer"
        else
            error("Bad OnInit args: "..tostring(libraryNameOrInitFunc) .. ", " .. tostring(userInitFunc))
        end
    end})

    do --if you don't need the initializers for "root", "config" and "main", you can delete this do...end block.
        local gmt = getmetatable(_G) or getmetatable(setmetatable(_G, {}))
        local rawIndex = gmt.__newindex or rawset
        local newIndex
        function newIndex(g, key, val)
            if key == "main" or key == "config" then
                if key == "main" then
                    runInitializers "root"
                end
                rawIndex(g, key, function()
                    if key == "config" then
                        val()
                    elseif gmt.__newindex == newIndex then
                        gmt.__newindex = rawIndex --restore the original __newindex if no further hooks on __newindex exist.
                    end
                    runInitializers(key)
                    if key == "main" then val() end
                end)
            else
                rawIndex(g, key, val)
            end
        end
        gmt.__newindex = newIndex
        OnInit.root    = createInit "root"   -- Runs immediately during the Lua root, but is yieldable (allowing requirements) and pcalled.
        OnInit.config  = createInit "config" -- Runs when "config" is called. Credit to @Luashine: https://www.hiveworkshop.com/threads/inject-main-config-from-we-trigger-code-like-jasshelper.338201/
        OnInit.main    = createInit "main"   -- Runs when "main" is called. Idea from @Tasyen: https://www.hiveworkshop.com/threads/global-initialization.317099/post-3374063
    end
    if library then
        library.queuedInitializerList   = {}
        library.customDeclarationList   = {}
        library.yieldedModuleMatrix     = {}
        library.moduleValueMatrix       = {}
       
        function library:pack(name, ...)
            self.moduleValueMatrix[name] = table.pack(...)
        end
       
        function library:resume()
            if self.queuedInitializerList[1] then
                local continue, tempQueue, forceOptional

                ::initLibraries::
                repeat
                    continue=false
                    self.queuedInitializerList, tempQueue = {}, self.queuedInitializerList
                   
                    for _,func in ipairs(tempQueue) do
                        if func(forceOptional) then
                            continue=true --Something was initialized; therefore further systems might be able to initialize.
                        else
                            insert(self.queuedInitializerList, func) --If the queued initializer returns false, that means its requirement wasn't met, so we re-queue it.
                        end
                    end
                until not continue or not self.queuedInitializerList[1]

                if self.customDeclarationList[1] then
                    self.customDeclarationList, tempQueue = {}, self.customDeclarationList
                    for _,func in ipairs(tempQueue) do
                        func() --unfreeze any custom initializers.
                    end
                elseif not forceOptional then
                    forceOptional = true
                else
                    return
                end
                goto initLibraries
            end
        end
        local function declareName(name, initialValue)
            assert(type(name)=="string")
            assert(library.moduleValueMatrix[name]==nil)
            library.moduleValueMatrix[name] = initialValue and {true,n=1}
        end
        function library:create(name, userFunc)
            assert(type(userFunc)=="function")
            declareName(name, false)                --declare itself as a non-loaded library.
            return function()
                self:pack(name, userFunc(Require))  --pack return values to allow multiple values to be communicated.
                if self.moduleValueMatrix[name].n==0 then
                    self:pack(name, true)           --No values were returned; therefore simply package the value as "true"
                end
            end
        end
        ---@async
        function library:declare(name)
            declareName(name, true)                 --declare itself as a loaded library.
            local co = coroutine.running()
            insert(self.customDeclarationList, function() coroutine.resume(co) end)
            coroutine.yield() --yields the calling function until after all currently-queued initializers have run.
        end
        local processRequirement
        ---@async
        function processRequirement(optional, requirement, explicitSource)
            if type(optional) == "string" then
                optional, requirement, explicitSource = true, optional, requirement --optional requirement (processed by the __index method)
            else
                optional = false --strict requirement (processed by the __call method)
            end
            local source = explicitSource or _G
           
            assert(type(source)=="table")
            assert(type(requirement)=="string")

            ::reindex::
            local subSource, subReq = requirement:match("([\x25w_]+)\x25.(.+)") --Check if user is requiring using "table.property" syntax
            if subSource and subReq then
                source, requirement = processRequirement(subSource, source), subReq --If the container is nil, yield until it is not.
                if type(source)=="table" then
                    explicitSource = source
                    goto reindex --check for further nested properties ("table.property.subProperty.anyOthers").
                else
                    return --The source table for the requirement wasn't found, so disregard the rest (this only happens with optional requirements).
                end
            end
            local function loadRequirement(unpack)
                local package = rawget(source, requirement) --check if the requirement exists in the host table.
                if not package and not explicitSource then
                    if library.yieldedModuleMatrix[requirement] then
                        library.yieldedModuleMatrix[requirement]() --load module if it exists
                    end
                    package = library.moduleValueMatrix[requirement] --retrieve the return value from the module.
                    if unpack and type(package)=="table" then
                        return table.unpack(package, 1, package.n) --using unpack allows any number of values to be returned by the required library.
                    end
                end
                return package
            end
            local co, loaded
            local function checkReqs(forceOptional, printErrors)
                if not loaded then
                    loaded = loadRequirement()
                    loaded = loaded or optional and (loaded==nil or forceOptional)
                    if loaded then
                        if co then coroutine.resume(co) end --resume only if it was yielded in the first place.
                        return loaded
                    elseif printErrors then
                        coroutine.resume(co, true)
                    end
                end
            end
            if not checkReqs() then --only yield if the requirement doesn't already exist.
                co = coroutine.running()
                insert(library.queuedInitializerList, checkReqs)
                if coroutine.yield() then
                    error("Missing Requirement: "..requirement) --handle the error within the user's function to get an accurate stack trace via the "try" function.
                end
            end
            return loadRequirement(true)
        end
        function Require.strict(name, explicitSource)
            return processRequirement(nil, name, explicitSource)
        end
       
        setmetatable(Require, {
            __call = processRequirement,
            __index = function() return processRequirement end
        })

        local module  = createInit "module"

        OnInit.module = function(name, func, debugLineNum)
            if func then
                local userFunc = func
                func = function(require)
                    local co = coroutine.running()
                    library.yieldedModuleMatrix[name]
                        = function(failure)
                            library.yieldedModuleMatrix[name] = nil
                            coroutine.resume(co, failure)
                        end
                    print ("yielding: "..name)
                    if coroutine.yield() then
                        error("Module declared but not required: "..name)
                    end
                    print (name.." has resumed.")
                    return userFunc(require)
                end
            end
            module(name, func, debugLineNum)
        end
    end

    if assignLegacyAPI then --This block handles legacy code.
        ---Allows packaging multiple requirements into one table and queues the initialization for later.
        ---@deprecated
        function OnInit.library(initList, userFunc)
            local typeOf = type(initList)

            assert(typeOf=="table" or typeOf=="string")
            assert(type(userFunc) == "function")

            local function caller(use)
                if typeOf=="string" then
                    use(initList)
                else
                    for _,initName in ipairs(initList) do
                        use(initName)
                    end
                    if initList.optional then
                        for _,initName in ipairs(initList.optional) do
                            use.lazily(initName)
                        end
                    end
                end
            end
            if initList.name then
                OnInit(initList.name, caller)
            else
                OnInit(caller)
            end
        end

        local legacyTable = {}
       
        assignLegacyAPI(legacyTable, OnInit)
       
        for key,func in pairs(legacyTable) do
            rawset(_G, key, func)
        end

        OnInit.final(function()
            for key in pairs(legacyTable) do rawset(_G, key, nil) end
        end)
    end
end
if Debug then Debug.endFile() end
function Trig_NoFog_Actions()
FogEnableOff()
FogMaskEnableOff()
end

function InitTrig_NoFog()
gg_trg_NoFog = CreateTrigger()
TriggerAddAction(gg_trg_NoFog, Trig_NoFog_Actions)
end

function InitCustomTriggers()
InitTrig_NoFog()
end

function RunInitializationTriggers()
ConditionalTriggerExecute(gg_trg_NoFog)
end

function InitCustomPlayerSlots()
SetPlayerStartLocation(Player(0), 0)
SetPlayerColor(Player(0), ConvertPlayerColor(0))
SetPlayerRacePreference(Player(0), RACE_PREF_HUMAN)
SetPlayerRaceSelectable(Player(0), true)
SetPlayerController(Player(0), MAP_CONTROL_USER)
end

function InitCustomTeams()
SetPlayerTeam(Player(0), 0)
end

function main()
SetCameraBounds(1024.0 + GetCameraMargin(CAMERA_MARGIN_LEFT), -3584.0 + GetCameraMargin(CAMERA_MARGIN_BOTTOM), 3072.0 - GetCameraMargin(CAMERA_MARGIN_RIGHT), -1024.0 - GetCameraMargin(CAMERA_MARGIN_TOP), 1024.0 + GetCameraMargin(CAMERA_MARGIN_LEFT), -1024.0 - GetCameraMargin(CAMERA_MARGIN_TOP), 3072.0 - GetCameraMargin(CAMERA_MARGIN_RIGHT), -3584.0 + GetCameraMargin(CAMERA_MARGIN_BOTTOM))
SetDayNightModels("Environment\\DNC\\DNCLordaeron\\DNCLordaeronTerrain\\DNCLordaeronTerrain.mdl", "Environment\\DNC\\DNCLordaeron\\DNCLordaeronUnit\\DNCLordaeronUnit.mdl")
NewSoundEnvironment("Default")
SetAmbientDaySound("SunkenRuinsDay")
SetAmbientNightSound("SunkenRuinsNight")
SetMapMusic("Music", true, 0)
InitBlizzard()
InitGlobals()
InitCustomTriggers()
RunInitializationTriggers()
end

function config()
SetMapName("")
SetMapDescription("")
SetPlayers(1)
SetTeams(1)
SetGamePlacement(MAP_PLACEMENT_USE_MAP_SETTINGS)
DefineStartLocation(0, 896.0, -640.0)
InitCustomPlayerSlots()
SetPlayerSlotAvailable(Player(0), MAP_CONTROL_USER)
InitGenericPlayerSlots()
end

