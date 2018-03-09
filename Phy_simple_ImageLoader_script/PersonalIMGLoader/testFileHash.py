__author__ = 'gpipperr'
# Hashing
import hashlib
import os
import time

# graph
#  C:\Python34> .\python -m pip install matplotlib --upgrade
import matplotlib.pyplot as plt

# check the possible hash libs
print(hashlib.algorithms_available)

# add your testfile here
file = 'D:\\temp\\12cR2Upgrade\\catupgrd0.log'
size = os.path.getsize(file)

# size of the file buffer
buffersize = 262144

results = []
for hashAlgo in hashlib.algorithms_available:

    # Remember the start time of the program
    start_time = time.clock()

    # define the hash algorithm
    hashtask = hashlib.new(hashAlgo)

    # Open the file and read and hash
    with open(file, 'rb') as afile:
        buffer = afile.read(buffersize)
        while len(buffer) > 0:
            hashtask.update(buffer)
            buffer = afile.read(buffersize)

    # get the hash af the file
    filehash = hashtask.hexdigest()

    # Remember Results
    results.append((hashAlgo, time.clock() - start_time))
    # print("-- Info  :: The file {0} has the {1} hash :: {2}".format(file,hashalgo,filehash))
    # print("-- Info  :: The singel run needs          :: {0:5.8f} seconds".format(time.clock() - start_time))

# sort the result list after the second parameter
results.sort(key=lambda x: x[1])
sorted_result = results

print("--" + 40 * "=")
print("-- Info  :: File {0} and size {1:3.3f} MB".format(file, size / 1024 / 1024))
print("-- Info  :: Use Buffersize {0}".format(buffersize))

for result in sorted_result:
    print("   Hash {0:15} | {1:2.6f} ".format(result[0], result[1]))

print("--" + 40 * "=")

# check the main algorithm  with different buffersizes
buffersize = 512
resultsBuffersize = []

# algoList=hashlib.algorithms_available
algoList = ['SHA1', 'MD5', 'DSA-SHA', 'MD4', 'SHA', 'DSA']

for j in range(12):
    buffersize = 512
    for i in range(10):
        buffersize *= 2
        for hashAlgo in algoList:
            # Remember the start time of the program
            start_time = time.clock()
            hashtask = hashlib.new(hashAlgo)
            with open(file, 'rb') as afile:
                buffer = afile.read(buffersize)
                while len(buffer) > 0:
                    hashtask.update(buffer)
                    buffer = afile.read(buffersize)
            filehash = hashtask.hexdigest()
            resultsBuffersize.append((hashAlgo, buffersize, time.clock() - start_time))

# sort the list with sorted after the second element
sorted_result = sorted(resultsBuffersize, key=lambda x: float(x[2]))

print("--" + 40 * "=")
print("-- Info  :: Results for Buffersize and Algorithm")
print(" {0:17} | {1:11} |  {2:10} ".format("Hash", "Buffer", "Time"))

for result in sorted_result:
    print("  {0:15} |  {1:8} |  {2:2.6f} ".format(result[0], result[1], result[2]))

print("--" + 40 * "=")

valuesX = []
valuesY = []
# graph the figures
for hashAlgo in algoList:
    for val in sorted_result:
        if val[0] == hashAlgo:
            valuesX.append(val[2])
            valuesY.append(val[1])

    plt.plot(valuesX, valuesY, label=hashAlgo, marker='x')  # --,marker='o', linestyle='--', color='r',

    # plot a smoth line with interpolation #must be implemented later
    # f2 = interp1d(valuesX, valuesY, kind='cubic')
    # plt.plot(f2, label=hashAlgo, marker='x')

    # Empty the list
    valuesX[:] = []
    valuesY[:] = []


############################################################
# Graph the figures
############################################################
# Runtime X axis
# plt.xscale('log')
plt.xlabel('Runtime s')
plt.xlim([0.02, 0.12])

# Buffersize Y axis
plt.ylabel('Buffersize Byte')
plt.yscale('log')
buffersize = 512
yticks = []
for i in range(10):
    buffersize = buffersize * 2
    yticks.append(buffersize)
plt.yticks(yticks, yticks)

# Diagram options
plt.title('Hash Performance for 10 runs of each algorithm with different buffersize')
legend = plt.legend(loc='upper right', shadow=True, fontsize='x-large')
legend.get_frame().set_facecolor('#FFFFE0')
plt.grid()

plt.show()
############################################################
