__author__ = 'gpipperr'

import datetime, time
import glob, filecmp, ntpath, shutil
import os, errno, sys, getopt

# Library to read the exif informatoin
# load with .\python -m pip install exifread  --upgrade
# from https://pypi.python.org/pypi/ExifRead
import exifread


# Get the change date of a file
def modification_date(filename):
    t = os.path.getmtime(filename)
    print("-- Info  :: EXIF data not available - use  mTime {0} of the file".format(datetime.datetime.fromtimestamp(t)))
    return datetime.datetime.fromtimestamp(t)


# check for a unique filename in the import directory
# if the new unique name still exits check if this file is the same as the original file
# if yes do not copy and search the next unique file name until a new name is found
# noinspection PyPep8Naming
def createNewName(filename, importDir, fileNo, origFile):
    firstPart = filename.split(".")[0]
    extension = filename.split(".")[1]
    newFName = firstPart + "-" + str(fileNo) + "." + extension
    # If exits
    if os.path.isfile(importDir + os.path.sep + newFName):
        # Check if this new Name is still the original file
        # if shallow is true, files with identical os.stat() signatures are taken to be equal. Otherwise, the contents of the files are compared.
        fcompare = filecmp.cmp(origFile, importDir + os.path.sep + newFName, shallow=False)
        if fcompare:
            print("-- Info  :: File {0} still exits with same content as original file {1}".format(newFName, origFile))
            return newFName
        else:
            fileNo += 1
            # call again to find the next possible name
            return createNewName(newFName, importDir, fileNo, origFile)
    else:
        # Copy the new file and return the name of the new file
        shutil.copy2(origFile, importDir + os.path.sep + newFName)
        setStatisticTotalSize(os.path.getsize(importDir + os.path.sep + newFName))
        print("-- Info  :: File {0} exits but with other content, create new File {1}".format(origFile,
                                                                                              importDir + os.path.sep + newFName))
        return newFName


# Remember the global Size of all copied files
def setStatisticTotalSize(size):
    global totalFileSize
    totalFileSize += size


# global for the total filesize
totalFileSize = 0


# Main Script part
def main(argv):
    # Parameter 1   - Import Directory
    # Parameter 2   - Image Main Folder
    # Parameter 3   - Subfolder Level

    path_name = '-'
    dest_name = '-'
    recursiveLevel = 0

    try:
        opts, args = getopt.getopt(argv, "hs:d:r:", ["src=", "dest=", "rec="])
    except getopt.GetoptError:
        print("usage: importImg.py  -s <src> -d <dest> -r <recursive Level>")
        sys.exit(2)

    for opt, arg in opts:
        if opt == '-h':
            print("usage: importImg.py  -s <src> -d <dest> -r <recursive Level>")
            sys.exit()
        elif opt in ("-s", "--src"):
            path_name = arg
        elif opt in ("-d", "--dest"):
            dest_name = arg
        elif opt in ("-r", "--rec"):
            recursiveLevel = int(arg)

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
        print("-- Error :: 05 Source Directory (-s) {0} not found".format(path_name))
        print("usage: importImg.py  -s <src> -d <dest> ")
        sys.exit(2)

    # Destination
    # check and strip last / if necessary
    if not os.path.isdir(dest_name):
        print("-- Error :: 04 Destination Directory (-d) {0} not found".format(dest_name))
        print("usage: importImg.py  -s <src> -d <dest> ")
        sys.exit(2)
    else:
        if dest_name.endswith(os.path.sep):
            dest_name = dest_name[:-1]

    # Remember the start time of the program
    start_time = time.clock()

    print("--" + 40 * "=")
    print("-- Info  :: Read all files from {0}".format(path_name))
    print("-- Info  :: Copy files to       {0}".format(dest_name))
    print("--" + 40 * "=")

    fileCount = 0
    fileExistsCount = 0
    dirCount = 0
    dirPathList = []

    # Get the list of all Files
    fileList = glob.glob(path_name)

    # remove Thumbs.db if exist from the list
    # Internal Windows file no need to copy it
    thumbsDBFile = "Thumbs.db"
    for file in fileList:
        if file.endswith(thumbsDBFile):
            fileList.remove(file)

    # Loop one read files in Import Directory
    for file in fileList:
        fileCount += 1
        createDate = datetime.datetime.now()
        imgFilename = '-'
        newFileName = '-'
        try:
            # get only the filename without the path
            imgFilename = ntpath.basename(file)

            # Open image file for reading (binary mode)
            imgFile = open(file, 'rb')

            # Read the image tags, if not possible read last change date
            try:
                tags = exifread.process_file(imgFile, stop_tag='EXIF DateTimeDigitized')
                # Transform to a real date
                # https://docs.python.org/2/library/datetime.html#strftime-and-strptime-behavior
                # 2010:08:22 14:13:42  %Y:%m:%d %H:%M:%S
                createDate = datetime.datetime.strptime(str(tags['EXIF DateTimeDigitized']), '%Y:%m:%d %H:%M:%S')
            except:
                # if no exif tag use the last modification date
                # print("file with not exif information ::{0}".format(imgfile.name))
                createDate = modification_date(file)

            # Create Import Directory if not exits
            # Remember the directory after the first create
            # to avoid exception with still existing directories
            dirPath = dest_name + os.path.sep + "{0:%Y%m%d}".format(createDate)
            try:
                if dirPath not in dirPathList:
                    dirPathList.append(dirPath)
                    os.makedirs(dirPath)
                    dirCount += 1
                    print("-- Info  :: Create Directory :: {0}".format(dirPath))
            except OSError as exception:
                if exception.errno != errno.EEXIST:
                    print(
                        "-- Error :: 03 Directory {0} creation error :: see error {1}".format(dirPath,
                                                                                              sys.exc_info()[0]))
                else:
                    print("-- Info  :: Directory still exits :: {0}".format(dirPath))
                    pass

            # Copy the file to the new directory
            newFileName = dirPath + os.path.sep + imgFilename
            try:
                # Check if the same filename still exists
                if os.path.isfile(newFileName):
                    # if shallow is true, files with identical os.stat() signatures are taken to be equal. Otherwise, the contents of the files are compared.
                    compare = filecmp.cmp(imgFile.name, newFileName, shallow=False)
                    if compare:
                        print("-- Info  :: File {0} exits with the same content".format(imgFilename))
                        fileExistsCount += 1
                    else:
                        newUniqueFileName = createNewName(imgFilename, dirPath, 0, imgFile.name)
                else:
                    # copy2 preserves the original modification and access info (mtime and atime) in the file metadata.
                    shutil.copy2(imgFile.name, dirPath)
                    setStatisticTotalSize(os.path.getsize(newFileName))
                    print("-- Info  :: Copy Image {0:50} to directory {1}".format(imgFilename, dirPath))
            except OSError as exception:
                print("-- Error :: 02 File {0} in directory {1} :: error {2}".format(imgFile.name, dirPath,
                                                                                     sys.exc_info()[0]))

            if not imgFile.closed:
                imgFile.close()
        except:
            print("-- Error :: 01 Error with {0} in {1} :: error {2}".format(imgFile.name, path_name, sys.exc_info()))
            pass

    # print statistics
    print("--" + 40 * "=")
    print("-- Finish with           :: {0} files in {1} new directories".format(fileCount, dirCount))
    print("-- Found duplicate files :: {0}".format(fileExistsCount))
    print("-- The run needs         :: {0:5.4f} seconds".format(time.clock() - start_time))
    print("-- Copy size             :: {0:5.3f} MB".format(totalFileSize / 1024 / 1024))
    print("--" + 40 * "=")


if __name__ == "__main__":
    main(sys.argv[1:]);
