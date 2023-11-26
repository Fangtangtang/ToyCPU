file = open("a.out", "a")
for i in range(5000):
    file.write("wire [BYTE_SIZE-1:0] mem{}Value  = storage[{}];".format(i,i)+'\n')