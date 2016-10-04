#python
#
import os
import inspect
import sys

exclusion_file  = '<path here>/fnexcl.res'
farr = []

class Stack:
     def __init__(self):
         self.items = []

     def isEmpty(self):
         return self.items == []

     def push(self, item):
         self.items.append(item)

     def pop(self):
         return self.items.pop()

     def peek(self):
         return self.items[len(self.items)-1]

     def size(self):
         return len(self.items)

     def display(self, stkfname):
        if self.items == []:
            return;
        for val in self.items:
            writeInFile (stkfname, val, '\t')
        writeInFile (stkfname, '\n', '')

def run(command):
    try:
        return gdb.execute(command, to_string=True)
    except gdb.error:
        sys.exit()
    except:
        print ("Error while executing the command " + command + ".\n")

def getCurFrame():
    try:
        return gdb.newest_frame()
    except:
        return None

def getCurFnName ():
    try:
        frame = getCurFrame()

        if frame == None:
            print ("Returning empty function name.\n")
            #sys.exit()
            return "__PYTHON_GDB_GETCURFRAME_FAILED__"
        else:
            return frame.name()
    except SystemExit:
        print ("Exiting...\n")
    except:
        print ('Exception occured while getting current function name.\n')
        sys.exit()
        return "__PYTHON_GDB_GETCURFRAME_FAILED__"

def loadExclusionFunctionList ():
    global  farr
    global  exclusion_file
    with open(exclusion_file) as f:
        farr.extend (f.read().splitlines())

def checkIfAcceptableFunction (fname):
    global  farr        # array of ignored functions

    if fname in farr:
        return False

    if fname.startswith('_'):
        return False

    if "alloc" in fname:
        return False

    return True

def displayArr (farr):
    for word in farr:
        print (word)
        if (word.strip () == ""):
            print ('# empty string')
        #print ('\n')

    print (len(farr))

def writeInFile (fname, content1, content2 = ""):
    try:
        f = open(fname, 'a')
        f.write (content1)
        f.write (content2)
        f.close ()
    except:
        print ('Unable to open the file.\n')

def clearFileContent (fname):
    try:
        f = open(fname, 'w')
        f.truncate()
        f.close()
    except:
        print ('Unable to truncate the file.\n')

def trace_function_calls (args):
    global  farr        # array of ignored functions
    fnstk   = Stack()   # call stack
    curfn   = ''
    nxtfn   = ''
    prvfn   = ''
    depth   = 0
    dbg     = False
    fname   = 'out.log'
    dbgfname= 'dbg.log'
    stkfname= 'stk.log'
    errfname= 'err.log'

    if (len(args) == 2):
        print ('Running in debug mode...\n')
        fname = args[0];
        if (args[1] == 'debug'):
            dbg = True;
    elif (len(args) == 1):
        fname = args[0];
        print ('Running in release mode...\n')
    else:
        print ('Output is in file \"out.log\"\n')
        print ('Running in release mode...\n')

    loadExclusionFunctionList ()

    # truncate the file
    clearFileContent (fname)
    clearFileContent (dbgfname)
    clearFileContent (stkfname)
    clearFileContent (errfname)

    # get current function name
    curfn   = getCurFnName()#gdb.newest_frame().name()

    # push the current function on the stack
    fnstk.push (curfn)

    # Write the current function name
    writeInFile(fname, curfn, '\n')

    while (fnstk.isEmpty() == False):
        # step into
        run('s')
        # next function name
        nxtfn   = getCurFnName()#gdb.newest_frame().name()

        # debug section
        if dbg == True:
            if (nxtfn == "__PYTHON_GDB_GETCURFRAME_FAILED__"):
                writeInFile (errfname, "Displaying call stack and exiting.", "\n")
                fnstk.display(stkfname)

        # This should not be null, Error case
        if nxtfn == None:
# print error here
            continue

        # Still in the same function, continue
        if (nxtfn == curfn):
            continue

        # Check if stepped into excluded functions
        if checkIfAcceptableFunction (nxtfn) == False:
            # Finish the entire function
            while True:
                run('n')
                nxtfn   = getCurFnName()#gdb.newest_frame().name()

                # debug section
                if dbg == True:
                    if (nxtfn == "__PYTHON_GDB_GETCURFRAME_FAILED__"):
                        writeInFile (errfname, "Displaying call stack and exiting.", "\n")
                        fnstk.display(stkfname)

                if nxtfn == curfn:
                    break

            continue

        # get the function name on the top of the stack
        #prvfn   = fnstk.peek()

        if dbg == True:
            fnstk.display(stkfname)
            writeInFile (dbgfname, prvfn + '\t-->\t' + curfn + '\t-->\t' + nxtfn, '\n')
            #print (prvfn + '\t-->\t' + curfn + '\t-->\t' + nxtfn + '\n')

        # case1 - stepped out of function
        if (prvfn == nxtfn):
            depth = depth - 1
            fnstk.pop()
            curfn = prvfn
            if fnstk.isEmpty() == False:
                prvfn = fnstk.peek()
            else:
                prvfn = ''
        # case2 - stepped in function
        else:
            # increase depth
            depth = depth + 1
            # log into file
            writeInFile(fname, ' ' * depth, nxtfn + '\n')

            # push old function on stack
            fnstk.push(curfn)

            # make new function as current
            prvfn = curfn
            curfn = nxtfn

class RT_Trace (gdb.Command):

    def __init__ (self):
        super (RT_Trace, self).__init__ ("rtt", gdb.COMMAND_USER)

    def invoke (self, arg, from_tty):
        if arg == "":
            print ("""
            Usage: rtt <file name for runtime function calls>
            Steps:
            1. Start the program that has to be executed.
            2. Break the execution on the desired function,
               it will list all function all that are not
               excluded.
            3. It would stop at the end of the string function
               call.
            4. Create a file "fnexcl.res" to specify the excluded
               function list. Change the path in this file.

            """)
            return "Error!!!"
        return trace_function_calls (arg.split())

RT_Trace()
