__author__ = 'gpipperr'

import datetime
import time
import glob
import filecmp
import ntpath
import shutil
import os
import sys
import getopt


# check for a unique filename in the temp directory and move the file to the tmp directory
# if the new unique name still exits check if this file is the same as the original file
# if yes do not copy and search the next unique file name until a new name is found
def moveDuplicateFile(filename, tempDir, fileNo, origFile):
    firstPart = filename.split(".")[0]
    extension = filename.split(".")[1]
    newFName = firstPart + ("-" + str(fileNo) if fileNo > 0 else "") + "." + extension
    # If exits
    if os.path.isfile(tempDir + os.path.sep + newFName):
        # Check if this new Name is still the original file
        fcompare = filecmp.cmp(origFile, tempDir + os.path.sep + newFName, shallow=False)
        if fcompare:
            # as the original file is still save - delete the original one
            os.remove(origFile)
            print("-- Info  :: Delete File \"{0:40}\" - still exits with the same content in \"{1}\"".format(origFile,
                                                                                                             newFName))
            return newFName
        else:
            fileNo += 1
            # call again to find the next possible name
            return moveDuplicateFile(newFName, tempDir, fileNo, origFile)
    else:
        # Copy the new file and return the name of the new file
        shutil.move(origFile, tempDir + os.path.sep + newFName)
        print(
            "-- Info  :: Move Duplicate File \"{0:40}\" to \"{1}\"".format(origFile, tempDir + os.path.sep + newFName))
        return newFName


# Main Script part
def main(argv):
    # Parameter 1   - Image Main Folder
    path_name = '-'
    temp_path = 'd:\\temp'
    recursiveLevel = 0
    usageString = "usage: removeDuplicateFiles.py  -s <src> -t <temp path>"

    try:
        opts, args = getopt.getopt(argv, "hs:t:", ["src=", "tmp="])
    except getopt.GetoptError:
        print(usageString)
        sys.exit(2)

    for opt, arg in opts:
        if opt == '-h':
            print(usageString)
            sys.exit()
        elif opt in ("-s", "--src"):
            path_name = arg
        elif opt in ("-t", "--tmp"):
            temp_path = arg

    # check if Directory exists and if the * is necessary
    # Source
    if os.path.isdir(path_name):
        if path_name.endswith(os.path.sep):
            path_name += ("*" + os.path.sep) * recursiveLevel
            path_name += "*.*"
        else:
            path_name += os.path.sep
            path_name += ("*" + os.path.sep) * recursiveLevel
            path_name += "*.*"
    else:
        print("-- Error :: 03 Source Directory (-s) {0} not found".format(path_name))
        print(usageString)
        sys.exit(2)

    # Temp Destination
    # check and strip last / if necessary
    if not os.path.isdir(temp_path):
        print("-- Error :: 02 temp Directory (-t) {0} not found".format(temp_path))
        print(usageString)
        sys.exit(2)
    else:
        if temp_path.endswith(os.path.sep):
            dest_name = temp_path[:-1]

    # Remember the start time of the program
    start_time = time.clock()

    print("--" + 40 * "=")
    print("-- Info  :: Read all files in  :: {0}".format(path_name))
    print("-- Info  :: Copy duplicates to :: {0}".format(temp_path))
    print("--" + 40 * "=")

    fileCount = 0
    fileExistsCount = 0

    # Get the list of all Files
    masterFileList = glob.glob(path_name)
    slaveFileList = glob.glob(path_name)
    candiateFile = []

    # Loop one read files in Import Directory
    for masterfile in masterFileList:
        fileCount += 1
        createDate = datetime.datetime.now()

        # Loop again over all files
        # compare the files, if a match found remove from list
        print("-- Info  :: Check File \"{0}\"".format(masterfile))
        for cfile in slaveFileList:
            # only if not the same file
            if masterfile != cfile:
                # if shallow is true, files with identical os.stat() signatures are taken to be equal. Otherwise, the contents of the files are compared.
                compare = filecmp.cmp(masterfile, cfile, shallow=False)
                if compare:
                    print(
                        "-- Info  :: File \"{0:40}\" exits with the same content as file {1}".format(masterfile, cfile))

                    # remove only if still exits
                    # if more then one file is identical
                    # you need more then one run
                    if masterfile in slaveFileList:
                        slaveFileList.remove(masterfile)

                    # Add the file with the longest name to the duplicate file list
                    longestFileName = masterfile if len(masterfile) > len(cfile) else cfile
                    # Avoid duplicate entries
                    if longestFileName not in candiateFile:
                        candiateFile.append(longestFileName)
                        fileExistsCount += 1

    # Do something with the duplicates
    print("--" + 40 * "=")

    for file in candiateFile:
        # move the files to temp
        try:
            imgFilename = ntpath.basename(file)
            moveDuplicateFile(filename=imgFilename, tempDir=temp_path, fileNo=0, origFile=file)
        except:
            print("-- Error :: 01 - Move File {0} :: error {1}:".format(file, sys.exc_info()))
            pass

    if fileExistsCount < 1:
        print("-- Found no duplicate files in directory {0}".format(path_name))

    print("--" + 40 * "=")

    # print statistics

    print("--" + 40 * "=")
    print("-- Finish with           :: {0} files in directorie {1}".format(fileCount, path_name))
    print("-- Found duplicate files :: {0}".format(fileExistsCount))
    print("-- The run needs         :: {0:5.4f} seconds".format(time.clock() - start_time))
    print("--" + 40 * "=")


if __name__ == "__main__":
    main(sys.argv[1:])
