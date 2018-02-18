__author__ = 'gpipperr'


# Get extension
#    #
def getFile_ext2(filename):
    #clean filename from stange letters
    chars = set('$,()[]_ ')
    for c in chars:
        filename = str.replace(filename, c, "")
    #split the filename
    fparts = filename.split('.')[1:]
    z = len(fparts)
    #get only the last part
    if z > 1:
        fparts = fparts[(z - 2):]
    fparts = '.'.join(fparts)
    v_return = '.' + fparts if fparts else None
    # check if space in the name to avoid strange filenames
    #if len(v_return) > 10 and v_return.count('.') > 1:
    #    getFile_ext(v_return)
    #else:
    return v_return.lower()

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

    return v_return




test1 = 'Test (x ) dokument.doc'
print("--" + 40 * "=")
print("-- Info  :: try to test file extension from the file name  {0}".format(test1))
result = getFile_ext(test1)
print("-- Info  :: found  {0}".format(result))
print("--" + 40 * "=")
