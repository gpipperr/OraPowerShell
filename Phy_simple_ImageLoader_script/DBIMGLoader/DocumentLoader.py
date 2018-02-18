__author__ = 'gpipperr'

import datetime, time
import glob, filecmp, ntpath, shutil
import os, errno, sys, getopt
import hashlib
import subprocess
import io
import cx_Oracle
import locale
import configparser


# get FileType
def getFileType(file, command, magicFilePath):
    # magicFilePath
    result = "-2"
    # Command + arguments  as sequence
    args = magicFilePath + " " + command + ' "' + file + '"'
    # execute the program and pipe the output to subprocess.PIPE
    prog = subprocess.Popen(args, stdout=subprocess.PIPE, shell=True)
    # wait until finished
    stat = prog.wait()
    # connect pipes together
    (output, err) = prog.communicate()
    result = str(output)
    result = str.replace(result, "b'", "")
    result = str.replace(result, "\\r", "")
    result = str.replace(result, "\\n", "")
    escFileName = str.replace(str(file), "\\", "\\\\") + "; "
    result = str.replace(result, escFileName, "")
    return result


# Get extension
def getFile_ext(filename):
    fparts = filename.split('.')
    c = len(fparts)
    # try to get .tar.gz
    v_return = fparts[-1]
    if c > 3:
        if len(fparts[-2]) < 5:
            chars = set('$,()[]_ ')
            if any((c in chars) for c in fparts[-2]):
                v_return = fparts[-1]
            else:
                v_return = fparts[-2] + "." + fparts[-1]

    if v_return.find('.') < 0:
        v_return = "." + v_return

    return v_return.lower()

# get the MD5 Hash the file
def getMD5(filename):
    blocksize = 65536
    if os.path.exists(filename) == False:
        return 'N/A'
    md5 = hashlib.md5()
    with open(filename, "rb") as f:
        for block in iter(lambda: f.read(blocksize), b""):
            md5.update(block)
    return md5.hexdigest()


# Remember the global Size of all copied files
def setStatisticTotalSize(size):
    global totalFileSize
    totalFileSize += size


# global for the total filesize
totalFileSize = 0


# print the file info
# later insert the record to the database
#   fileInfo=dict(filename=filename,filepath=fileDirectoryName,fileADate=fileAccessDate,fileMDate=fileModDate,fileCDate=fileCreateDate,md5=md5checkSum,fileBType=fileType,fileMtype=fileMimeType)
def insertFileInfo(fileInfo, ora_dir_path, connection):
    # strip the oracle path
    print("-- Info ORA_DIR_PATH ::{0}".format(ora_dir_path))
    relative_doc_path = str.replace(fileInfo['filepath'], ora_dir_path, "")
    try:
        print("-- Info for the file ::{0}".format(fileInfo['filename']))
        print("                 Path::{0}".format(fileInfo['filepath']))
        print("         Relativ Path::{0}".format(relative_doc_path + os.sep + str(fileInfo['filename'])))
        print("          Access Date::{0}".format(fileInfo['fileADate']))
        print("          Modify Date::{0}".format(fileInfo['fileMDate']))
        print("          Create Date::{0}".format(fileInfo['fileCDate']))
        print("            File Size::{0}".format(fileInfo['fileSize']))
        print("                  MD5::{0}".format(fileInfo['md5']))
        print("     File Binary Type::{0}".format(fileInfo['fileBType']))
        print("       File Mime Type::{0}".format(fileInfo['fileMtype']))
        print("       File Extention::{0}".format(fileInfo['fileExtention']))
    except:
        print("Unexpected error with file infos")

    # insert into the database

    # Cursor auf die DB oeffenen
    cursor = connection.cursor()

    # filename,filetyp,filedirectory,md5hash, FILECREATEDATE, FILELASTMODIFY
    # .encode('utf-8')
    # .encode('utf-8')

    doc_rows = [(str(fileInfo['filename'])
                 , fileInfo['fileExtention']
                 , fileInfo['filepath']
                 , fileInfo['md5']
                 , fileInfo['fileCDate']
                 , fileInfo['fileMDate']
                 , relative_doc_path + os.sep + str(fileInfo['filename'])
                 , fileInfo['fileSize']
                 , fileInfo['fileADate']
                 )
                ]

    # how many rows to insert
    cursor.bindarraysize = len(doc_rows)

    # datatype - lenght of the inserted data
    # cursor.setinputsizes(int, 14, 13)
    try:
        # insert the whole record
        cursor.executemany(
            "insert into documents (ID , FILENAME, FILETYP, FILEDIRECTORY, MD5HASH, FILECREATEDATE, FILELASTMODIFY,FILEPOINTER,filesize,FILELASTACESS) values ( documents_seq.nextval, :1, :2, :3, :4, :5, :6,BFILENAME('INFO_ARCHIVE',replace(:7,';','')),:8,:9)",
            doc_rows)
    except cx_Oracle.DatabaseError as e:
        connection.rollback()
        print("-- Error - Oracle Database Error:" + str(e))
    except Exception as e:
        print("-- Error - Unexpected error:" + str(e))
        connection.rollback()
        # raise
    connection.commit()


# Main Script part
def main(argv):
    global totalFileSize


    # Parameter 1   - Import Directory
    # Parameter 2   - Subfolder Level


    # Remember the start time of the program
    start_time = time.clock()

    usage_string = " DocumentLoader.py  -s <src>  -r <recursive Level> -d <oracle_directory_path> -c <config_path>"

    path_name = '-'
    dest_name = '-'
    recursiveLevel = 0
    config_path = 'dataLoader.conf'

    # -- Parameter from the config file

    oracle_port = '-'
    oracle_host = '-'
    oracle_service = '-'
    oracle_user = '-'
    oracle_pwd = '-'
    magicFilePath = '-'
    ingoreFileExt = []

    # Path of the oracle Info Archive
    ora_dir_path = '-'

    try:
        opts, args = getopt.getopt(argv, "hs:d:r:d:c:", ["src=", "rec=", "dir=", "config="])
    except getopt.GetoptError:
        print("usage: {0}".format(usage_string))
        sys.exit(2)
    # read the parameter
    for opt, arg in opts:
        if opt == '-h':
            print("usage: {0}").format(usage_string)
            sys.exit()
        elif opt in ("-s", "--src"):
            path_name = arg
        elif opt in ("-d", "--dir"):
            ora_dir_path = arg
        elif opt in ("-c", "--config"):
            config_path = arg
        elif opt in ("-r", "--rec"):
            recursiveLevel = int(arg)

    # read the config file
    config = configparser.ConfigParser()
    # check if the file exits
    if os.path.exists(config_path) == False:
        # use normal configparser to write the template
        print("--" + 80 * "!")
        print("-- Error to read file {0}".format(config_path))
        print("-- Error usage: {0}".format(usage_string))
        config['DEFAULT'] = {'MagicFile': 'd:\\tools\\file\\bin\\file.exe', 'ignoreFileExt': '.iso'}
        config['ORACLE_DB_CONNECT'] = {'Host': 'localhost', 'Port': '1521', 'Service': 'ORCL', 'DB_User': 'USER',
                                       'DB_Password': 'xxxxx'}
        with open(config_path, 'w') as configfile:
            config.write(configfile)
        print("--" + 80 * "!")
        print("-- Info create Configuration Template :: {0}".format(config_path))
        print("-- Info fillout the configuration file  with your personal values and start again!")
        print("--" + 80 * "!")
        sys.exit(2)
    else:
        print("-- Info read config file {0}".format(config_path))
        config.read(config_path)
        # Parameter of the application
        general_configuration = config['DEFAULT']
        magicFilePath = general_configuration['MagicFile']
        ingoreFileExtString = general_configuration['ignoreFileExt']
        ingoreFileExt = str.split(str.replace(ingoreFileExtString, ' ', ''), ',')
        # Oracle DB Connect
        oracle_db_configuration = config['ORACLE_DB_CONNECT']
        oracle_port = oracle_db_configuration['Port']
        oracle_host = oracle_db_configuration['Host']
        oracle_service = oracle_db_configuration['Service']
        oracle_user = oracle_db_configuration['DB_User']
        oracle_pwd = oracle_db_configuration['DB_Password']


    # check if Directory exists and if the * is necessary
    # BUG ! if more then 1 then the * not match the documents on root level??
    # FIX IT!
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
        print("usage: {0}").format(usage_string)
        sys.exit(2)

    # connect to the database
    print("--" + 40 * "=")
    print("-- Info :: Oracle Client Library Version :: {0}".format(cx_Oracle.clientversion()))
    # get the connection to the database
    print("-- Info :: oracle_host {0} oracle_port {1} oracle_service {2} oracle_user {3} oracle_pwd ********".format(
        oracle_host, oracle_port, oracle_service, oracle_user, oracle_pwd))
    connection = cx_Oracle.connect(
        oracle_user + '/' + oracle_pwd + '@' + oracle_host + ':' + oracle_port + '/' + oracle_service)
    # Version der DB ausgeben
    print("-- Info :: Oracle Database Version :: {0}".format(connection.version))
    print("--" + 40 * "=")

    print("-- Info  :: Environment Settings :: Language :: {0} - Char Set ::{1}".format(locale.getdefaultlocale()[0],
                                                                                        locale.getdefaultlocale()[1]))

    print("--" + 40 * "=")
    print("-- Info  :: Read all files from {0}".format(path_name))
    print("-- Info  :: Copy files to       {0}".format(dest_name))
    print("-- Info  :: Not index this file types ::" + str(ingoreFileExt))
    print("--" + 40 * "=")

    fileCount = 0
    fileExistsCount = 0
    dirCount = 0
    dirPathList = []
    totalFileSize = 0
    # Get the list of all Files
    fileList = glob.glob(path_name)

    # remove Thumbs.db if exist from the list
    thumbsDBFile = "Thumbs.db"
    for file in fileList:
        if file.endswith(thumbsDBFile):
            fileList.remove(file)

    # Loop one read files in Import Directory
    for file in fileList:
        fileCount += 1
        #read only some files
        if fileCount > 20:
            exit

        # do the work
        try:
            # check if directoy
            if ntpath.isdir(file):
                print("-- Info :: found dirctory {0} ::".format(file))
                dirCount += 1
            else:
                # get only the filename without the path
                filename = ntpath.basename(file)
                # get directory
                fileDirectoryName = ntpath.dirname(file)
                # get Create date

                fileAccessDate = datetime.datetime.fromtimestamp(ntpath.getatime(file))
                fileModDate = datetime.datetime.fromtimestamp(ntpath.getmtime(file))
                fileCreateDate = datetime.datetime.fromtimestamp(ntpath.getctime(file))
                # get md5 hash
                md5checkSum = getMD5(file)
                # get File Type over file from external, Python Lib magic not working, error with magic file!
                # now I implement this stupid solution
                fileType = getFileType(file, " ", magicFilePath)
                # Call file with -i to get the mime Type
                fileMimeType = getFileType(file, "-i", magicFilePath)
                # get Extenstion
                fileExt = getFile_ext(filename)
                # getFileSize
                fileSize = os.path.getsize(file)
                # Remember for statistic
                setStatisticTotalSize(fileSize)

                # not add url files to the index
                # endswith(".url")

                if fileExt in ingoreFileExt:
                    # encode the output with UTF-8 to avoid errors with stange things in filenames
                    print("-- Info :: Not index this file types ::" + str(ingoreFileExt))
                    print("-- Info :: Not index this file::{0}".format(repr(filename.encode('utf-8'))))
                    print("-- Info :: Not index this Dir::{0}".format(repr(fileDirectoryName.encode('utf-8'))))
                    print("-- --")
                else:
                    # record
                    fileInfo = dict(filename=str(filename), filepath=str(fileDirectoryName), fileADate=fileAccessDate,
                                    fileMDate=fileModDate, fileCDate=fileCreateDate, md5=md5checkSum,
                                    fileBType=fileType,
                                    fileMtype=fileMimeType, fileExtention=fileExt, fileSize=fileSize)

                    ##print("-- Index this Dir::{0}".format(repr(fileDirectoryName.encode('utf-8'))))
                    # encode the output with UTF-8 to avoid errors with stange things in filenames
                    ##print("-- Index this file   ::{0}".format(repr(filename.encode('utf-8'))))
                    # write to DB
                    insertFileInfo(fileInfo, ora_dir_path, connection)

        except OSError as exception:
            if exception.errno != errno.EEXIST:
                print("-- Error :: Error read file :: see error {1}".format(file, sys.exc_info()[0]))


    # print statistics
    print("--" + 40 * "=")
    print("-- Finish with           :: {0} files in {1} new directories".format(fileCount, dirCount))
    print("-- The run needs         :: {0:5.4f} seconds".format(time.clock() - start_time))
    print("-- Read size             :: {0:5.3f} MB".format(totalFileSize / 1024 / 1024))
    print("--" + 40 * "=")

    # Close the DB Connection
    connection.close()


if __name__ == "__main__":
    main(sys.argv[1:]);
