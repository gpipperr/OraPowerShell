import time
import os
import sys
import datetime

__author__ = 'gpipperr'

# Source: multiple Examples in the internet - thanks to people answer questions in forums

# Hashing
import hashlib


# Get the change date of a file
def modification_date(filename):
    t = os.path.getmtime(filename)
    return datetime.datetime.fromtimestamp(t)


# Write the progressbar

def write_progress(pstep, width):
    if width > pstep:
        s = "X" * pstep + ">"
    else:
        s = "X" * pstep
    r = "." * (width - pstep)
    print("-- [{0:{1}}]".format(s + r, width), end="\r")
    sys.stdout.flush()


# Close the progressbar
def finish_progress(pstep):
    s = "x" * pstep
    print("-- [" + s + "]")
    sys.stdout.flush()


# after x files draw a point
progress_points = 10
progress_width = 80
# algoList=hashlib.algorithms_available
algoList = ['SHA1', 'MD5', 'DSA-SHA', 'MD4', 'SHA', 'DSA']
# Best Performance
hashAlgo = 'SHA1'
# size of the file buffer
buffersize = 262144

# Remember the start time of the program
start_time = time.clock()

# read of a complete directory structure
base_dir = "C:\\data\\info-archiv"
#base_dir = "C:\\oracle\\products"
#

print("--" + 40 * "=")
print("-- Info :: start to read base directory {0} )".format(base_dir))
print("--" + 40 * "=")
print("--")

fileRead = 0
# calculate how many files to compare
for folder, subFolders, files in os.walk(base_dir):
    # print( "folder {0}, subFolders {1}, files {2}".format( folder, subFolders, files ) )
    for file in files:
        fileRead += 1

# calculate the progressbar

progress_points = int(fileRead / progress_width)
#check if 0 
if progress_points == 0:
	progress_points =1

print("--" + 40 * "=")
print("-- Info :: After the read of base directory {0} found {1} files (progress :: each x for {2} files)".format(base_dir,
                                                                                                             fileRead,
                                                                                                             progress_points))
print("-- Info  :: The read of all filenames  needs                              :: {0:5.8f} seconds".format(time.clock() - start_time))
print("--" + 40 * "=")
print("--")

fileRead = 0
step = 1
# get all MD5 Hashes of all Files in the directory structure
results = []
for folder, subFolders, files in os.walk(base_dir):
    # print( "folder {0}, subFolders {1}, files {2}".format( folder, subFolders, files ) )
    for file in files:
        fileFullName = folder + os.path.sep + file
        if os.path.isfile(fileFullName):
            fileRead += 1

            # progressbar
            if fileRead % progress_points == 0:
                write_progress(step, progress_width)
                step += 1

            # define the hash algorithm
            hashtask = hashlib.new(hashAlgo)
            try:
                # Open the file and read and hash
                with open(fileFullName, 'rb') as afile:
                    buffer = afile.read(buffersize)
                    while len(buffer) > 0:
                        hashtask.update(buffer)
                        buffer = afile.read(buffersize)
                # get the hash af the file
                filehash = hashtask.hexdigest()
                # Remember Results
                results.append([filehash, fileFullName, modification_date(fileFullName)])
                # print("-- Info  :: The file {0} has the {1} hash :: {2}".format(fileFullName, hashAlgo, filehash))
            except:
                print("-- Error :: 01 - Read File {0} :: error {1}:".format(fileFullName, sys.exc_info()))
                pass
# get duplicate md5 hash values

# close progressbar
finish_progress(step)
print("--")

# sort md5 hashes in the list
results.sort(key=lambda x: x[0])

# get only the element of a list
h = []
# for a,b in enumerate(results):
for b in results:
    h.append(b[0])

# get a unorderd but unique list
s = set(h)
print("--" + 40 * "=")


# search the duplicates
dub = []
for x in h:
    if x in s:
        s.remove(x)
    else:
        dub.append(x)

x = '-'
dub.sort(key=lambda x: x[0])
if len(dub) > 0:
    x = dub[0]

dupFileCount=0
# show the duplicates entries
for res in results:
    if res[0] in dub:
        if res[0] != x:
            print("  " + 40 * "-")
        print("-- Info hash {0} and this date {2} ::  File {1} ".format(res[0], res[1], res[2]))
        dupFileCount += 1
    x = res[0]

print("--" + 40 * "=")
print("-- Info :: found {1} duplicate entries in {0} total files".format(len(results), dupFileCount))
print("-- Info  :: The run needs          :: {0:5.8f} seconds".format(time.clock() - start_time))
print("--" + 40 * "=")

# define the ruleset which file have to be deleted ....
# define a delete directory, if there the file is found it will be deleteted, compared to a directory structure